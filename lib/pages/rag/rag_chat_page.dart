import 'package:flutter/material.dart';

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
      final response = await _service.chat(
        query: text,
        document: widget.document,
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

class _MessageBubble extends StatelessWidget {
  final RagMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final isError = message.isError;

    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bgColor = isError
        ? const Color(0xFFFFE4E6)
        : isUser
            ? theme.colorScheme.primary
            : Colors.white;
    final textColor = isUser ? Colors.white : Colors.black87;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isUser
              ? null
              : const [
                  BoxShadow(
                    color: Color.fromRGBO(15, 23, 42, 0.08),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
            ),
            if (message.isAssistant && message.contexts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Nguồn tham khảo',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: message.contexts
                    .map((ctx) => _ContextCard(contextSnippet: ctx))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  final RagContextSnippet contextSnippet;

  const _ContextCard({required this.contextSnippet});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = contextSnippet.metadata;
    final quality = metadata['quality_tier'];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contextSnippet.displayTitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            contextSnippet.content,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _MetaChip(label: contextSnippet.source),
              if (quality is String && quality.isNotEmpty)
                _MetaChip(label: 'Chất lượng: $quality'),
              if (metadata['chunk_level'] is String)
                _MetaChip(label: 'Loại: ${metadata['chunk_level']}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF374151),
            ),
      ),
    );
  }
}
