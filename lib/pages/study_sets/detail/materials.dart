import 'package:flutter/material.dart';
import 'package:study_application/pages/study_sets/detail/progress_tab.dart';

class StudySetDetailPage extends StatefulWidget {
  final String title;
  const StudySetDetailPage({super.key, required this.title});

  @override
  State<StudySetDetailPage> createState() => _StudySetDetailPageState();
}

class _StudySetDetailPageState extends State<StudySetDetailPage> {
  int _tab = 0; // 0 = Material, 1 = Your Progress

  // ---------------- Mock data ----------------
  final _flash = const <_FlashItem>[
    _FlashItem(title: 'Cell Membranes', cards: 20),
    _FlashItem(title: 'Bacteriology', cards: 25),
  ];

  final _exps = const <_ExplanationItem>[
    _ExplanationItem(title: 'The Structure and Function of Cell', sizeMB: 1.2),
    _ExplanationItem(title: 'Medical Virology', sizeMB: 2.5),
  ];
  // -------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF6F7FB),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.w800),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 6),
            child: Icon(Icons.more_vert, color: Colors.black87),
          )
        ],
      ),

      // Bottom big button
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A6B2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999)),
              elevation: 6,
              shadowColor: const Color(0xFF00A6B2).withOpacity(.35),
            ),
            onPressed: () {},
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add to My Library',
              style:
                  TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ),
      ),

      // --------- FIX: không lồng ListView, dùng Column + Expanded ----------
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _TwoPillsTab(
                current: _tab, onChanged: (v) => setState(() => _tab = v)),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _tab == 0
                ? _MaterialTab(flash: _flash, exps: _exps)
                : const ProgressTab(),
          ),
        ],
      ),
    );
  }
}

/// ================== Material Tab (scroll riêng) ==================
class _MaterialTab extends StatelessWidget {
  final List<_FlashItem> flash;
  final List<_ExplanationItem> exps;

  const _MaterialTab({required this.flash, required this.exps});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Row(
          children: [
            _softIcon('assets/icons/flash-card.png'),
            const SizedBox(width: 10),
            Expanded(
              child: _SectionHeader(
                title: 'Flashcards (${flash.length})',
                onViewAll: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...flash.map((e) => _SoftCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 6),
                        Text('${e.cards} cards',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.more_vert, color: Colors.black54),
                ],
              ),
            )),
        const SizedBox(height: 16),
        Row(
          children: [
            _softIcon('assets/icons/file.png'),
            const SizedBox(width: 10),
            Expanded(
              child: _SectionHeader(
                title: 'Explanations (${exps.length})',
                onViewAll: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...exps.map((e) => _SoftCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 6),
                        Text('${_sizeStr(e.sizeMB)} MB',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.more_vert, color: Colors.black54),
                ],
              ),
            )),
      ],
    );
  }
}

/// ================== Small building blocks ==================
class _TwoPillsTab extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChanged;
  const _TwoPillsTab({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final active = const Color(0xFF00A6B2);
    Widget pill(String text, bool sel, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel ? active : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sel ? active : const Color(0xFFE7E9F0)),
              boxShadow: sel
                  ? [
                      BoxShadow(
                          color: active.withOpacity(.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6))
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(text,
                style: TextStyle(
                    color: sel ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w800)),
          ),
        );

    return Row(
      children: [
        Expanded(child: pill('Material', current == 0, () => onChanged(0))),
        const SizedBox(width: 10),
        Expanded(
            child: pill('Your Progress', current == 1, () => onChanged(1))),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;
  const _SectionHeader({required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.black87))),
        GestureDetector(
          onTap: onViewAll,
          child: Row(children: const [
            Text('View All',
                style: TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.w700)),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward, size: 16, color: Colors.black87),
          ]),
        ),
      ],
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  const _SoftCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECF3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 8))
        ],
      ),
      child: child,
    );
  }
}

Widget _softIcon(String asset) {
  return Container(
    height: 28,
    width: 28,
    decoration: BoxDecoration(
      color: const Color(0xFFF6F7FB),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE7E9F0)),
    ),
    padding: const EdgeInsets.all(4),
    child: Image.asset(asset, fit: BoxFit.contain),
  );
}

String _sizeStr(double mb) {
  final isInt = mb.truncateToDouble() == mb;
  return isInt ? mb.toStringAsFixed(0) : mb.toStringAsFixed(1);
}

/// ---------------- Models (mock) ----------------
class _FlashItem {
  final String title;
  final int cards;
  const _FlashItem({required this.title, required this.cards});
}

class _ExplanationItem {
  final String title;
  final double sizeMB;
  const _ExplanationItem({required this.title, required this.sizeMB});
}
