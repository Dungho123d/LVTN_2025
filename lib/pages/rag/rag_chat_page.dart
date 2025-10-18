import 'dart:async';

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
  bool _isLoadingHistory = false;
  bool _historyInitialized = false;
  bool _isLoadingMessages = false;

  String? _pbSessionId;
  String? _pbDocumentId;
  _ChatSession? _currentSession;
  List<_ChatSession> _historySessions = const <_ChatSession>[];

  @override
  void initState() {
    super.initState();
    unawaited(_loadHistory());
  }

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

  Future<void> _loadHistory({bool force = false}) async {
    if (_isLoadingHistory) return;
    if (_historyInitialized && !force) return;

    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final pb = await getPocketbaseInstance();
      _pbDocumentId ??= await _resolvePocketBaseDocumentId(pb);

      final filter = _pbDocumentId != null
          ? 'documents.id ?= "${_escapeFilterValue(_pbDocumentId!)}"'
          : 'title = "${_escapeFilterValue('Chat: ${widget.document.name}')}"';

      final result = await pb.collection('chat_sessions').getList(
            page: 1,
            perPage: 50,
            sort: '-last_message_at',
            filter: filter,
          );

      final sessions = result.items
          .map(
            (record) => _ChatSession(
              id: record.id,
              title: (record.data['title'] as String? ?? '').trim(),
              createdAt: _parsePocketBaseDate(record.created),
              lastMessageAt: _parsePocketBaseDate(
                    record.data['last_message_at'] as String?,
                  ) ??
                  _parsePocketBaseDate(record.updated),
            ),
          )
          .toList();

      _ChatSession? selected = _currentSession;
      if (_pbSessionId != null) {
        selected = _findSessionById(sessions, _pbSessionId!);
      }

      if (mounted) {
        setState(() {
          _historySessions = sessions;
          _currentSession = selected;
          _historyInitialized = true;
        });
      }
    } on ClientException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Không tải được lịch sử: ${e.response['message'] ?? e.toString()}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được lịch sử: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  Future<void> _showHistoryPanel() async {
    await _loadHistory(force: true);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        'Lịch sử trò chuyện',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Làm mới',
                        onPressed: () => _loadHistory(force: true),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _isLoadingHistory
                      ? const Center(child: CircularProgressIndicator())
                      : _historySessions.isEmpty
                          ? _buildEmptyHistory(theme)
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _historySessions.length,
                              separatorBuilder: (_, __) => const Divider(
                                  height: 1, indent: 16, endIndent: 16),
                              itemBuilder: (context, index) {
                                final session = _historySessions[index];
                                final isSelected = session.id == _pbSessionId;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFE0E7FF),
                                    child: Icon(
                                      isSelected
                                          ? Icons.chat_bubble_rounded
                                          : Icons.history_rounded,
                                      color: const Color(0xFF1E40AF),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    _friendlySessionTitle(session),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    _formatSessionSubtitle(session),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  isThreeLine: session.createdAt != null &&
                                      session.lastMessageAt != null &&
                                      session.createdAt !=
                                          session.lastMessageAt,
                                  trailing: PopupMenuButton<_SessionAction>(
                                    tooltip: 'Tùy chọn',
                                    onSelected: (action) {
                                      switch (action) {
                                        case _SessionAction.rename:
                                          _promptRenameSession(session);
                                          break;
                                        case _SessionAction.delete:
                                          _confirmDeleteSession(session);
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem<_SessionAction>(
                                        value: _SessionAction.rename,
                                        child: const Text('Đổi tên'),
                                      ),
                                      PopupMenuItem<_SessionAction>(
                                        value: _SessionAction.delete,
                                        child: const Text('Xóa'),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.of(sheetContext).pop();
                                    _loadSessionMessages(session);
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadSessionMessages(_ChatSession session) async {
    setState(() {
      _isLoadingMessages = true;
    });

    try {
      final pb = await getPocketbaseInstance();
      final records = await pb.collection('chat_messages').getFullList(
            sort: 'created',
            filter: 'session.id = "${_escapeFilterValue(session.id)}"',
          );

      final loaded = <RagMessage>[];
      for (final record in records) {
        final roleRaw =
            (record.data['role'] as String? ?? 'assistant').toLowerCase();
        final role = _parseRole(roleRaw);
        final content = (record.data['content'] as String? ?? '').trim();
        final timestamp = _parsePocketBaseDate(record.created);
        final interactionId = record.data['interaction_id'] as String?;
        final contexts = _parseContexts(record.data['ctx']);

        loaded.add(
          RagMessage.history(
            role: role,
            text: content,
            timestamp: timestamp,
            contexts: contexts,
            interactionId: interactionId,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(loaded);
        _pbSessionId = session.id;
        _currentSession = session;
      });
      _scrollToBottom();
    } on ClientException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Không tải được cuộc trò chuyện: ${e.response['message'] ?? e.toString()}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được cuộc trò chuyện: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMessages = false;
        });
      }
    }
  }

  List<RagContextSnippet> _parseContexts(dynamic raw) {
    if (raw == null) return const [];

    List<dynamic>? items;
    if (raw is Map<String, dynamic>) {
      final maybeList = raw['contexts'];
      if (maybeList is List) {
        items = maybeList;
      }
    } else if (raw is List) {
      items = raw;
    }

    if (items == null) return const [];

    final contexts = <RagContextSnippet>[];
    for (final item in items) {
      if (item is Map<String, dynamic>) {
        contexts.add(RagContextSnippet.fromJson(item));
      } else if (item is Map) {
        contexts.add(
          RagContextSnippet.fromJson(
            item.map((key, value) => MapEntry('$key', value)),
          ),
        );
      }
    }
    return contexts;
  }

  RagMessageRole _parseRole(String role) {
    switch (role) {
      case 'user':
        return RagMessageRole.user;
      case 'assistant':
        return RagMessageRole.assistant;
      case 'error':
        return RagMessageRole.error;
      default:
        return RagMessageRole.assistant;
    }
  }

  DateTime? _parsePocketBaseDate(String? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  _ChatSession? _findSessionById(List<_ChatSession> sessions, String id) {
    for (final session in sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  String _friendlySessionTitle(_ChatSession session) {
    final title = session.title;
    if (title.isEmpty) {
      return 'Cuộc trò chuyện không tên';
    }
    if (title.startsWith('Chat:')) {
      final trimmed = title.substring(5).trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return title;
  }

  String _formatSessionSubtitle(_ChatSession session) {
    final updated = session.lastMessageAt ?? session.createdAt;
    if (updated == null) {
      return 'Chưa có tin nhắn';
    }

    final buffer = StringBuffer('Ngày ${_formatAbsoluteDate(updated)}');
    final relative = _formatRelativeTime(updated);
    if (relative != null) {
      buffer.write(' • $relative');
    }

    final created = session.createdAt;
    if (created != null && created != updated) {
      buffer.write('\nTạo: ${_formatAbsoluteDate(created)}');
    }

    return buffer.toString();
  }

  String _formatAbsoluteDate(DateTime time) {
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    final year = time.year.toString().padLeft(4, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String? _formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return 'Vừa cập nhật';
    }
    if (diff.inMinutes < 60) {
      return 'Cập nhật ${diff.inMinutes} phút trước';
    }
    if (diff.inHours < 24) {
      return 'Cập nhật ${diff.inHours} giờ trước';
    }
    if (diff.inDays < 7) {
      return 'Cập nhật ${diff.inDays} ngày trước';
    }
    return null;
  }

  Future<void> _promptRenameSession(_ChatSession session) async {
    final controller = TextEditingController(
      text: session.title.isNotEmpty
          ? session.title
          : _friendlySessionTitle(session),
    );

    final newTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Đổi tên cuộc trò chuyện'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Tên cuộc trò chuyện',
              hintText: 'Nhập tên mới',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    final trimmed = newTitle?.trim();
    if (trimmed == null) return;
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tên cuộc trò chuyện không được để trống.')),
      );
      return;
    }

    try {
      final pb = await getPocketbaseInstance();
      await pb.collection('chat_sessions').update(session.id, body: {
        'title': trimmed,
      });

      if (!mounted) return;
      final updated = session.copyWith(title: trimmed);
      setState(() {
        _historySessions = _historySessions
            .map((s) => s.id == updated.id ? updated : s)
            .toList(growable: false);
        if (_currentSession?.id == updated.id) {
          _currentSession = updated;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đổi tên cuộc trò chuyện.')),
      );
    } on ClientException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Không thể đổi tên: ${e.response['message'] ?? e.toString()}'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể đổi tên: $e')),
      );
    }
  }

  Future<void> _confirmDeleteSession(_ChatSession session) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa cuộc trò chuyện'),
          content: Text(
            'Bạn có chắc muốn xóa "${_friendlySessionTitle(session)}"? Hành động này không thể hoàn tác.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                foregroundColor: const Color(0xFFB91C1C),
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      final pb = await getPocketbaseInstance();
      await pb.collection('chat_sessions').delete(session.id);

      if (!mounted) return;
      final wasCurrent = _currentSession?.id == session.id;
      setState(() {
        _historySessions = _historySessions
            .where((s) => s.id != session.id)
            .toList(growable: false);
        if (!wasCurrent && _pbSessionId == session.id) {
          _pbSessionId = null;
        }
      });
      if (wasCurrent) {
        _startNewConversation();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa cuộc trò chuyện.')),
      );
    } on ClientException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Không thể xóa: ${e.response['message'] ?? e.toString()}'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể xóa: $e')),
      );
    }
  }

  Widget _buildEmptyHistory(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded,
                size: 48, color: Color(0xFF2563EB)),
            const SizedBox(height: 12),
            Text(
              'Chưa có cuộc trò chuyện nào',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhắn tin với trợ lý để tạo cuộc trò chuyện đầu tiên của bạn.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  void _startNewConversation() {
    setState(() {
      _messages.clear();
      _pbSessionId = null;
      _currentSession = null;
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
            if (_currentSession != null) ...[
              const SizedBox(height: 2),
              Text(
                'Đang tiếp tục cuộc trò chuyện đã lưu',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cuộc trò chuyện mới',
            onPressed: _startNewConversation,
            icon: const Icon(Icons.add_comment_rounded),
          ),
          IconButton(
            tooltip: 'Lịch sử trò chuyện',
            onPressed: _showHistoryPanel,
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  _messages.isEmpty
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
                  if (_isLoadingMessages)
                    Positioned.fill(
                      child: Container(
                        color: theme.colorScheme.surface.withOpacity(0.7),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                ],
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

enum _SessionAction { rename, delete }

class _ChatSession {
  final String id;
  final String title;
  final DateTime? createdAt;
  final DateTime? lastMessageAt;

  const _ChatSession({
    required this.id,
    required this.title,
    this.createdAt,
    this.lastMessageAt,
  });

  _ChatSession copyWith({
    String? title,
    DateTime? createdAt,
    DateTime? lastMessageAt,
  }) {
    return _ChatSession(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
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
