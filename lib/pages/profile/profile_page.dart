import 'package:flutter/material.dart';
import 'package:study_application/manager/studysets_manager.dart';
import 'package:study_application/manager/user_manager.dart';
import 'package:study_application/models/study_set.dart';
import 'package:study_application/models/user.dart';
import 'package:study_application/utils/color.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  static const routeName = '/profile';

  @override
  Widget build(BuildContext context) {
    final User user = UserManager.demoUser;
    // Các set do bạn tạo (byYou == true). Nếu muốn tất cả thì bỏ where(...)
    final List<StudySet> studySets =
        StudySetManager.demoSets.where((e) => e.byYou).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ---------- Header ----------
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00A6B2), Color(0xFF01B1A5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 46,
                      // backgroundImage: AssetImage(user.avatarUrl),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),

            // ---------- User Info ----------
            Text(
              user.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            // Text(
            //   '${user.age} years old • ${user.degree} in ${user.subject}',
            //   style: TextStyle(color: Colors.grey.shade700),
            // ),
            // const SizedBox(height: 6),
            // Text(
            //   '${user.university} • Year: ${user.year}',
            //   style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            // ),

            const SizedBox(height: 20),
            const Divider(thickness: 1, color: Color(0xFFEFF1F5)),
            const SizedBox(height: 10),

            // ---------- Study Sets ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Study Sets',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: studySets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final item = studySets[i];
                      final Color accent = AppColors.randomAccent();

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
                        child: ListTile(
                          leading: Container(
                            height: 28,
                            width: 28,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.folder, size: 18, color: accent),
                          ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          subtitle: Text(
                            '${item.flashcardCount} flashcards · ${item.explanationCount} explanations',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12),
                          ),
                          trailing: const Icon(Icons.more_vert,
                              size: 18, color: Colors.black54),
                          onTap: () {},
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
