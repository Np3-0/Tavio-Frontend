import 'package:flutter/material.dart';
import 'package:restaurantfinder/utils/app_colors.dart';

Future<List<String>?> showAllergyDialog({
  required BuildContext context,
  required List<String> initialAllergies,
}) async {
  final TextEditingController allergyController = TextEditingController();
  final List<String> draftAllergies = List<String>.from(initialAllergies);

  final List<String>? updatedAllergies = await showDialog<List<String>>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          void addAllergy() {
            final String value = allergyController.text.trim();
            if (value.isEmpty) {
              return;
            }

            final bool exists = draftAllergies.any(
              (String allergy) => allergy.toLowerCase() == value.toLowerCase(),
            );

            if (!exists) {
              setModalState(() {
                draftAllergies.add(value);
              });
            }

            allergyController.clear();
          }

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
                          controller: allergyController,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => addAllergy(),
                          decoration: const InputDecoration(
                            hintText: 'e.g. peanuts',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: addAllergy,
                        icon: const Icon(Icons.add_circle, color: AppColors.Ocean),
                        tooltip: 'Add allergy',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (draftAllergies.isEmpty)
                    const Text('No allergies added yet.')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: draftAllergies.map((String allergy) {
                        return InputChip(
                          label: Text(allergy),
                          onDeleted: () {
                            setModalState(() {
                              draftAllergies.remove(allergy);
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
                onPressed: () => Navigator.of(context).pop(draftAllergies),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );

  allergyController.dispose();
  return updatedAllergies;
}
