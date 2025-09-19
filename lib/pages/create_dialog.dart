import 'package:flutter/material.dart';

/// Trả về Future để chỗ gọi có thể `await` (đổi icon +/X)
Future<void> openCreateBubbles(
  BuildContext context, {
  Color mainColor = const Color(0xFFF24466),
  double centerSize = 60,
  double sideSize = 56,
  double navBottomPadding = 12,
  double lift = 28,
  VoidCallback? onCard,
  VoidCallback? onNote,
  VoidCallback? onFile,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => _BubbleOverlay(
      mainColor: mainColor,
      centerSize: centerSize,
      sideSize: sideSize,
      navBottomPadding: navBottomPadding,
      lift: lift,
      onCard: onCard,
      onNote: onNote,
      onFile: onFile,
    ),
    transitionBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
  );
}

class _BubbleOverlay extends StatefulWidget {
  final Color mainColor;
  final double centerSize;
  final double sideSize;
  final double navBottomPadding;
  final double lift;
  final VoidCallback? onCard, onNote, onFile;

  const _BubbleOverlay({
    required this.mainColor,
    required this.centerSize,
    required this.sideSize,
    required this.navBottomPadding,
    required this.lift,
    this.onCard,
    this.onNote,
    this.onFile,
  });

  @override
  State<_BubbleOverlay> createState() => _BubbleOverlayState();
}

class _BubbleOverlayState extends State<_BubbleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320))
    ..forward();

  // Staggered curves
  late final Animation<double> centerIn = CurvedAnimation(
      parent: c, curve: const Interval(0.00, 0.70, curve: Curves.easeOutBack));
  late final Animation<double> leftIn = CurvedAnimation(
      parent: c, curve: const Interval(0.15, 1.00, curve: Curves.easeOutBack));
  late final Animation<double> rightIn = CurvedAnimation(
      parent: c, curve: const Interval(0.25, 1.00, curve: Curves.easeOutBack));

  void _close() => Navigator.of(context).maybePop();

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bubblesBaseline =
        56 + widget.navBottomPadding + bottomInset + widget.lift;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Tap ngoài để đóng
        Positioned.fill(
          child:
              GestureDetector(onTap: _close, behavior: HitTestBehavior.opaque),
        ),

        // 3 bubbles PNG + animation (scale + fade + slide up)
        Positioned(
          bottom: bubblesBaseline,
          child: Row(
            children: [
              _AnimatedBubble(
                anim: leftIn,
                child: _Bubble(
                  size: widget.sideSize,
                  color: Colors.yellow.shade100,
                  iconPath: 'assets/icons/flashcard.png',
                  onTap: () {
                    widget.onCard?.call();
                    _close();
                  },
                ),
              ),
              const SizedBox(width: 28),
              _AnimatedBubble(
                anim: centerIn,
                offsetY: -16,
                child: _Bubble(
                  size: widget.centerSize,
                  color: Colors.blue.shade100,
                  iconPath: 'assets/icons/notepad.png',
                  onTap: () {
                    widget.onNote?.call();
                    _close();
                  },
                ),
              ),
              const SizedBox(width: 28),
              _AnimatedBubble(
                anim: rightIn,
                child: _Bubble(
                  size: widget.sideSize,
                  color: Colors.green.shade100,
                  iconPath: 'assets/icons/upload.png',
                  onTap: () {
                    widget.onFile?.call();
                    _close();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Gói hiệu ứng: scale + fade + slide-up
class _AnimatedBubble extends StatelessWidget {
  final Animation<double> anim;
  final Widget child;
  final double offsetY;

  const _AnimatedBubble({
    required this.anim,
    required this.child,
    this.offsetY = 0,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(anim),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, .20), end: Offset.zero)
            .animate(anim),
        child: ScaleTransition(
          scale: Tween<double>(begin: .7, end: 1).animate(anim),
          child: Transform.translate(offset: Offset(0, offsetY), child: child),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size;
  final Color color;
  final String iconPath;
  final VoidCallback onTap;

  const _Bubble({
    required this.size,
    required this.color,
    required this.iconPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 28,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // PNG icon
            SizedBox(
              width: size * 0.55,
              height: size * 0.55,
              child: Image.asset(iconPath, fit: BoxFit.contain),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}
