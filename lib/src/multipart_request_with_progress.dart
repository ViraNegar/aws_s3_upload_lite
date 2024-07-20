import 'dart:async';
import 'package:http/http.dart' as http;

class MultipartRequestWithProgress extends http.MultipartRequest {
  MultipartRequestWithProgress(String method, Uri url) : super(method, url);

  StreamController<UploadProgress>? _progressController;

  Stream<UploadProgress> get progressStream {
    _progressController ??= StreamController<UploadProgress>();
    return _progressController!.stream;
  }

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    final totalBytes = contentLength;

    if (_progressController != null) {
      int bytesSent = 0;
      Stream<List<int>> transformedStream = byteStream.transform(
        StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            bytesSent += data.length;
            final progress = UploadProgress(bytesSent, totalBytes);
            _progressController!.add(progress);
            sink.add(data);
          },
          handleDone: (sink) {
            _progressController!.close();
            sink.close();
          },
        ),
      );
      return http.ByteStream(transformedStream);
    }

    return byteStream;
  }
}

class UploadProgress {
  final int bytesSent;
  final int totalBytes;

  UploadProgress(this.bytesSent, this.totalBytes);

  double get progress => (bytesSent / totalBytes) * 100;

  double get speed => bytesSent / ((DateTime.now().millisecondsSinceEpoch - _startTime) / 1000);

  static final int _startTime = DateTime.now().millisecondsSinceEpoch;
}
