import 'package:flutter/material.dart';
import 'package:restaurantfinder/utils/app_colors.dart';

class AllergyDialogController extends ChangeNotifier {
  AllergyDialogController({
    required Map<String, String> allowedAllergyLookup,
    List<String> initialAllergies = const [],
  })  : _allowedAllergyLookup = allowedAllergyLookup,
        _allergies = List<String>.from(initialAllergies);

  final Map<String, String> _allowedAllergyLookup;
  final List<String> _allergies;

  List<String> get allergies => List.unmodifiable(_allergies);

  String? validate(String value) {
    if (value.isEmpty) return null;

    final lookup = _allowedAllergyLookup[value.toLowerCase()];
    if (lookup == null) return '"$value" not recognized';

    if (_allergies.any((a) => a.toLowerCase() == lookup.toLowerCase())) {
      return 'Already added';
    }
    return null;
  }

  bool addAllergy(String value) {
    final normalized = value.trim();
    final err = validate(normalized);
    if (err != null) return false;

    final canonical = _allowedAllergyLookup[normalized.toLowerCase()]!;
    _allergies.add(canonical);
    notifyListeners();
    return true;
  }

  bool removeAllergy(String value) {
    final normalized = value.trim().toLowerCase();
    final index = _allergies.indexWhere((a) => a.toLowerCase() == normalized);
    if (index == -1) return false;

    _allergies.removeAt(index);
    notifyListeners();
    return true;
  }

  void replaceAll(List<String> allergies) {
    _allergies
      ..clear()
      ..addAll(allergies);
    notifyListeners();
  }
}

Future<List<String>?> showAllergyDialog({
  required BuildContext context,
  required List<String> initialAllergies,
  required Map<String, String> allowedAllergyLookup,
  AllergyDialogController? controller,
}) async {
  final dialogController = controller ?? AllergyDialogController(
    allowedAllergyLookup: allowedAllergyLookup,
    initialAllergies: initialAllergies,
  );

  try {
    return await showDialog<List<String>>(
      context: context,
      builder: (ctx) => _AllergyDialog(controller: dialogController),
    );
  } finally {
    if (controller == null) {
      dialogController.dispose();
    }
  }
}

class _AllergyDialog extends StatefulWidget {
  const _AllergyDialog({required this.controller});

  final AllergyDialogController controller;

  @override
  State<_AllergyDialog> createState() => _AllergyDialogState();
}

class _AllergyDialogState extends State<_AllergyDialog> {
  late TextEditingController input;
  String? error;

  @override
  void initState() {
    super.initState();
    input = TextEditingController();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    input.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {
      error = null;
    });
  }

  String? _validate(String value) {
    return widget.controller.validate(value);
  }

  void _add() {
    final value = input.text.trim();
    final err = _validate(value);
    
    setState(() => error = err);
    if (err != null) return;
    
    if (widget.controller.addAllergy(value)) {
      input.clear();
    }
  }

  void _remove(String value) {
    widget.controller.removeAllergy(value);
  }

  void _save() {
    // Try adding any pending input.
    final pending = input.text.trim();
    if (pending.isNotEmpty && _validate(pending) == null) {
      widget.controller.addAllergy(pending);
    }
    Navigator.pop(context, widget.controller.allergies);
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
            if (widget.controller.allergies.isEmpty)
              const Text('None yet.', semanticsLabel: 'No allergies added yet.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.controller.allergies.map((a) => Semantics(
                  label: 'Allergy: $a. Double tap to remove.',
                  button: true,
                  child: InputChip(
                    label: Text(a),
                    deleteButtonTooltipMessage: 'Remove $a',
                    onDeleted: () => _remove(a),
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
