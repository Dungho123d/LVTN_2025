import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:study_application/service/pocketbase.dart';
import '../../models/rag_chat.dart';
import '../../models/rag_document.dart';
import '../../service/rag_service.dart';

class RagChatPage extends StatefulWidget {
  final RagDocument document;

  const RagChatPage({super.key, required this.document});

  @override
  State<RagChatPage> createState() => _RagChatPageState();
}

class _RagChatPageState extends State<RagChatPage> {
  final RagApiService _service = RagApiService.instance;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<RagMessage> _messages = [];

  bool _isSending = false;

  String? _pbSessionId;
  String? _pbDocumentId;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(RagMessage.user(text));
      _isSending = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      // Chuẩn bị log sang PocketBase
      final pb = await getPocketbaseInstance();
      _pbDocumentId ??= await _resolvePocketBaseDocumentId(pb);

      final pbLog = PbLogOptions(
        pb: pb,
        sessionId: _pbSessionId, // null -> auto tạo
        sessionTitle: 'Chat: ${widget.document.name}',
        documentIds: [
          if (_pbDocumentId != null) _pbDocumentId!,
        ],
        ensureSession: true,
        onSessionCreated: (sid) => _pbSessionId = sid,
      );

      final response = await _service.chat(
        query: text,
        document: widget.document,
        pbLog: pbLog, // truyền tuỳ chọn log
      );

      if (!mounted) return;

      setState(() {
        _messages.add(RagMessage.assistant(
          response.answer,
          contexts: response.contexts,
          interactionId: response.interactionId,
        ));
      });
    } on RagApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(RagMessage.error(e.message));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(RagMessage.error('Gặp lỗi không mong muốn: $e'));
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  // Tìm record documents trong PB theo owner + title
  Future<String?> _resolvePocketBaseDocumentId(PocketBase pb) async {
    try {
      final ownerId = pb.authStore.record?.id;
      if (ownerId == null || ownerId.isEmpty) return null;

      final title = widget.document.name;
      final esc = _escapeFilterValue(title);

      final list = await pb.collection('documents').getList(
            page: 1,
            perPage: 1,
            filter: 'owner.id = "$ownerId" && title = "$esc"',
            sort: '-created',
          );

      if (list.items.isNotEmpty) {
        return list.items.first.id;
      }
    } catch (_) {
      // nuốt lỗi, không làm hỏng phiên chat
    }
    return null;
  }

  String _escapeFilterValue(String v) => v.replaceAll(r'"', r'\"');

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trợ lý học tập'),
            Text(
              widget.document.name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _MessageBubble(message: message);
                      },
                    ),
            ),
            const Divider(height: 1),
            _buildComposer(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(height: 16),
            Text(
              'Bắt đầu trò chuyện với tài liệu',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đặt câu hỏi dựa trên nội dung tài liệu “${widget.document.name}”. Trợ lý sẽ trích dẫn các đoạn liên quan.',
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

  Widget _buildComposer(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 12,
        top: 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Nhập câu hỏi của bạn...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _isSending ? null : _sendMessage,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            child: _isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}

/* ====================== UI dưới đây: ĐẸP HƠN & ẨN CHUNK_LEVEL/LOẠI ====================== */

class _MessageBubble extends StatelessWidget {
  final RagMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final isError = message.isError;

    if (isUser) {
      // Bubble người dùng
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: SelectableText(
            message.text,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ),
      );
    }

    // Assistant / Error
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isError ? const Color(0xFFFFF1F2) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isError ? const Color(0xFFFECACA) : const Color(0xFFE5E7EB),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(15, 23, 42, 0.06),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: isError
            ? _AssistantError(text: message.text)
            : _AssistantMessageContent(message: message),
      ),
    );
  }
}

class _AssistantError extends StatelessWidget {
  final String text;
  const _AssistantError({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
        const SizedBox(width: 10),
        Expanded(
          child: SelectableText(
            text,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: const Color(0xFF991B1B)),
          ),
        ),
      ],
    );
  }
}

class _AssistantMessageContent extends StatelessWidget {
  final RagMessage message;
  const _AssistantMessageContent({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header nhỏ
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: Color(0xFF2563EB), size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              'Trợ lý',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Sao chép trả lời',
              icon: const Icon(Icons.copy_all_rounded, size: 18),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: message.text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Đã sao chép nội dung trả lời')),
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Nội dung trả lời – format nhẹ
        _AnswerRichText(text: message.text),

        if (message.contexts.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SourcesSection(contexts: message.contexts),
        ],
      ],
    );
  }
}

class _AnswerRichText extends StatelessWidget {
  final String text;
  const _AnswerRichText({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Tách đoạn theo dòng trống
    final paragraphs = text.split(RegExp(r'\n\s*\n'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in paragraphs) ...[
          _renderParagraph(p.trim(), theme),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _renderParagraph(String p, ThemeData theme) {
    // Nếu là danh sách gạch đầu dòng, render lại đẹp hơn
    final lines = p.split('\n');
    final isBulleted = lines.every(
        (l) => l.trimLeft().startsWith('-') || l.trimLeft().startsWith('•'));
    if (isBulleted) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final l in lines)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(Icons.circle, size: 6, color: Color(0xFF6B7280)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    l.replaceFirst(RegExp(r'^[-•]\s*'), ''),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
        ],
      );
    }

    // Đoạn văn thường
    return SelectableText(
      p,
      style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
    );
  }
}

class _SourcesSection extends StatelessWidget {
  final List<RagContextSnippet> contexts;
  const _SourcesSection({required this.contexts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          initiallyExpanded: false,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          collapsedShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              const Icon(Icons.library_books_outlined,
                  size: 18, color: Color(0xFF334155)),
              const SizedBox(width: 8),
              Text(
                'Nguồn tham khảo (${contexts.length})',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
            ],
          ),
          children: [
            const SizedBox(height: 6),
            ...contexts.map((c) => _SourceCard(contextSnippet: c)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final RagContextSnippet contextSnippet;
  const _SourceCard({required this.contextSnippet});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = contextSnippet.metadata;
    final quality = meta[
        'quality_tier']; // chỉ còn quality, KHÔNG hiển thị chunk_level/loại

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề hiển thị
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.description_outlined,
                  size: 18, color: Color(0xFF475569)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  contextSnippet.displayTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Trích đoạn
          Text(
            contextSnippet.content,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: const Color(0xFF374151), height: 1.25),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Chips metadata: CHỈ hiện source & quality
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _ChipPill(label: contextSnippet.source),
              if (quality is String && quality.isNotEmpty)
                _ChipPill(label: 'Chất lượng: $quality'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  final String label;
  const _ChipPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF334155),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
