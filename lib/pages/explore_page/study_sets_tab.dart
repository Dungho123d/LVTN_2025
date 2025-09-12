import 'package:flutter/material.dart';
import 'package:study_application/pages/explore_page/explanations_tab.dart';
import 'package:study_application/pages/explore_page/flashcards_tab.dart';
import 'package:study_application/pages/study_sets/detail/detail_set.dart';
import 'package:study_application/utils/color.dart'; // <-- thêm

/// ====================== PUBLIC PAGE API ======================
class ExplorePage extends StatefulWidget {
  final List<StudySetItem> items;
  final ValueChanged<ExploreTab>? onTabChanged;
  final ValueChanged<String>? onSearch;

  const ExplorePage({
    super.key,
    required this.items,
    this.onTabChanged,
    this.onSearch,
  });

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

/// ====================== STATE / UI ROOT ======================
class _ExplorePageState extends State<ExplorePage> {
  ExploreTab _currentTab = ExploreTab.studySets;
  final ValueNotifier<Set<String>> _filters = ValueNotifier(const {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: _ExploreAppBar(
        onSearchTap: () async {
          final controller = TextEditingController();
          final text = await showDialog<String>(
            context: context,
            builder: (_) => _SearchDialog(controller: controller),
          );
          if (text != null) widget.onSearch?.call(text);
        },
      ),
      body: Column(
        children: [
          _TabBarPills(
            current: _currentTab,
            onChanged: (tab) {
              setState(() => _currentTab = tab);
              widget.onTabChanged?.call(tab);
            },
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildTabBody()),
        ],
      ),
    );
  }

  List<StudySetItem> _applyFilter(
    List<StudySetItem> items,
    Set<String> filters,
    ExploreTab tab,
  ) {
    return items.where((e) {
      bool ok = true;
      if (filters.contains('Community')) ok &= e.isCommunity;
      if (filters.contains('By you')) ok &= e.byYou;
      return ok;
    }).toList();
  }

  Widget _buildTabBody() {
    switch (_currentTab) {
      case ExploreTab.studySets:
        final filtered =
            _applyFilter(widget.items, _filters.value, _currentTab);
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final item = filtered[i];
            return StudySetCard(
              item: item,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StudySetDetailPage(
                      title: item.title, // truyền tiêu đề sang trang detail
                    ),
                  ),
                );
              },
            );
          },
        );

      case ExploreTab.flashcards:
        return const FlashcardsTab();
      case ExploreTab.explanations:
        return ExplanationsTab();
    }
  }
}

/// ====================== APP BAR ======================
class _ExploreAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSearchTap;
  const _ExploreAppBar({this.onSearchTap});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFFF6F7FB),
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFF00A6B2).withOpacity(.1),
          child: const Icon(Icons.psychology_alt, color: Color(0xFF00A6B2)),
        ),
      ),
      title: const Text(
        'Explore',
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          onPressed: onSearchTap,
          icon: const Icon(Icons.search_rounded, color: Colors.black87),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _SearchDialog extends StatelessWidget {
  final TextEditingController controller;
  const _SearchDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Type to search...'),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Search')),
      ],
    );
  }
}

/// ====================== TABS (PILLS) ======================
enum ExploreTab { studySets, flashcards, explanations }

class _TabBarPills extends StatelessWidget {
  final ExploreTab current;
  final ValueChanged<ExploreTab> onChanged;
  const _TabBarPills({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 42,
        child: Row(
          children: [
            Expanded(
              child: _TabPill(
                label: 'Study Sets',
                selected: current == ExploreTab.studySets,
                onTap: () => onChanged(ExploreTab.studySets),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TabPill(
                label: 'Flashcards',
                selected: current == ExploreTab.flashcards,
                onTap: () => onChanged(ExploreTab.flashcards),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TabPill(
                label: 'Explanations',
                selected: current == ExploreTab.explanations,
                onTap: () => onChanged(ExploreTab.explanations),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color active = Color(0xFF01B1A5);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? active : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border:
              Border.all(color: selected ? active : const Color(0xFFE9ECF3)),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: active.withOpacity(.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6))
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// ====================== DOMAIN MODEL ======================
class StudySetItem {
  final String id;
  final String title;
  final int flashcards;
  final int explanations;
  final bool isCommunity;
  final bool byYou;

  const StudySetItem({
    required this.id,
    required this.title,
    required this.flashcards,
    required this.explanations,
    required this.isCommunity,
    required this.byYou,
  });
}

/// ====================== CARD ITEM ======================
class StudySetCard extends StatelessWidget {
  final StudySetItem item;
  final VoidCallback? onTap;
  final VoidCallback? onMore;

  const StudySetCard({
    super.key,
    required this.item,
    this.onTap,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = AppColors.randomAccent();

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
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dải màu trái
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 12),

                // Nội dung
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề có icon phía trước
                      // Tiêu đề có icon phía trước (có nền mềm)
                      Row(
                        children: [
                          Container(
                            height: 28,
                            width: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F7FB), // nền nhạt
                              borderRadius: BorderRadius.circular(8), // bo góc
                              border: Border.all(
                                  color: const Color(0xFFE7E9F0)), // viền mỏng
                            ),
                            padding: const EdgeInsets.all(4), // tránh dính mép
                            child: Image.asset(
                              'assets/icons/folder2.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Meta
                      Text(
                        '${item.flashcards} flashcards  ·  ${item.explanations} explanations',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 12),
                      const Divider(
                          height: 1, thickness: 1, color: Color(0xFFEFF1F5)),
                      const SizedBox(height: 10),

                      // Chips và actions
                      Row(
                        children: [
                          if (item.isCommunity)
                            _softChip(
                                label: 'Community',
                                icon: Icons.groups_2_outlined),
                          if (item.byYou) ...[
                            const SizedBox(width: 8),
                            _softChip(
                                label: 'By you', icon: Icons.person_outline),
                          ],
                          const Spacer(),
                          const Icon(Icons.public,
                              size: 18, color: Colors.black54),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: onMore,
                            child: const Icon(Icons.more_vert,
                                size: 18, color: Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _softChip({required String label, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
