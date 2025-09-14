import 'package:flutter/material.dart';

class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key});

  // mock numbers
  static const double learned = .58;
  static const double review = .20;
  static const double notYet = .22;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Center(
          child: SizedBox(
            height: 180,
            width: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(180),
                  painter: _DonutPainter(
                    segments: const [
                      _Seg(learned, Color(0xFF01B1A5)),
                      _Seg(review, Color(0xFFFF6B5F)),
                      _Seg(notYet, Color(0xFFDADFE7)),
                    ],
                    thickness: 14,
                    gapRadians: .05,
                  ),
                ),
                const Text('58%',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        Column(
          children: const [
            _Legend(
                color: Color(0xFF01B1A5), label: 'Learned', valueText: '58%'),
            SizedBox(height: 12),
            _Legend(
                color: Color(0xFFFF6B5F),
                label: 'To be reviewed',
                valueText: '20%'),
            SizedBox(height: 12),
            _Legend(
                color: Color(0xFFDADFE7),
                label: 'Not learned',
                valueText: '22%'),
          ],
        ),

        const SizedBox(height: 24),

        // Recent
        Row(
          children: const [
            Expanded(
              child: Text('Recent',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.black87)),
            ),
            Text('View All',
                style: TextStyle(
                    color: Color(0xFF01B1A5), fontWeight: FontWeight.w700)),
            SizedBox(width: 6),
            Icon(Icons.arrow_right_alt, color: Color(0xFF01B1A5)),
          ],
        ),
        const SizedBox(height: 12),

        const _RecentCard(title: 'Cell Membranes', subtitle: '20 flashcards'),
        const SizedBox(height: 10),
        const _RecentCard(title: 'Bacteriology', subtitle: '25 flashcards'),
      ],
    );
  }
}

/// ========== Legend ==========
class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final String valueText;

  const _Legend({
    required this.color,
    required this.label,
    required this.valueText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 16,
          width: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          valueText,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// ========== Recent Card ==========
class _RecentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _RecentCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Row(
        children: [
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE7E9F0)),
            ),
            padding: const EdgeInsets.all(4),
            child:
                Image.asset('assets/icons/flash-card.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.more_vert, color: Colors.black54),
        ],
      ),
    );
  }
}

/// ========== Donut Painter ==========
class _Seg {
  final double percent;
  final Color color;
  const _Seg(this.percent, this.color);
}

class _DonutPainter extends CustomPainter {
  final List<_Seg> segments;
  final double thickness;
  final double gapRadians;
  const _DonutPainter(
      {required this.segments, this.thickness = 14, this.gapRadians = .04});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = thickness;

    double start = -90 * (3.1415926535 / 180.0);
    for (final s in segments) {
      final sweep = s.percent * (2 * 3.1415926535) - gapRadians;
      if (sweep <= 0) {
        start += s.percent * (2 * 3.1415926535);
        continue;
      }
      paint.color = s.color;
      canvas.drawArc(Rect.fromCircle(center: center, radius: r), start, sweep,
          false, paint);
      start += s.percent * (2 * 3.1415926535);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.segments != segments ||
      old.thickness != thickness ||
      old.gapRadians != gapRadians;
}
