import 'dart:async';
import 'package:http/http.dart' as http;
import 'upload_progress.dart';

class MultipartRequestWithProgress extends http.MultipartRequest {
  MultipartRequestWithProgress(String method, Uri url) : super(method, url);

  final _progressController = StreamController<UploadProgress>.broadcast();
  late int _startTime;

  Stream<UploadProgress> get progressStream => _progressController.stream;

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    final totalBytes = contentLength;

    _startTime = DateTime.now().millisecondsSinceEpoch;

    if (!_progressController.hasListener) {
      int bytesSent = 0;
      Stream<List<int>> transformedStream = byteStream.transform(
        StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            bytesSent += data.length;
            final elapsedTime = DateTime.now().millisecondsSinceEpoch - _startTime;
            final progress = UploadProgress(bytesSent, totalBytes, elapsedTime);
            _progressController.add(progress);
            sink.add(data);
          },
          handleError: (error, stackTrace, sink) {
            _progressController.addError(error, stackTrace);
          },
          handleDone: (sink) {
            _progressController.close();
            sink.close();
          },
        ),
      );
      return http.ByteStream(transformedStream);
    }

    return byteStream;
  }
}
