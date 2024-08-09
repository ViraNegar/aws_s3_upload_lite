class Progress {
  final int bytesSent;
  final int totalBytes;
  final int elapsedTime;

  Progress(this.bytesSent, this.totalBytes, this.elapsedTime);

  double get progress => (bytesSent / totalBytes) * 100;

  double get speedMbps => (bytesSent * 8) / (elapsedTime / 1000) / (1024 * 1024);

  @override
  String toString() {
    return 'Progress: ${progress.toStringAsFixed(2)}%, Speed: ${speedMbps.toStringAsFixed(2)} Mbps';
  }
}