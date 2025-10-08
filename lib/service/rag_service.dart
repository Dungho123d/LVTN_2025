import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/rag_chat.dart';
import '../models/rag_document.dart';

class RagApiException implements Exception {
  final String message;
  final int? statusCode;

  RagApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class RagApiService {
  RagApiService._internal();

  static final RagApiService instance = RagApiService._internal();

  final http.Client _client = http.Client();
  final Duration _timeout = const Duration(seconds: 30);

  String get _baseUrl {
    final raw = dotenv.env['RAG_API_URL'] ??
        dotenv.env['RAG_API_BASE_URL'] ??
        'http://10.0.2.2:8011';
    return raw.trim().isEmpty ? 'http://10.0.2.2:8011' : raw.trim();
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalizedBase = _baseUrl.endsWith('/') ? _baseUrl : '$_baseUrl/';
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$normalizedBase$normalizedPath').replace(
      queryParameters: query?.map((key, value) => MapEntry(key, '$value')),
    );
  }

  Future<List<RagDocument>> fetchDocuments() async {
    final response = await _client
        .get(_uri('/documents'))
        .timeout(_timeout, onTimeout: _onTimeout);

    final data = _decodeJson(response);
    final docs = <RagDocument>[];
    final rawDocs = data['documents'];
    if (rawDocs is List) {
      for (final item in rawDocs) {
        if (item is Map<String, dynamic>) {
          docs.add(RagDocument.fromJson(item));
        } else if (item is Map) {
          docs.add(RagDocument.fromJson(
              item.map((key, value) => MapEntry('$key', value))));
        }
      }
    }
    return docs;
  }

  Future<RagDocument> uploadDocumentBytes({
    required String filename,
    required List<int> bytes,
    String mimeType = 'text/plain',
  }) async {
    final request = http.MultipartRequest('POST', _uri('/ingest_file'))
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ));

    final streamed = await request.send().timeout(_timeout,
        onTimeout: () => _onTimeout<http.StreamedResponse>());

    final body = await streamed.stream.bytesToString();
    final statusCode = streamed.statusCode;
    if (statusCode >= 400) {
      throw RagApiException(
        'Máy chủ trả về lỗi $statusCode: $body',
        statusCode: statusCode,
      );
    }

    final decoded = _decodeBody(body, statusCode: statusCode);
    if (decoded['ok'] == false) {
      throw RagApiException(
        decoded['error']?.toString() ?? 'Tải lên thất bại',
        statusCode: statusCode,
      );
    }
    final documentJson = decoded['document'];
    if (documentJson is Map<String, dynamic>) {
      return RagDocument.fromJson(documentJson);
    }
    if (documentJson is Map) {
      return RagDocument.fromJson(
          documentJson.map((key, value) => MapEntry('$key', value)));
    }

    // fallback nếu server chưa trả về document
    return RagDocument(
      id: decoded['file'] as String? ?? filename,
      name: decoded['file'] as String? ?? filename,
      chunkCount: (decoded['added_chunks'] as num?)?.toInt() ?? 0,
      uploadedAt: DateTime.now(),
    );
  }

  Future<RagChatResponse> chat({
    required String query,
    required RagDocument document,
    int k = 4,
    String minQualityTier = 'medium',
  }) async {
    final response = await _client
        .post(
          _uri('/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'query': query,
            'k': k,
            'min_quality_tier': minQualityTier,
            'source_in': [document.name],
          }),
        )
        .timeout(_timeout, onTimeout: _onTimeout);

    final data = _decodeJson(response);
    return RagChatResponse.fromJson(data);
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    final statusCode = response.statusCode;
    final decoded = _decodeBody(response.body, statusCode: statusCode);
    if (statusCode >= 400) {
      throw RagApiException(
        decoded['error']?.toString() ?? 'Máy chủ trả về lỗi $statusCode',
        statusCode: statusCode,
      );
    }

    if (decoded['ok'] == false) {
      throw RagApiException(
        decoded['error']?.toString() ?? 'Yêu cầu thất bại',
        statusCode: statusCode,
      );
    }

    return decoded;
  }

  Map<String, dynamic> _decodeBody(String body, {int? statusCode}) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', value));
      }
      throw const FormatException('Phản hồi không đúng định dạng JSON');
    } on FormatException catch (e) {
      throw RagApiException(
        'Không đọc được phản hồi JSON: ${e.message}',
        statusCode: statusCode,
      );
    }
  }

  FutureOr<T> _onTimeout<T>() {
    throw RagApiException(
        'Yêu cầu vượt quá thời gian chờ. Kiểm tra lại server.');
  }
}
