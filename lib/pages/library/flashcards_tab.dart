import 'package:flutter/material.dart';

/// -------------------- PAGE --------------------
class FlashcardsTab extends StatefulWidget {
  const FlashcardsTab({super.key});

  @override
  State<FlashcardsTab> createState() => _FlashcardsTabState();
}

class _FlashcardsTabState extends State<FlashcardsTab> {
  // Mock data
  late final List<FlashcardSet> _all = [
    FlashcardSet(
      title: 'Cell Membranes',
      count: 20,
      subject: 'Microbiology',
      category: 'Biology',
    ),
    FlashcardSet(
      title: 'Software Development Lifecycle',
      count: 25,
      subject: 'Computer Science',
      category: 'Computer Science',
    ),
    FlashcardSet(
      title: 'Digital Logic Design',
      count: 15,
      subject: 'Engineering Technique',
      category: 'Engineering',
    ),
    FlashcardSet(
      title: 'Algebraic Structures',
      count: 30,
      subject: 'Mathematics for Dummies',
      category: 'Mathematics',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final data = _all;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // List flashcards
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => FlashcardSetCard(
              item: data[i],
              onMore: () {},
              onTap: () {},
            ),
          ),
        ),
      ],
    );
  }
}

/// -------------------- MODEL --------------------
class FlashcardSet {
  final String title;
  final int count;
  final String subject;
  final String category;
  FlashcardSet({
    required this.title,
    required this.count,
    required this.subject,
    required this.category,
  });
}

/// -------------------- CARD --------------------
class FlashcardSetCard extends StatelessWidget {
  final FlashcardSet item;
  final VoidCallback? onTap;
  final VoidCallback? onMore;

  const FlashcardSetCard({
    super.key,
    required this.item,
    this.onTap,
    this.onMore,
  });

  static const String _kFlashIcon = 'assets/icons/flash-card.png';

  @override
  Widget build(BuildContext context) {
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
              // Hàng đầu: icon PNG + tiêu đề + globe + more
              Row(
                children: [
                  _leadingPng(_kFlashIcon),
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
                  const SizedBox(width: 8),
                ],
              ),

              const SizedBox(height: 6),

              // Meta: "20 flashcards · from Microbiology"
              Text(
                '${item.count} flashcards  ·  from ${item.subject}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEFF1F5)),
              const SizedBox(height: 10),

              // Dòng dưới: category chip
              Row(
                children: [
                  _categoryChip(item.category),
                  const Spacer(),
                  const Icon(Icons.public, size: 18, color: Colors.black54),
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
      ),
    );
  }

  // Icon PNG chung (bao trong khung mềm đồng bộ style)
  Widget _leadingPng(String asset) {
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
          asset,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // Soft category chip (e.g., "Biology")
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
