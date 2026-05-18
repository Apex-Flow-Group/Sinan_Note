// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';


class SyncProgressWidget extends StatelessWidget {
  final String message;
  
  const SyncProgressWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

