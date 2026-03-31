import 'package:flutter/material.dart';
import 'package:restaurantfinder/utils/app_colors.dart';

Future<List<String>?> showAllergyDialog({
  required BuildContext context,
  required List<String> initialAllergies,
  required Map<String, String> allowedAllergyLookup,
}) async {
  return showDialog<List<String>>(
    context: context,
    builder: (ctx) => _AllergyDialog(
      initialAllergies: initialAllergies,
      allowedAllergyLookup: allowedAllergyLookup,
    ),
  );
}

class _AllergyDialog extends StatefulWidget {
  const _AllergyDialog({
    required this.initialAllergies,
    required this.allowedAllergyLookup,
  });

  final List<String> initialAllergies;
  final Map<String, String> allowedAllergyLookup;

  @override
  State<_AllergyDialog> createState() => _AllergyDialogState();
}

class _AllergyDialogState extends State<_AllergyDialog> {
  late TextEditingController input;
  late List<String> allergies;
  String? error;

  @override
  void initState() {
    super.initState();
    input = TextEditingController();
    allergies = List.from(widget.initialAllergies);
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  String? _validate(String value) {
    if (value.isEmpty) return null;
    
    final lookup = widget.allowedAllergyLookup[value.toLowerCase()];
    if (lookup == null) return '"$value" not recognized';
    
    if (allergies.any((a) => a.toLowerCase() == lookup.toLowerCase())) {
      return 'Already added';
    }
    return null;
  }

  void _add() {
    final value = input.text.trim();
    final err = _validate(value);
    
    setState(() => error = err);
    if (err != null) return;
    
    final canonical = widget.allowedAllergyLookup[value.toLowerCase()]!;
    allergies.add(canonical);
    input.clear();
  }

  void _save() {
    // try adding any pending input
    final pending = input.text.trim();
    if (pending.isNotEmpty && _validate(pending) == null) {
      final canonical = widget.allowedAllergyLookup[pending.toLowerCase()]!;
      if (!allergies.contains(canonical)) {
        allergies.add(canonical);
      }
    }
    Navigator.pop(context, allergies);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Allergies', semanticsLabel: 'Set Allergies Dialog'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add food allergies to filter restaurant options.'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _add(),
                    decoration: const InputDecoration(
                      hintText: 'e.g. peanuts',
                      labelText: 'Allergy Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _add,
                  tooltip: 'Add allergy',
                  icon: const Icon(Icons.add, color: AppColors.Alabaster),
                  style: IconButton.styleFrom(backgroundColor: AppColors.Ocean),
                ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                semanticsLabel: 'Error: $error',
              )
            ],
            const SizedBox(height: 12),
            if (allergies.isEmpty)
              const Text('None yet.', semanticsLabel: 'No allergies added yet.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allergies.map((a) => Semantics(
                  label: 'Allergy: $a. Double tap to remove.',
                  button: true,
                  child: InputChip(
                    label: Text(a),
                    deleteButtonTooltipMessage: 'Remove $a',
                    onDeleted: () => setState(() => allergies.remove(a)),
                  ),
                )).toList(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
