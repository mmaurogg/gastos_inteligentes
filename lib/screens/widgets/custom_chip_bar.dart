import 'package:flutter/material.dart';

class CustomChipBar extends StatelessWidget {
  final String? title;
  final List<String> values;
  final String? selectedValue;
  final List<String>? selectedValues;
  final Function(String) onSelected;
  final Function(String)? onLongPress;
  final Color? selectedColor;
  final Color? unselectedColor;
  final EdgeInsets padding;
  final VoidCallback? onAdd;

  const CustomChipBar({
    super.key,
    this.title,
    required this.values,
    this.selectedValue,
    this.selectedValues,
    required this.onSelected,
    this.onLongPress,
    this.selectedColor,
    this.unselectedColor,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0),
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 5),
          ],
          Wrap(
            spacing: 8.0, // Espacio horizontal entre chips
            runSpacing: 0.0, // Espacio vertical entre líneas de chips
            alignment: WrapAlignment.center,
            children: [
              ...values.map((value) {
                final isSelected = selectedValues != null
                    ? selectedValues!.contains(value)
                    : value == selectedValue;
                return GestureDetector(
                  onLongPress: onLongPress != null
                      ? () => onLongPress!(value)
                      : null,
                  child: ChoiceChip(
                    label: Text(value),
                    selected: isSelected,
                    onSelected: (selected) {
                      onSelected(value);
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
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                      ),
                    ),
                  ),
                );
              }),
              if (onAdd != null)
                Tooltip(
                  message: 'Agrega una etiqueta de categoria',
                  child: ActionChip(
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
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
