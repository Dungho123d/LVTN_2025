import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:study_application/service/pb_sync_service.dart';
import '../../models/rag_document.dart';
import '../../service/rag_service.dart';
import '../../service/pocketbase.dart';

Future<RagDocument?> showRagDocumentSheet(BuildContext context) {
  return showModalBottomSheet<RagDocument?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _RagDocumentSheet(),
  );
}

class _RagDocumentSheet extends StatefulWidget {
  const _RagDocumentSheet();

  @override
  State<_RagDocumentSheet> createState() => _RagDocumentSheetState();
}

class _RagDocumentSheetState extends State<_RagDocumentSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late List<RagDocument> _documents;
  final RagApiService _ragService = RagApiService.instance;
  RagDocument? _selected;
  bool _isUploading = false;
  bool _isLoadingDocs = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _documents = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDocuments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(15, 23, 42, 0.08),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trợ lý tài liệu',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tải tài liệu lên hoặc chọn tài liệu đã có để bắt đầu trò chuyện RAG.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: theme.colorScheme.primary,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Tải tài liệu'),
                    Tab(text: 'Tài liệu của tôi'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUploadTab(theme),
                    _buildDocumentTab(theme),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _selected == null || _isUploading
                            ? null
                            : () => Navigator.of(context).maybePop(_selected),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        child: const Text('Bắt đầu trò chuyện'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFCBD5F5),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
                color: const Color(0xFFF8FAFF),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Feather.upload_cloud,
                    size: 54,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kéo thả file PDF, DOCX hoặc TXT vào đây',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dung lượng tối đa 15MB. Hỗ trợ tài liệu tiếng Việt & tiếng Anh.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed:
                        _isUploading ? null : () => _handleUploadFromDevice(),
                    icon: _isUploading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.6,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.file_upload_outlined),
                    label: Text(
                      _isUploading
                          ? 'Đang tải lên...'
                          : 'Chọn tài liệu từ thiết bị',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Gợi ý tài liệu phù hợp',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _SuggestionCard(
              title: 'Giáo trình môn học',
              description:
                  'Chuẩn bị file PDF giáo trình để trợ lý tóm tắt nhanh các chương quan trọng.',
            ),
            const SizedBox(height: 12),
            _SuggestionCard(
              title: 'Tài liệu ôn thi',
              description:
                  'Tải các đề cương hoặc đề thi thử để nhận gợi ý ôn tập theo từng chủ đề.',
            ),
            const SizedBox(height: 12),
            _SuggestionCard(
              title: 'Ghi chú cá nhân',
              description:
                  'Kết hợp ghi chú với trợ lý để tạo flashcard và câu hỏi luyện tập.',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTab(ThemeData theme) {
    if (_isLoadingDocs) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 52,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 12),
              Text(
                'Không thể tải danh sách tài liệu.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => _loadDocuments(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_documents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Feather.folder_minus,
                size: 56,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(height: 12),
              Text(
                'Chưa có tài liệu nào được tải lên',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hãy tải tài liệu đầu tiên của bạn để bắt đầu trò chuyện cùng trợ lý.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const TextField(
              decoration: InputDecoration(
                icon: Icon(Icons.search),
                hintText: 'Tìm kiếm tài liệu của bạn',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadDocuments(),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _documents.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final doc = _documents[index];
                  final isSelected = doc.id == _selected?.id;
                  return _DocumentTile(
                    document: doc,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selected = doc),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUploadFromDevice() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx', 'txt', 'md'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;

      const maxSizeBytes = 15 * 1024 * 1024; // 15MB
      if (file.size > maxSizeBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File vượt quá giới hạn 15MB.')),
        );
        return;
      }

      final bytes = await _resolveFileBytes(file);
      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Không đọc được nội dung file "${file.name}"')),
        );
        return;
      }

      final mimeType = _resolveMimeType(file.name);

      if (!mounted) return;
      setState(() => _isUploading = true);

      // ==== DÙNG SERVICE ĐỒNG BỘ PB + RAG ====
      RagDocument uploaded;
      try {
        final pb =
            await getPocketbaseInstance(); // bạn đã import ../../service/pocketbase.dart
        final sync = PbSyncService(pb: pb, ragService: _ragService);

        uploaded = await sync.uploadAndSync(
          filename: file.name,
          bytes: bytes,
          mimeType: mimeType,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tải lên/đồng bộ thất bại: $e')),
        );
        return;
      }

      if (!mounted) return;

      await _loadDocuments(preferId: uploaded.id);
      if (!mounted) return;

      _tabController.animateTo(1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã tải lên "${uploaded.name}"')),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể truy cập bộ nhớ: ${e.message}')),
      );
    } catch (e, st) {
      debugPrint('Upload error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải lên tài liệu: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isUploading = false);
    }
  }

  Future<List<int>?> _resolveFileBytes(PlatformFile file) async {
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      return file.bytes!;
    }

    final path = file.path;
    if (path == null || path.isEmpty) {
      return null;
    }

    try {
      final ioFile = File(path);
      if (await ioFile.exists()) {
        return await ioFile.readAsBytes();
      }
    } catch (e) {
      debugPrint('Không thể đọc file từ đường dẫn: $e');
    }
    return null;
  }

  String _resolveMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'md':
        return 'text/markdown';
      default:
        return 'application/octet-stream';
    }
  }

  // rag_document_sheet.dart
  // Future<void> _persistDocumentToPocketBase({
  //   required RagDocument document,
  //   required List<int> bytes,
  //   required String originalFileName,
  // }) async {
  //   try {
  //     final pb = await getPocketbaseInstance();

  //     // Lấy owner id từ phiên đăng nhập hiện tại (BẮT BUỘC theo schema)
  //     final ownerId = pb.authStore.record?.id;
  //     if (ownerId == null || ownerId.isEmpty) {
  //       throw Exception('Chưa đăng nhập PocketBase (không có owner).');
  //     }

  //     // Chuẩn bị file multipart
  //     final file = http.MultipartFile.fromBytes(
  //       'file',
  //       bytes,
  //       filename: originalFileName,
  //     );

  //     // Map field THEO SCHEMA `documents` trong pb_schema.js
  //     await pb.collection('documents').create(
  //       body: {
  //         'title': document.name, // text
  //         'owner': ownerId, // relation -> users
  //         'status': 'ingested', // "pending" | "ingested" | "error"
  //         'chunk_count': document.chunkCount, // number
  //         // 'emb_model': 'gemini-embedding-xxx',               // (tùy chọn) nếu muốn lưu
  //         'ingested_at':
  //             (document.uploadedAt ?? DateTime.now()).toIso8601String(), // date
  //       },
  //       files: [file], // file (maxSelect:1)
  //     );

  //     debugPrint('PocketBase sync OK for ${document.id}');
  //   } catch (e, st) {
  //     debugPrint('PocketBase sync failed: $e');
  //     debugPrint('$st');

  //     // Retry 1 lần (mạng chập chờn/CORS)
  //     try {
  //       await Future.delayed(const Duration(seconds: 2));
  //       final pb2 = await getPocketbaseInstance();
  //       final ownerId2 = pb2.authStore.record?.id;
  //       if (ownerId2 == null || ownerId2.isEmpty) {
  //         throw Exception(
  //             'Chưa đăng nhập PocketBase (owner null) ở lần retry.');
  //       }

  //       await pb2.collection('documents').create(
  //         body: {
  //           'title': document.name,
  //           'owner': ownerId2,
  //           'status': 'ingested',
  //           'chunk_count': document.chunkCount,
  //           'ingested_at':
  //               (document.uploadedAt ?? DateTime.now()).toIso8601String(),
  //         },
  //         files: [
  //           http.MultipartFile.fromBytes('file', bytes,
  //               filename: originalFileName),
  //         ],
  //       );

  //       debugPrint('PocketBase sync retry OK for ${document.id}');
  //     } catch (e2) {
  //       debugPrint('Retry PocketBase failed: $e2');
  //       if (!mounted) return;
  //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //         content: Text(
  //             'Không thể đồng bộ với PocketBase. Tài liệu vẫn dùng được trong RAG.'),
  //       ));
  //     }
  //   }
  // }

  Future<void> _loadDocuments({String? preferId}) async {
    if (!mounted) return;
    setState(() {
      _isLoadingDocs = true;
      _loadError = null;
    });

    try {
      final docs = await _ragService.fetchDocuments();
      if (!mounted) return;
      setState(() {
        _documents = docs;
        final preferredId = preferId ?? _selected?.id;
        _selected = preferredId != null
            ? _findDocumentById(docs, preferredId)
            : docs.isNotEmpty
                ? docs.first
                : null;
        _selected ??= docs.isNotEmpty ? docs.first : null;
      });
    } on RagApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _documents = [];
        _selected = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _documents = [];
        _selected = null;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingDocs = false;
      });
    }
  }

  RagDocument? _findDocumentById(List<RagDocument> docs, String id) {
    for (final doc in docs) {
      if (doc.id == id) return doc;
    }
    return null;
  }
}

class _DocumentTile extends StatelessWidget {
  final RagDocument document;
  final bool isSelected;
  final VoidCallback onTap;

  const _DocumentTile({
    required this.document,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(15, 23, 42, 0.04),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D4ED8).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Feather.file_text,
                  color: Color(0xFF1D4ED8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tải lên ${document.uploadedLabel} • ${document.chunkLabel}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : Colors.grey.shade400,
                    width: isSelected ? 6 : 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final String title;
  final String description;

  const _SuggestionCard({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.04),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
