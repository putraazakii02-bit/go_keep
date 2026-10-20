import 'package:flutter/material.dart';
import '../utils/note_colors.dart';

class NoteColorPicker extends StatelessWidget {
  final String? selectedColorHex;
  final ValueChanged<String?> onColorSelected;

  const NoteColorPicker({
    super.key,
    this.selectedColorHex,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: NoteColors.colorNames.length,
        itemBuilder: (context, index) {
          final name = NoteColors.colorNames[index];
          final color = NoteColors.colors[name];
          final hexValue = NoteColors.hexFromColor(color);
          final isSelected = selectedColorHex == hexValue ||
              (selectedColorHex == null && name == 'Default');

          final displayColor = color == null
              ? (isDark ? const Color(0xFF2C2C2C) : Colors.white)
              : (isDark ? NoteColors.cardColor(hexValue, true) : color);

          return GestureDetector(
            onTap: () => onColorSelected(hexValue),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: displayColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : (isDark ? Colors.white30 : Colors.black26),
                  width: isSelected ? 2.5 : 1,
                ),
              ),
              child: color == null
                  ? Icon(
                      Icons.block,
                      size: 18,
                      color: isDark ? Colors.white38 : Colors.black38,
                    )
                  : isSelected
                      ? const Icon(
                          Icons.check,
                          size: 18,
                          color: Colors.black54,
                        )
                      : null,
            ),
          );
        },
      ),
    );
  }
}
