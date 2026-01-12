// Copyright © 2025 Apex Flow Group. All rights reserved.

enum TransferStatus {
  idle,
  advertising,
  connecting,
  transferring,
  completed,
  error,
}

class TransferState {
  final TransferStatus status;
  final String? message;
  final double? progress;

  TransferState({
    required this.status,
    this.message,
    this.progress,
  });

  TransferState copyWith({
    TransferStatus? status,
    String? message,
    double? progress,
  }) {
    return TransferState(
      status: status ?? this.status,
      message: message ?? this.message,
      progress: progress ?? this.progress,
    );
  }
}
