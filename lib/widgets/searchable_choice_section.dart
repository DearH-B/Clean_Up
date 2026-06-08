import 'package:flutter/material.dart';

class SearchableChoiceSection extends StatefulWidget {
  const SearchableChoiceSection({
    required this.title,
    required this.searchLabel,
    required this.options,
    required this.onSelected,
    super.key,
  });

  final String title;
  final String searchLabel;
  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  State<SearchableChoiceSection> createState() =>
      _SearchableChoiceSectionState();
}

class _SearchableChoiceSectionState extends State<SearchableChoiceSection> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filteredOptions = widget.options.where((option) {
      return option.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        TextField(
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: widget.searchLabel,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _query = value.trim();
            });
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in filteredOptions)
              ActionChip(
                label: Text(option),
                onPressed: () => widget.onSelected(option),
              ),
            ActionChip(
              label: const Text('그 외 직접 입력'),
              avatar: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () => widget.onSelected(''),
            ),
          ],
        ),
      ],
    );
  }
}
