import 'package:flutter/material.dart';
import 'package:study_application/manager/flashcard_manager.dart';
import 'package:study_application/model/flashcard.dart';

/// -------------------- PAGE --------------------
class FlashcardsTab extends StatelessWidget {
  const FlashcardsTab({super.key, required this.manager});

  final FlashcardManager manager;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) {
        final cards = manager.all;
        if (cards.isEmpty) {
          return const _EmptyFlashcards();
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _FlashcardCard(card: cards[i]),
        );
      },
    );
  }
}

class _EmptyFlashcards extends StatelessWidget {
  const _EmptyFlashcards();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.style_outlined, size: 48, color: Colors.black26),
            SizedBox(height: 12),
            Text(
              'No flashcards yet. Create some to see them here.',
              textAlign: TextAlign.center,
              style: TextStyle(
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

class _FlashcardCard extends StatelessWidget {
  const _FlashcardCard({required this.card});

  final Flashcard card;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            Text(
              card.term,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              card.definition,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
