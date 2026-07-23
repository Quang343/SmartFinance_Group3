import 'package:flutter/material.dart';
import 'app_breakpoints.dart';
import '../widgets/scale_on_tap.dart';

class AdaptiveFilterOption<T> {
  final T value;
  final String label;
  final IconData? icon;

  const AdaptiveFilterOption({
    required this.value,
    required this.label,
    this.icon,
  });
}

class AdaptiveFilterBar<TStatus, TCategory> extends StatelessWidget {
  final TStatus selectedStatus;
  final ValueChanged<TStatus> onStatusChanged;
  final List<AdaptiveFilterOption<TStatus>> statusOptions;

  final TCategory selectedCategory;
  final ValueChanged<TCategory> onCategoryChanged;
  final List<AdaptiveFilterOption<TCategory>> categoryOptions;

  final Widget? dateFilterWidget;
  final int activeFilterCount;
  final VoidCallback? onOpenFilterSheet;

  const AdaptiveFilterBar({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.statusOptions,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.categoryOptions,
    this.dateFilterWidget,
    this.activeFilterCount = 0,
    this.onOpenFilterSheet,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = AppBreakpoints.of(context);

    if (deviceType == DeviceType.desktopXL) {
      return _buildDesktopXLBar(context, isDark);
    } else if (deviceType == DeviceType.desktop) {
      return _buildDesktopDropdownBar(context, isDark);
    } else {
      return _buildMobilePillBar(context, isDark);
    }
  }

  Widget _buildDesktopXLBar(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Trạng thái: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: statusOptions.map((opt) {
                    final isSelected = opt.value == selectedStatus;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(opt.label),
                        selected: isSelected,
                        onSelected: (_) => onStatusChanged(opt.value),
                        selectedColor: const Color(0xFF00D09E),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (dateFilterWidget != null) dateFilterWidget!,
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              'Danh mục: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categoryOptions.map((opt) {
                    final isSelected = opt.value == selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(opt.label),
                        selected: isSelected,
                        onSelected: (_) => onCategoryChanged(opt.value),
                        selectedColor: const Color(0xFF00D09E),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopDropdownBar(BuildContext context, bool isDark) {
    final bgColor = isDark ? const Color(0xFF0D251C) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list_rounded, color: Color(0xFF00D09E), size: 20),
          const SizedBox(width: 10),
          // Status Dropdown
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TStatus>(
                value: selectedStatus,
                isExpanded: true,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                dropdownColor: bgColor,
                items: statusOptions.map((opt) {
                  return DropdownMenuItem<TStatus>(
                    value: opt.value,
                    child: Text('Trạng thái: ${opt.label}'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) onStatusChanged(val);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Category Dropdown
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TCategory>(
                value: selectedCategory,
                isExpanded: true,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                dropdownColor: bgColor,
                items: categoryOptions.map((opt) {
                  return DropdownMenuItem<TCategory>(
                    value: opt.value,
                    child: Text('Danh mục: ${opt.label}'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) onCategoryChanged(val);
                },
              ),
            ),
          ),
          if (dateFilterWidget != null) ...[
            const SizedBox(width: 12),
            dateFilterWidget!,
          ],
        ],
      ),
    );
  }

  Widget _buildMobilePillBar(BuildContext context, bool isDark) {
    final bgColor = isDark ? const Color(0xFF0D251C) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0);

    return Row(
      children: [
        ScaleOnTap(
          onTap: onOpenFilterSheet != null ? () => onOpenFilterSheet!() : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: activeFilterCount > 0 ? const Color(0xFF00D09E) : bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: activeFilterCount > 0 ? const Color(0xFF00D09E) : borderColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: activeFilterCount > 0 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(width: 6),
                Text(
                  'Bộ lọc',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: activeFilterCount > 0 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
                if (activeFilterCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$activeFilterCount',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF00D09E),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: statusOptions.map((opt) {
                final isSelected = opt.value == selectedStatus;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(opt.label),
                    selected: isSelected,
                    onSelected: (_) => onStatusChanged(opt.value),
                    selectedColor: const Color(0xFF00D09E),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
