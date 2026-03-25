import 'package:flutter/material.dart';
import 'package:restaurantfinder/utils/app_colors.dart';

Future<List<String>?> showAllergyDialog({
  required BuildContext context,
  required List<String> initialAllergies,
  required Map<String, String> allowedAllergyLookup,
}) async {
  return showDialog<List<String>>(
    context: context,
    builder: (BuildContext dialogContext) => _AllergyDialogContent(
      initialAllergies: initialAllergies,
      allowedAllergyLookup: allowedAllergyLookup,
    ),
  );
}

class _AllergyDialogContent extends StatefulWidget {
  const _AllergyDialogContent({
    required this.initialAllergies,
    required this.allowedAllergyLookup,
  });

  final List<String> initialAllergies;
  final Map<String, String> allowedAllergyLookup;

  @override
  State<_AllergyDialogContent> createState() => _AllergyDialogContentState();
}

class _AllergyDialogContentState extends State<_AllergyDialogContent> {
  late final TextEditingController _allergyController;
  late final List<String> _draftAllergies;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _allergyController = TextEditingController();
    _draftAllergies = List<String>.from(widget.initialAllergies);
  }

  @override
  void dispose() {
    _allergyController.dispose();
    super.dispose();
  }

  void _addAllergy() {
    final String value = _allergyController.text.trim();
    if (value.isEmpty) {
      return;
    }

    final String? canonicalAllergy =
        widget.allowedAllergyLookup[value.toLowerCase()];

    if (canonicalAllergy == null) {
      setState(() {
        _validationMessage = '"$value" is not in the supported allergy list.';
      });
      return;
    }

    final bool exists = _draftAllergies.any(
      (String allergy) => allergy.toLowerCase() == canonicalAllergy.toLowerCase(),
    );

    setState(() {
      if (exists) {
        _validationMessage = '"$canonicalAllergy" is already added.';
      } else {
        _draftAllergies.add(canonicalAllergy);
        _validationMessage = null;
      }
    });

    _allergyController.clear();
  }

  void _saveAllergies() {
    final String pendingValue = _allergyController.text.trim();
    if (pendingValue.isNotEmpty) {
      final String? canonicalAllergy =
          widget.allowedAllergyLookup[pendingValue.toLowerCase()];

      if (canonicalAllergy == null) {
        setState(() {
          _validationMessage =
              '"$pendingValue" is not in the supported allergy list.';
        });
        return;
      }

      final bool exists = _draftAllergies.any(
        (String allergy) =>
            allergy.toLowerCase() == canonicalAllergy.toLowerCase(),
      );

      if (!exists) {
        _draftAllergies.add(canonicalAllergy);
      }
    }

    Navigator.of(context).pop(_draftAllergies);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Allergies'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Add food allergies to filter restaurant options.'),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _allergyController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addAllergy(),
                    decoration: const InputDecoration(
                      hintText: 'e.g. peanuts',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addAllergy,
                  icon: const Icon(Icons.add_circle, color: AppColors.Ocean),
                  tooltip: 'Add allergy',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_validationMessage != null) ...<Widget>[
              Text(
                _validationMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
              const SizedBox(height: 8),
            ],
            if (_draftAllergies.isEmpty)
              const Text('No allergies added yet.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _draftAllergies.map((String allergy) {
                  return InputChip(
                    label: Text(allergy),
                    onDeleted: () {
                      setState(() {
                        _draftAllergies.remove(allergy);
                      });
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveAllergies,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
