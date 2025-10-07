import 'package:flutter/material.dart';
import 'package:study_application/manager/explanation_manager.dart';
import 'package:study_application/manager/studysets_manager.dart';
import 'package:study_application/model/explanation.dart';
import 'package:study_application/model/study_set.dart';

class ExplanationsTab extends StatefulWidget {
  const ExplanationsTab({super.key, this.onSearchTap});

  final VoidCallback? onSearchTap;

  @override
  State<ExplanationsTab> createState() => _ExplanationsTabState();
}

class _ExplanationsTabState extends State<ExplanationsTab> {
  @override
  void initState() {
    super.initState();
    ExplanationManager.loadAll();
    StudySetManager.loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ExplanationManager.loadingAll,
      builder: (_, loading, __) {
        return ValueListenableBuilder<String?>(
          valueListenable: ExplanationManager.errorAll,
          builder: (_, error, __) {
            return ValueListenableBuilder<List<Explanation>>(
              valueListenable: ExplanationManager.listenableAll,
              builder: (_, explanations, __) {
                return ValueListenableBuilder<List<StudySet>>(
                  valueListenable: StudySetManager.listenable,
                  builder: (_, sets, __) {
                    final setMap = {for (final set in sets) set.id: set};
                    final entries = explanations
                        .map((exp) => _ExplanationEntry(exp, setMap[exp.studySetId]))
                        .toList();

                    if (loading && entries.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (error != null && entries.isEmpty) {
                      return _ErrorState(message: error);
                    }
                    if (entries.isEmpty) {
                      return const _ErrorState(
                        message: 'No explanations available yet. Upload one to get started! ',
                      );
                    }

                    final listView = ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final entry = entries[i];
                        return ExplanationCard(
                          explanation: entry.explanation,
                          studySet: entry.studySet,
                          onTap: () {},
                          onMore: () {},
                        );
                      },
                    );

                    if (error == null && !loading) {
                      return listView;
                    }

                    return Column(
                      children: [
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: _ErrorBanner(message: error),
                          ),
                        Expanded(
                          child: Stack(
                            children: [
                              listView,
                              if (loading)
                                const Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: 16),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class ExplanationCard extends StatelessWidget {
  const ExplanationCard({
    super.key,
    required this.explanation,
    required this.studySet,
    this.onTap,
    this.onMore,
  });

  final Explanation explanation;
  final StudySet? studySet;
  final VoidCallback? onTap;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final source = studySet?.title ?? 'Unknown Study Set';
    final category = studySet?.subject ?? 'Unknown Subject';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _docIcon(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      explanation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onMore,
                    child: const Icon(Icons.more_vert,
                        size: 18, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${_sizeStr(explanation.sizeMB)} MB  ·  from $source',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEFF1F5)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _categoryChip(category),
                  const Spacer(),
                  if (explanation.views != null) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.public, size: 18, color: Colors.black54),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _sizeStr(double mb) {
    final isInt = mb.truncateToDouble() == mb;
    return isInt ? mb.toStringAsFixed(0) : mb.toStringAsFixed(1);
  }

  Widget _docIcon() {
    return Container(
      height: 28,
      width: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Image.asset(
          'assets/icons/file.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _categoryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade800,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ExplanationEntry {
  const _ExplanationEntry(this.explanation, this.studySet);

  final Explanation explanation;
  final StudySet? studySet;
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_outlined,
                size: 48, color: Colors.black26),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
