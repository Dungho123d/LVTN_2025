import 'package:flutter/material.dart';
import 'package:study_application/manager/explanation_manager.dart';
import 'package:study_application/manager/flashcard_manager.dart';
import 'package:study_application/manager/studysets_manager.dart';
import 'package:study_application/model/study_set.dart';
import 'package:study_application/pages/bottom_nav.dart';
import 'package:study_application/pages/explore/study_sets_tab.dart';
import 'package:study_application/pages/flashcards/create_flashcard.dart';
import 'package:study_application/pages/library/library_page.dart';
import 'package:study_application/pages/profile/profile_page.dart';
import 'package:study_application/pages/study_sets/create_set.dart';
import 'package:study_application/pages/study_sets/detail/materials.dart';
import 'package:study_application/utils/color.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _current = 0;

  late final _pages = [
    const _HomeBody(),
    ExplorePage(),
    LibraryPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    StudySetManager.loadInitialData();
    FlashcardManager.loadAll();
    ExplanationManager.loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(index: _current, children: _pages),

          // Nút tròn draggable
          DraggableCircleButton(
            iconPng: 'assets/images/logo2.png',
            onTap: () {
              // TODO: mở chatbot hoặc support
            },
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _current,
        onItemTap: (i) => setState(() => _current = i),
        onCenterTap: () => setState(() => _current = 2),
      ),
    );
  }
}

//
// ---------------------- UI TRANG HOME ----------------------
//

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final double bottomReserve = media.padding.bottom + 24;

    return ColoredBox(
      color: const Color(0xFFF6F7FB),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomReserve),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hàng trên cùng: logo + chip
              Row(
                children: [
                  Image.asset('assets/images/logo.png', height: 60),
                  const Spacer(),
                  _ChipIcon(icon: Icons.local_fire_department, value: '0'),
                  const SizedBox(width: 8),
                  _ChipIcon(icon: Icons.shield_outlined, value: '2'),
                  const SizedBox(width: 8),
                  _ChipIcon(icon: Icons.monetization_on_outlined, value: '45'),
                  const SizedBox(width: 8),
                  const CircleAvatar(radius: 14, child: Text('H')),
                ],
              ),
              const SizedBox(height: 14),

              // Ô tìm kiếm
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: const TextField(
                  decoration: InputDecoration(
                    icon: Icon(Icons.search, color: Colors.grey),
                    hintText: 'Find study material or friends',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Recent Study Sets
              const _StudySetSection(),
              const SizedBox(height: 20),

              // Jump Back Into
              const _SectionTitle('Jump Back Into'),
              const SizedBox(height: 10),
              SizedBox(
                height: 138,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _JumpBackCard(
                      iconPath: 'assets/icons/flash_card.png',
                      title: 'Chapter 9 - Aggregate Demand',
                      subtitle: 'Viewed 1d ago',
                    ),
                    _JumpBackCard(
                      iconPath: 'assets/icons/flash_card.png',
                      title: 'Causes of Shift in Supply Demand …',
                      subtitle: 'Viewed 1d ago',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Create
              const _SectionTitle('Create'),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.2,
                children: [
                  _CreateCard(
                    iconPath: 'assets/icons/upload.png',
                    title: 'Upload a file',
                    subtitle: '& get material',
                    onTap: () {
                      // TODO: xử lý upload file
                      debugPrint("Upload file tapped");
                    },
                  ),
                  _CreateCard(
                    iconPath: 'assets/icons/folder.png',
                    title: 'Create study sets',
                    subtitle: '& get material',
                    onTap: () async {
                      final form = await openCreateStudySetDialog(context);
                      if (form == null) return;

                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StudySetDetailPage(
                            studySet: form.studySet,
                            title: '',
                          ),
                        ),
                      );
                    },
                  ),
                  _CreateCard(
                    iconPath: 'assets/icons/notepad.png',
                    title: 'Create notes',
                    subtitle: 'without AI for free',
                    onTap: () {
                      debugPrint("Create notes tapped");
                    },
                  ),
                  _CreateCard(
                    iconPath: 'assets/icons/flashcard.png',
                    title: 'Create flashcards',
                    subtitle: 'without AI for free',
                    onTap: () async {
                      await StudySetManager.loadInitialData();
                      final sets = StudySetManager.current;
                      if (sets.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Create a study set before adding flashcards.'),
                            ),
                          );
                        }
                        return;
                      }
                      final StudySet target =
                          sets.firstWhere((set) => set.byYou, orElse: () => sets.first);

                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateFlashcardsPage(
                            manager: FlashcardManager.instance,
                            studySetId: target.id,
                          ),
                        ),
                      );
                      debugPrint("Create flashcards tapped");
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

//
// ---------------------- WIDGET CON ----------------------
//

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );
  }
}

