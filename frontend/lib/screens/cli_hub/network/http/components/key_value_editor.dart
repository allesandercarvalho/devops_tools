import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KeyValuePair {
  String key;
  String value;
  bool enabled;

  KeyValuePair({this.key = '', this.value = '', this.enabled = true});
}

class KeyValueEditor extends StatefulWidget {
  final List<KeyValuePair> pairs;
  final Function(List<KeyValuePair>) onChanged;
  final String keyPlaceholder;
  final String valuePlaceholder;

  const KeyValueEditor({
    super.key,
    required this.pairs,
    required this.onChanged,
    this.keyPlaceholder = 'Key',
    this.valuePlaceholder = 'Value',
  });

  @override
  State<KeyValueEditor> createState() => _KeyValueEditorState();
}

class _KeyValueEditorState extends State<KeyValueEditor> {
  @override
  void initState() {
    super.initState();
    // Ensure there's always an empty row at the end
    _ensureEmptyRow();
  }

  void _ensureEmptyRow() {
    if (widget.pairs.isEmpty || widget.pairs.last.key.isNotEmpty || widget.pairs.last.value.isNotEmpty) {
      widget.pairs.add(KeyValuePair());
    }
  }

  void _onPairChanged(int index) {
    setState(() {
      _ensureEmptyRow();
      widget.onChanged(widget.pairs.where((p) => p.key.isNotEmpty).toList());
    });
  }

  void _removePair(int index) {
    setState(() {
      widget.pairs.removeAt(index);
      _ensureEmptyRow();
      widget.onChanged(widget.pairs.where((p) => p.key.isNotEmpty).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      shrinkWrap: true,
      itemCount: widget.pairs.length,
      itemBuilder: (context, index) {
        final pair = widget.pairs[index];
        final isLast = index == widget.pairs.length - 1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: pair.enabled,
                onChanged: (value) {
                  setState(() {
                    pair.enabled = value ?? true;
                    widget.onChanged(widget.pairs.where((p) => p.key.isNotEmpty).toList());
                  });
                },
              ),
              
              // Key input
              Expanded(
                flex: 2,
                child: TextField(
                  controller: TextEditingController(text: pair.key)
                    ..selection = TextSelection.collapsed(offset: pair.key.length),
                  decoration: InputDecoration(
                    hintText: widget.keyPlaceholder,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  ),
                  style: GoogleFonts.jetBrainsMono(fontSize: 13),
                  onChanged: (value) {
                    pair.key = value;
                    _onPairChanged(index);
                  },
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Value input
              Expanded(
                flex: 3,
                child: TextField(
                  controller: TextEditingController(text: pair.value)
                    ..selection = TextSelection.collapsed(offset: pair.value.length),
                  decoration: InputDecoration(
                    hintText: widget.valuePlaceholder,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  ),
                  style: GoogleFonts.jetBrainsMono(fontSize: 13),
                  onChanged: (value) {
                    pair.value = value;
                    _onPairChanged(index);
                  },
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Delete button
              if (!isLast)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _removePair(index),
                  tooltip: 'Remove',
                  color: colorScheme.error,
                ),
              if (isLast)
                const SizedBox(width: 40),
            ],
          ),
        );
      },
    );
  }
}
