import * as functions from "firebase-functions";
import {initializeApp} from "firebase-admin/app";
import {getStorage} from "firebase-admin/storage";
import {genkit, z} from "genkit";
import {vertexAI} from "@genkit-ai/vertexai";
import {TextToSpeechClient} from "@google-cloud/text-to-speech";
import {onCallGenkit} from "firebase-functions/v2/https";
import logger from "firebase-functions/logger";

// 環境定数
const LOCATION_ID = "us-central1";

initializeApp();

const ai = genkit({
  plugins: [vertexAI({location: LOCATION_ID})],
  model: vertexAI.model("gemini-2.5-flash-preview-05-20"),
});

const ttsClient = new TextToSpeechClient();

const OcrSchema = z.object({
  text: z.string(),
});

const ocrFlow = ai.defineFlow(
  {
    name: "ocrFlow",
    inputSchema: z.object({
      imageUrl: z.string(),
    }),
    outputSchema: OcrSchema,
  },
  async (input) => {
    const prompt = `画像内のテキストを正確に読み取って、そのまま出力してください。
    新聞記事のような段組の場合、読む順序を論理的に判断して下さい。読みたいと思って撮った記事以外のテキストは含まないで下さい。
    読み取ったテキストのみを出力し、説明や注釈は一切加えないで下さい。`;

    const {output} = await ai.generate({
      prompt: [{text: prompt}, {media: {url: input.imageUrl}}],
      output: {schema: OcrSchema},
    });

    if (output === null) throw new Error("No output generated.");

    return output;
  }
);

export const generateOcm = onCallGenkit(
  {
    enforceAppCheck: true,
    authPolicy: (auth) => auth?.uid != null,
    region: LOCATION_ID,
    maxInstances: 100,
    cors: true,
    timeoutSeconds: 300, // 5 minutes timeout
  },
  ocrFlow
);

export const textToSpeechFunction = functions.https.onCall(
  {
    authPolicy: (auth) => auth?.uid != null,
    region: LOCATION_ID,
    maxInstances: 100,
    cors: true,
    enforceAppCheck: true,
    timeoutSeconds: 300, // 5 minutes timeout
  },
  async (request) => {
    const userId = request.auth?.uid ?? "(null)";
    const {text} = request.data;

    if (!text || typeof text !== "string") {
      throw new functions.https.HttpsError("invalid-argument", "テキストが指定されていません");
    }

    try {
      const [response] = await ttsClient.synthesizeSpeech({
        input: {text},
        voice: {
          languageCode: "ja-JP",
          name: "ja-JP-Standard-B",
          ssmlGender: "FEMALE" as const,
        },
        audioConfig: {
          audioEncoding: "MP3" as const,
        },
      });

      const audioContent = response.audioContent as Buffer;
      const bucket = getStorage().bucket();
      const fileName = `downloads/${userId}/audio_${Date.now()}.mp3`;
      const file = bucket.file(fileName);

      logger.debug("fileName: ", fileName);

      await file.save(audioContent, {
        metadata: {
          contentType: "audio/mpeg",
        },
      });

      // await file.makePublic();
      const audioUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;

      /* 署名付きURLを生成する
      const [signedUrl] = await file.getSignedUrl({
        action: 'read',
        // URLの有効期限を設定
        expires: Date.now() + 15 * 60 * 1000, // 15分
      }); */

      logger.debug("audioUrl: ", audioUrl);

      return {audioUrl};
    } catch (error) {
      functions.logger.error("Text-to-speech failed:", error);

      throw new functions.https.HttpsError("internal", "音声変換処理に失敗しました");
    }
  }
);