class _ChipIcon extends StatelessWidget {
  final IconData icon;
  final String value;
  const _ChipIcon({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black87),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// class _PromoCard extends StatelessWidget {
//   final Color bg;
//   final String text;
//   const _PromoCard({required this.bg, required this.text});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: bg,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//             ),
//           ),
//           const CircleAvatar(
//             radius: 16,
//             backgroundColor: Colors.white,
//             child: Icon(Icons.arrow_forward_ios, size: 14),
//           ),
//         ],
//       ),
//     );
//   }
// }

class _JumpBackCard extends StatelessWidget {
  final String iconPath; // đường dẫn file PNG
  final String title;
  final String subtitle;

  const _JumpBackCard({
    required this.iconPath,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9ECF3)), // viền nhẹ
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // icon PNG
          Image.asset(
            iconPath,
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),

          // title
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),

          const Spacer(),

          // subtitle
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateCard extends StatelessWidget {
  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _CreateCard({
    required this.iconPath,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap, // <-- sử dụng callback
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE9ECF3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(iconPath),
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudySetSection extends StatelessWidget {
  const _StudySetSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + View All
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent Study Sets',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () {}, // TODO: điều hướng trang “All”
              child: Row(
                children: const [
                  Text('View All'),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Danh sách ngang các card
        SizedBox(
          height: 150,
          child: ValueListenableBuilder<bool>(
            valueListenable: StudySetManager.loadingListenable,
            builder: (_, loading, __) {
              return ValueListenableBuilder<List<StudySet>>(
                valueListenable: StudySetManager.listenable,
                builder: (_, sets, __) {
                  final items = sets.take(6).toList();
                  if (loading && items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'Create your first study set to see it here.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }

                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, index) {
                      final set = items[index];
                      final accent = AppColors.randomAccent();
                      return _StudySetCard(
                        title: set.title,
                        flashcards: set.flashcardCount,
                        explanations: set.explanationCount,
                        progress: set.progress,
                        accentColor: accent,
                        isPrivate: !set.isCommunity,
                        byYou: set.byYou,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StudySetCard extends StatelessWidget {
  final String title;
  final int flashcards;
  final int explanations;

  final double progress; // 0..1
  final Color accentColor; // màu viền trái & vòng progress
  final bool isPrivate;
  final bool byYou;

  const _StudySetCard({
    required this.title,
    required this.flashcards,
    required this.explanations,
    required this.progress,
    required this.accentColor,
    this.isPrivate = false,
    this.byYou = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // dải màu bên trái
          Container(
            width: 4,
            height: 92,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),

          // nội dung chính
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // tiêu đề + vòng % bên phải
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _ProgressCircle(value: progress, color: accentColor),
                  ],
                ),
                const SizedBox(height: 8),

                // dòng counts
                Text(
                  '$flashcards flashcards . $explanations explanations',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),

                // hàng dưới: by you chip + private + menu
                Row(
                  children: [
                    if (byYou)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.person_outline, size: 14),
                            SizedBox(width: 4),
                            Text('By you',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    const Spacer(),
                    if (isPrivate)
                      Icon(Icons.lock_outline,
                          size: 18, color: Colors.grey.shade700),
                    const SizedBox(width: 10),
                    Icon(Icons.more_vert,
                        size: 18, color: Colors.grey.shade700),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCircle extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  const _ProgressCircle({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return SizedBox(
      height: 42,
      width: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value.clamp(0, 1),
            strokeWidth: 4,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            '$percent%',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class DraggableCircleButton extends StatefulWidget {
  final String iconPng;
  final Color color;
  final double size;
  final double iconSize;
  final VoidCallback onTap;

  const DraggableCircleButton({
    super.key,
    required this.iconPng,
    required this.onTap,
    this.color = const Color(0xFF00A6B2),
    this.size = 56,
    this.iconSize = 42,
  });

  @override
  State<DraggableCircleButton> createState() => _DraggableCircleButtonState();
}

class _DraggableCircleButtonState extends State<DraggableCircleButton> {
  // Vị trí mặc định: cách mép phải và dưới 100
  double posX = 0;
  double posY = 0;

  @override
  void initState() {
    super.initState();
    posX = 20;
    posY = 120;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Giới hạn không để ra ngoài màn hình
    final maxX = size.width - widget.size - 20;
    final maxY = size.height - widget.size - 120;

    return Positioned(
      right: posX,
      bottom: posY,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            posX = (posX - details.delta.dx).clamp(0.0, maxX);
            posY = (posY - details.delta.dy).clamp(0.0, maxY);
          });
        },
        onTap: widget.onTap,
        child: Container(
          height: widget.size,
          width: widget.size,
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 0, 166, 178),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(255, 0, 166, 178).withOpacity(0.3),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center, // căn giữa icon
          child: SizedBox(
            height: widget.iconSize,
            width: widget.iconSize,
            child: Image.asset(
              widget.iconPng,
              fit: BoxFit.contain,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
