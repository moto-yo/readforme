import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String message;
  final double? progress;

  const LoadingIndicator({
    super.key,
    required this.message,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (progress != null)
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
              ),
            )
          else
            const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          if (progress != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${(progress! * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}