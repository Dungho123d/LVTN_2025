import 'package:flutter/material.dart';
import 'package:study_application/manager/flashcard_manager.dart';
import 'package:study_application/manager/studysets_manager.dart';
import 'package:study_application/model/flashcard.dart';
import 'package:study_application/model/study_set.dart';

/// -------------------- PAGE --------------------
class FlashcardsTab extends StatefulWidget {
  const FlashcardsTab({
    super.key,
    required this.manager,
  });

  final FlashcardManager manager;

  @override
  State<FlashcardsTab> createState() => _FlashcardsTabState();
}

class _FlashcardsTabState extends State<FlashcardsTab> {
  @override
  void initState() {
    super.initState();
    widget.manager.addListener(_handleManagerChanged);
  }

  @override
  void didUpdateWidget(covariant FlashcardsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.manager != widget.manager) {
      oldWidget.manager.removeListener(_handleManagerChanged);
      widget.manager.addListener(_handleManagerChanged);
    }
  }

  @override
  void dispose() {
    widget.manager.removeListener(_handleManagerChanged);
    super.dispose();
  }

  void _handleManagerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _selectStudySet(BuildContext context, Flashcard card) async {
    final sets = StudySetManager.listenable.value;
    if (sets.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No study sets available yet.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _StudySetPickerSheet(
        sets: sets,
        currentId: card.studySetId,
      ),
    );
    if (selected == null) return;
    widget.manager.attachToStudySet(cardId: card.id, studySetId: selected);
  }

  void _detachFromStudySet(Flashcard card) {
    widget.manager.detachFromStudySet(card.id);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<StudySet>>(
      valueListenable: StudySetManager.listenable,
      builder: (context, sets, _) {
        final cards = widget.manager.all;
        if (cards.isEmpty) {
          return const _EmptyState();
        }

        final unassigned = cards.where((c) => c.studySetId == null).toList();
        final assigned = cards.where((c) => c.studySetId != null).toList();
        final map = {for (final s in sets) s.id: s};

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (unassigned.isNotEmpty) ...[
              const _SectionTitle('Unsorted flashcards'),
              const SizedBox(height: 8),
              ...unassigned.map(
                (card) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FlashcardListTile(
                    card: card,
                    studySet: null,
                    onSelectStudySet: () => _selectStudySet(context, card),
                    onDetach: null,
                  ),
                ),
              ),
              if (assigned.isNotEmpty) const SizedBox(height: 18),
            ],
            if (assigned.isNotEmpty) ...[
              const _SectionTitle('Assigned to study sets'),
              const SizedBox(height: 8),
              ...assigned.map((card) {
                final studySet = map[card.studySetId];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FlashcardListTile(
                    card: card,
                    studySet: studySet,
                    onSelectStudySet: () => _selectStudySet(context, card),
                    onDetach: () => _detachFromStudySet(card),
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }
}

/// -------------------- CARD --------------------
class FlashcardListTile extends StatelessWidget {
  const FlashcardListTile({
    super.key,
    required this.card,
    required this.studySet,
    required this.onSelectStudySet,
    this.onDetach,
  });

  final Flashcard card;
  final StudySet? studySet;
  final VoidCallback onSelectStudySet;
  final VoidCallback? onDetach;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isAssigned = card.studySetId != null;
    final studySetLabel = studySet != null
        ? studySet!.subject != null && studySet!.subject!.isNotEmpty
            ? '${studySet!.title} · ${studySet!.subject}'
            : studySet!.title
        : isAssigned
            ? 'Unknown study set (${card.studySetId})'
            : 'Not attached to a study set';

    return Ink(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    card.term.isEmpty ? 'Untitled flashcard' : card.term,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ),
                PopupMenuButton<_CardMenuAction>(
                  icon: const Icon(Icons.more_vert, size: 20, color: Colors.black54),
                  onSelected: (value) {
                    switch (value) {
                      case _CardMenuAction.attach:
                      case _CardMenuAction.change:
                        onSelectStudySet();
                        break;
                      case _CardMenuAction.detach:
                        onDetach?.call();
                        break;
                    }
                  },
                  itemBuilder: (_) {
                    return <PopupMenuEntry<_CardMenuAction>>[
                      PopupMenuItem<_CardMenuAction>(
                        value: studySet == null
                            ? _CardMenuAction.attach
                            : _CardMenuAction.change,
                        child: Text(
                          studySet == null
                              ? 'Add to study set'
                              : 'Change study set',
                        ),
                      ),
                      if (studySet != null && onDetach != null)
                        const PopupMenuItem<_CardMenuAction>(
                          value: _CardMenuAction.detach,
                          child: Text('Remove from study set'),
                        ),
                    ];
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              card.definition.isEmpty
                  ? 'No definition yet'
                  : card.definition,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.style_outlined, size: 18, color: Colors.black54),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    studySetLabel,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (studySet?.description != null && studySet!.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 24),
                child: Text(
                  studySet!.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(color: Colors.black45),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _CardMenuAction { attach, change, detach }

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.style_outlined, size: 48, color: Colors.black26),
            SizedBox(height: 12),
            Text(
              'No flashcards yet. Create one to get started!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudySetPickerSheet extends StatelessWidget {
  const _StudySetPickerSheet({
    required this.sets,
    this.currentId,
  });

  final List<StudySet> sets;
  final String? currentId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Select a study set',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sets.length,
              itemBuilder: (context, index) {
                final set = sets[index];
                final isSelected = set.id == currentId;
                return ListTile(
                  title: Text(set.title),
                  subtitle: set.subject != null
                      ? Text(set.subject!)
                      : null,
                  trailing:
                      isSelected ? const Icon(Icons.check, color: Colors.teal) : null,
                  onTap: () => Navigator.of(context).pop(set.id),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
