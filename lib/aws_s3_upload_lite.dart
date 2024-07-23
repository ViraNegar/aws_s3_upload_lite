library aws_s3_upload_lite;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:amazon_cognito_identity_dart_2/sig_v4.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';
import './src/policy.dart';
import 'src/upload_progress.dart';
import 'enum/acl.dart';
import 'src/utils.dart';

/// Convenience class for uploading files to AWS S3
class AwsS3 {
  /// Upload a file, returning the status code 200/204 on success.
  static Stream<UploadProgress> uploadFile({
    /// Storage endpoint
    required String domain,

    /// AWS access key
    required String accessKey,

    /// AWS secret key
    required String secretKey,

    /// The name of the S3 storage bucket to upload  to
    required String bucket,

    /// The file to upload
    required File file,

    /// The AWS region. Must be formatted correctly, e.g. us-west-1
    required String region,

    /// The path to upload the file to (e.g. "uploads/public"). Defaults to the root "directory"
    required String destDir,

    /// The filename to upload as.
    required String filename,

    /// The key to save this file as. Will override destDir and filename if set.
    String? key,

    /// Access control list enables you to manage access to bucket and objects
    /// For more information visit [https://docs.aws.amazon.com/AmazonS3/latest/userguide/acl-overview.html]
    ACL acl = ACL.public_read,

    /// The content-type of file to upload. defaults to binary/octet-stream.
    String contentType = 'binary/octet-stream',

    /// If set to true, https is used instead of http. Default is true.
    bool useSSL = true,

    /// Additional metadata to be attached to the upload
    Map<String, String>? metadata,

    required CancelToken cancelToken
  }) async* {
    final StreamController<UploadProgress> streamController =
    StreamController<UploadProgress>();
    try {
      var httpStr = 'http';
      if (useSSL) {
        httpStr += 's';
      }
      final endpoint = '$httpStr://$domain/$bucket';

      String? uploadKey;

      if (key != null) {
        uploadKey = key;
      } else if (destDir.isNotEmpty) {
        uploadKey = '$destDir/$filename';
      } else {
        uploadKey = '$filename';
      }

      final length = file.lengthSync();

      final dio = Dio();

      // Convert metadata to AWS-compliant params before generating the policy.
      final metadataParams = _convertMetadataToParams(metadata);

      // Generate pre-signed policy.
      final policy = Policy.fromS3PresignedPost(
        uploadKey,
        bucket,
        accessKey,
        15,
        length,
        acl,
        region: region,
        metadata: metadataParams,
      );

      final signingKey =
      SigV4.calculateSigningKey(secretKey, policy.datetime, region, 's3');
      final signature = SigV4.calculateSignature(signingKey, policy.encode());

      FormData formData = FormData.fromMap({
        'key': policy.key,
        'acl': aclToString(acl),
        'X-Amz-Credential': policy.credential,
        'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
        'X-Amz-Date': policy.datetime,
        'Policy': policy.encode(),
        'X-Amz-Signature': signature,
        'Content-Type': contentType,
        'file': await MultipartFile.fromFile(
            file.path, filename: path.basename(file.path)),
      });

      int startTime = DateTime
          .now()
          .millisecondsSinceEpoch;
      int lastSent = 0;

      dio.post(
        endpoint,
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: (sent, total) {
          int now = DateTime
              .now()
              .millisecondsSinceEpoch;
          int elapsed = now - startTime;
          lastSent = sent;
          streamController.add(UploadProgress(sent, total, elapsed));
        },
      );
    } catch (e) {
      streamController.addError(e);
      streamController.close();
    }

    yield* streamController.stream;
  }

  /// A method to transform the map keys into the format compliant with AWS.
  /// AWS requires that each metadata param be sent as `x-amz-meta-*`.
  static Map<String, String> _convertMetadataToParams(
      Map<String, String>? metadata) {
    Map<String, String> updatedMetadata = {};

    if (metadata != null) {
      for (var k in metadata.keys) {
        updatedMetadata['x-amz-meta-${k.paramCase}'] = metadata[k]!;
      }
    }

    return updatedMetadata;
  }

  /// A method to convert File To Cast
  static convertFileToCast(Uint8List data) {
    return List<int>.from(data);
  }
}