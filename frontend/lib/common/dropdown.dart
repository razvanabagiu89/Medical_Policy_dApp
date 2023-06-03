import 'package:flutter/material.dart';
import 'pallete.dart';

class InputDropdown extends StatefulWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const InputDropdown({
    Key? key,
    required this.value,
    required this.items,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<InputDropdown> createState() => _InputDropdownState();
}

class _InputDropdownState extends State<InputDropdown> {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 400,
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(27),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Pallete.borderColor,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Pallete.gradient2,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        value: widget.value,
        items: widget.items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: widget.onChanged,
      ),
    );
  }
}
