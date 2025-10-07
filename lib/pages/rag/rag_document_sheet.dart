import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../models/rag_document.dart';

Future<void> showRagDocumentSheet(BuildContext context) {
  return showModalBottomSheet<void>(
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
  RagDocument? _selected;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _documents = _seedDocuments();
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
                            : () {
                                Navigator.of(context).maybePop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Đang chuẩn bị hội thoại RAG với "${_selected!.name}"',
                                    ),
                                  ),
                                );
                              },
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
                    onPressed: _isUploading ? null : _handleSimulatedUpload,
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
                    label: Text(_isUploading ? 'Đang tải lên...' : 'Chọn tài liệu từ máy'),
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
            child: ListView.separated(
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
        ],
      ),
    );
  }

  Future<void> _handleSimulatedUpload() async {
    setState(() {
      _isUploading = true;
    });

    await Future<void>.delayed(const Duration(seconds: 2));

    final newDoc = RagDocument(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Tai lieu moi ${_documents.length + 1}.pdf',
      pageCount: 12 + _documents.length * 3,
      uploadedAt: DateTime.now(),
    );

    setState(() {
      _documents = [newDoc, ..._documents];
      _selected = newDoc;
      _isUploading = false;
      _tabController.animateTo(1);
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tải lên thành công "${newDoc.name}"'),
      ),
    );
  }

  List<RagDocument> _seedDocuments() {
    final now = DateTime.now();
    return [
      RagDocument(
        id: 'doc-01',
        name: 'Chuong 1 - Dai so tuyen tinh.pdf',
        pageCount: 28,
        uploadedAt: now.subtract(const Duration(days: 1)),
      ),
      RagDocument(
        id: 'doc-02',
        name: 'De cuong on tap Giua ky.docx',
        pageCount: 9,
        uploadedAt: now.subtract(const Duration(days: 4)),
      ),
      RagDocument(
        id: 'doc-03',
        name: 'Tong hop ghi chu Marketing.txt',
        pageCount: 5,
        uploadedAt: now.subtract(const Duration(days: 12)),
      ),
    ];
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
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE5E7EB),
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
                      'Tải lên ngày ${document.uploadedLabel} • ${document.pageCount} trang',
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
