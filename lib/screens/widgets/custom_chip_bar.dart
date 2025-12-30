import 'package:flutter/material.dart';

class CustomChipBar extends StatelessWidget {
  final List<String> values;
  final String? selectedValue;
  final Function(String) onSelected;
  final Color? selectedColor;
  final Color? unselectedColor;
  final EdgeInsets padding;
  final VoidCallback? onAdd;

  const CustomChipBar({
    super.key,
    required this.values,
    this.selectedValue,
    required this.onSelected,
    this.selectedColor,
    this.unselectedColor,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0),
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Wrap(
        spacing: 8.0, // Espacio horizontal entre chips
        runSpacing: 0.0, // Espacio vertical entre líneas de chips
        children: [
          ...values.map((value) {
            final isSelected = value == selectedValue;
            return ChoiceChip(
              label: Text(value),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onSelected(value);
                }
              },
              selectedColor:
                  selectedColor ??
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
              backgroundColor: unselectedColor ?? Colors.grey[100],
              checkmarkColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                ),
              ),
            );
          }),
          if (onAdd != null)
            ActionChip(
              avatar: Icon(
                Icons.add,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: SizedBox.shrink(),
              onPressed: onAdd,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
            ),
        ],
      ),
    );
  }
}
