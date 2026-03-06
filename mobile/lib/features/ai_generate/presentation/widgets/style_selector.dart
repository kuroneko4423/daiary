import 'package:flutter/material.dart';
import '../../domain/entities/generation_result.dart';

class StyleSelector extends StatelessWidget {
  final GenerationStyle selected;
  final ValueChanged<GenerationStyle> onSelected;

  const StyleSelector({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: GenerationStyle.values.map((style) {
        return ChoiceChip(
          label: Text(style.label),
          selected: selected == style,
          onSelected: (_) => onSelected(style),
        );
      }).toList(),
    );
  }
}
