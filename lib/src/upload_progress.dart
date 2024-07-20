class UploadProgress {
  final int bytesSent;
  final int totalBytes;

  UploadProgress(this.bytesSent, this.totalBytes);

  double get progress => (bytesSent / totalBytes) * 100;

  double get speed => bytesSent / ((DateTime.now().millisecondsSinceEpoch - _startTime) / 1000);

  static final int _startTime = DateTime.now().millisecondsSinceEpoch;
}