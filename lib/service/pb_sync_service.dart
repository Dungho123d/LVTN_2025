import 'dart:convert';
import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/rag_document.dart';
import 'rag_service.dart';

class PbSyncService {
  final PocketBase pb;
  final RagApiService rag;

  PbSyncService({required this.pb, RagApiService? ragService})
      : rag = ragService ?? RagApiService.instance;

  /// Upload file vào PocketBase (collection `documents`) rồi
  /// gọi RAG ingest và cập nhật lại record (status/chunk_count/ingested_at).
  ///
  /// Trả về RagDocument (từ server RAG).
  Future<RagDocument> uploadAndSync({
    required String filename,
    required List<int> bytes,
    String mimeType = 'application/pdf',
    String? embModel, // nếu bạn muốn lưu vào PB
  }) async {
    final userId = pb.authStore.record?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('Chưa đăng nhập PocketBase');
    }

    // 1) Tạo record documents (status=pending) + upload file vào PB
    final createBody = <String, dynamic>{
      'title': filename,
      'owner': userId,
      'status': 'pending',
      if (embModel != null) 'emb_model': embModel,
    };

    final filePart = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
      contentType: MediaType.parse(mimeType),
    );

    late final RecordModel docRec;
    try {
      docRec = await pb.collection('documents').create(
        body: createBody,
        files: [filePart],
      );
    } on ClientException catch (e) {
      final msg = e.response['message'] ?? e ?? e.toString();
      throw Exception('PB: tạo documents thất bại: $msg');
    }

    // 2) Gọi RAG ingest, truyền pb_document_id để backend liên kết ngược
    RagDocument ragDoc;
    try {
      ragDoc = await rag.uploadDocumentBytes(
        filename: filename,
        bytes: bytes,
        mimeType: mimeType,
        sizeBytes: bytes.length,
        pbDocumentId: docRec.id, // <— rất quan trọng
      );
    } catch (e) {
      // 2.1) Nếu RAG lỗi, cập nhật status=error cho record PB
      await _safeUpdate(docRec.id, {'status': 'error'});
      rethrow;
    }

    // 3) Cập nhật record PB sau khi ingest OK
    await _safeUpdate(docRec.id, {
      'status': 'ingested',
      'chunk_count': ragDoc.chunkCount,
      'ingested_at': DateTime.now().toIso8601String(),
    });

    return ragDoc;
  }

  Future<void> _safeUpdate(String id, Map<String, dynamic> body) async {
    try {
      await pb.collection('documents').update(id, body: body);
    } catch (_) {/* bỏ qua để không chặn flow */}
  }
}
