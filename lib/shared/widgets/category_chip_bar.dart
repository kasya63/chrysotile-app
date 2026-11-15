import 'package:chrysotile_app/core/models/post_models.dart';
import 'package:chrysotile_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class CategoryChipBar extends StatelessWidget {
  const CategoryChipBar({
    super.key,
    required this.categories,
    required this.selectedSlug,
    required this.onSelected,
  });

  final List<CategoryInfo> categories;
  final String? selectedSlug;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final scale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.9).toDouble();
    return SizedBox(
      height: 22 + 20.0 * scale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = selectedSlug == category.slug;
          return _CategoryChip(
            label: category.name,
            selected: selected,
            onTap: () {
              if (selected) {
                onSelected(null);
              } else {
                onSelected(category.slug);
              }
            },
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: selected
          ? AppColors.blue
          : (isDark ? AppColors.darkSurface : Colors.white),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: selected
                ? null
                : Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.chipBorder,
                    width: 0.5,
                  ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: selected
                  ? Colors.white
                  : (isDark ? AppColors.darkText : Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}
