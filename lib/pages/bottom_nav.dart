import 'package:flutter/material.dart';
import 'package:study_application/pages/create_dialog.dart';
import 'package:study_application/utils/theme.dart';

class CustomBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onItemTap;
  final VoidCallback onCenterTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onItemTap,
    required this.onCenterTap,
  });

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav> {
  bool _isCreateOpen = false;

  @override
  Widget build(BuildContext context) {
    const inactive = Color(0xFFB8C0CC);
    final active = AppTheme.mainTeal;

    // Tỉ lệ/thông số
    const double barHeight = 58;
    const double sideMargin = 16;
    const double cornerRadius = 30;

    const double centerDiameter = 52; // nút tròn
    const double notchGap = 10; // khoảng hở giữa nút & miệng lõm
    const double notchDepth = 20; // độ sâu lõm
    final double notchRadius = centerDiameter / 2 + notchGap;

    // Khoảng trống chính giữa cho hàng icon = đúng bề rộng nút
    const double middleReserve = centerDiameter;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: barHeight + 50, // chỗ cho nút lấn xuống
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Nền bar có phần lõm
            Positioned(
              left: sideMargin,
              right: sideMargin,
              bottom: 10,
              child: PhysicalShape(
                elevation: 8,
                color: Colors.white,
                clipper: _ConcaveClipper(
                  cornerRadius: cornerRadius,
                  notchRadius: notchRadius,
                  notchDepth: notchDepth,
                ),
                child: SizedBox(
                  height: barHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _Item(
                            icon: Icons.home_outlined,
                            label: "Home",
                            selected: widget.currentIndex == 0,
                            active: active,
                            inactive: inactive,
                            onTap: () => widget.onItemTap(0),
                          ),
                        ),
                        Expanded(
                          child: _Item(
                            icon: Icons.explore_outlined,
                            label: "Explore",
                            selected: widget.currentIndex == 1,
                            active: active,
                            inactive: inactive,
                            onTap: () => widget.onItemTap(1),
                          ),
                        ),

                        // Ô giữa rỗng – chừa chỗ cho notch/nút
                        SizedBox(width: middleReserve),

                        Expanded(
                          child: _Item(
                            icon: Icons.book_outlined,
                            label: "Library",
                            selected: widget.currentIndex == 2,
                            active: active,
                            inactive: inactive,
                            onTap: () => widget.onItemTap(2),
                          ),
                        ),
                        Expanded(
                          child: _Item(
                            icon: Icons.person_outline,
                            label: "Profile",
                            selected: widget.currentIndex == 3,
                            active: active,
                            inactive: inactive,
                            onTap: () => widget.onItemTap(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Nút tròn giữa
            Positioned(
              bottom: 10 + (barHeight - notchDepth) - centerDiameter / 2 + 32,
              child: GestureDetector(
                onTap: () async {
                  setState(() => _isCreateOpen = true);
                  await openCreateBubbles(
                    context,
                    mainColor: AppTheme.mainTeal,
                    centerSize: centerDiameter,
                    sideSize: 48,
                    navBottomPadding: 10,
                    lift: 36,
                  );
                  if (!mounted) return;
                  setState(() => _isCreateOpen = false);
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => RotationTransition(
                    turns: Tween<double>(begin: .75, end: 1).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Container(
                    key: ValueKey(_isCreateOpen),
                    height: centerDiameter,
                    width: centerDiameter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isCreateOpen ? Colors.red : AppTheme.mainTeal,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_isCreateOpen ? Colors.red : AppTheme.mainTeal)
                                  .withOpacity(0.35),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isCreateOpen ? Icons.close_rounded : Icons.add,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clipper phần lõm
class _ConcaveClipper extends CustomClipper<Path> {
  final double cornerRadius;
  final double notchRadius;
  final double notchDepth;

  _ConcaveClipper({
    required this.cornerRadius,
    required this.notchRadius,
    required this.notchDepth,
  });

  @override
  Path getClip(Size size) {
    final rect = RRect.fromLTRBR(
      0,
      0,
      size.width,
      size.height,
      Radius.circular(cornerRadius),
    );
    final rectPath = Path()..addRRect(rect);

    final circleCenterY = -(notchRadius - notchDepth);
    final circlePath = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size.width / 2, circleCenterY),
        radius: notchRadius,
      ));

    return Path.combine(PathOperation.difference, rectPath, circlePath);
  }

  @override
  bool shouldReclip(_ConcaveClipper old) =>
      cornerRadius != old.cornerRadius ||
      notchRadius != old.notchRadius ||
      notchDepth != old.notchDepth;
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color active;
  final Color inactive;
  final VoidCallback onTap;

  const _Item({
    required this.icon,
    required this.label,
    required this.selected,
    required this.active,
    required this.inactive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = selected ? active : inactive;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center, // loại bỏ khoảng trắng thừa
        children: [
          Icon(icon, size: 22, color: c),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: c)),
        ],
      ),
    );
  }
}
