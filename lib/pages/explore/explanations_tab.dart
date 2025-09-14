import 'package:flutter/material.dart';

/// ===================== PUBLIC TAB =====================
class ExplanationsTab extends StatelessWidget {
  /// Nếu không truyền [items], tab sẽ dùng [_mockItems].
  ExplanationsTab({super.key, List<ExplanationItem>? items, this.onSearchTap})
      : items = items ?? _mockItems;

  final List<ExplanationItem> items;
  final VoidCallback? onSearchTap;

  // --------- MOCK DATA (có thể sửa/ thêm tuỳ ý) ---------
  static final List<ExplanationItem> _mockItems = <ExplanationItem>[
    ExplanationItem(
      id: 'e1',
      title: 'The Structure and Function of Cell',
      sizeMB: 1.2,
      source: 'Microbiology',
      category: 'Biology',
    ),
    ExplanationItem(
      id: 'e2',
      title: 'Data Structures: An Overview',
      sizeMB: 2.3,
      source: 'Computer Vision',
      category: 'Computer Science',
    ),
    ExplanationItem(
      id: 'e3',
      title: 'Fluid Mechanics: Basic Principles',
      sizeMB: 1.6,
      source: 'Engineering School',
      category: 'Engineering',
    ),
    ExplanationItem(
      id: 'e4',
      title: 'Algebraic Equations and Inequalities',
      sizeMB: 1.8,
      source: 'Mathematics',
      category: 'Mathematics',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => ExplanationCard(
        item: items[i],
        onTap: () {},
        onMore: () {},
      ),
    );
  }
}

/// ===================== MODEL =====================
class ExplanationItem {
  final String id;
  final String title;
  final double sizeMB;
  final String source;
  final String category;
  final int? views;

  const ExplanationItem({
    required this.id,
    required this.title,
    required this.sizeMB,
    required this.source,
    required this.category,
    this.views,
  });
}

/// ===================== CARD =====================
class ExplanationCard extends StatelessWidget {
  final ExplanationItem item;
  final VoidCallback? onTap;
  final VoidCallback? onMore;

  const ExplanationCard({
    super.key,
    required this.item,
    this.onTap,
    this.onMore,
  });

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
              // Hàng trên: icon + title + more
              Row(
                children: [
                  _docIcon(),
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
                  GestureDetector(
                    onTap: onMore,
                    child: const Icon(Icons.more_vert,
                        size: 18, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Meta: size + source
              Text(
                '${_sizeStr(item.sizeMB)} MB  ·  from ${item.source}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEFF1F5)),
              const SizedBox(height: 10),

              // Chip + views
              Row(
                children: [
                  _categoryChip(item.category),
                  const Spacer(),
                  if (item.views != null) ...[
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
    // 1 chữ số thập phân nếu cần
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
