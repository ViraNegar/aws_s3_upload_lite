import 'dart:async';
import 'package:http/http.dart' as http;

import 'multipart_request_with_progress.dart';

class StreamedRequestWithProgress extends http.BaseClient {
  final http.Client _inner;

  StreamedRequestWithProgress(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request is MultipartRequestWithProgress) {
      return _inner.send(request);
    }
    return _inner.send(request);
  }
}
