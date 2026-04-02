import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restaurantfinder/utils/app_colors.dart';
import 'package:restaurantfinder/utils/recommendation_voice_context.dart';

class RecommendationRequest {
  const RecommendationRequest({
    required this.cuisinePreferences,
    required this.dietaryRestrictions,
  });

  final List<String> cuisinePreferences;
  final List<String> dietaryRestrictions;
}

class RecommendationDialogController {
  final Set<String> selectedCuisines = {};
  final List<String> selectedDietaryRestrictions = [];
  
  VoidCallback? _onChanged;
  VoidCallback? _submitCallback;
  
  void addListener(VoidCallback callback) {
    _onChanged = callback;
  }
  
  void registerSubmitCallback(VoidCallback callback) {
    _submitCallback = callback;
  }
  
  void submit() {
    _submitCallback?.call();
  }
  
  bool addCuisine(String cuisine) {
    if (selectedCuisines.contains(cuisine)) return false;
    selectedCuisines.add(cuisine);
    _onChanged?.call();
    return true;
  }

  bool removeCuisine(String cuisine) {
    final removed = selectedCuisines.remove(cuisine);
    if (removed) _onChanged?.call();
    return removed;
  }

  bool addDietaryRestriction(String restriction) {
    if (selectedDietaryRestrictions.contains(restriction)) return false;
    selectedDietaryRestrictions.add(restriction);
    _onChanged?.call();
    return true;
  }

  bool removeDietaryRestriction(String restriction) {
    final removed = selectedDietaryRestrictions.remove(restriction);
    if (removed) _onChanged?.call();
    return removed;
  }
  
  void toggleCuisine(String cuisine) {
    if (selectedCuisines.contains(cuisine)) {
      removeCuisine(cuisine);
    } else {
      addCuisine(cuisine);
    }
  }
}

Future<RecommendationRequest?> showRecommendationDialog({
  required BuildContext context,
  RecommendationDialogController? controller,
}) {
  return showDialog<RecommendationRequest>(
    context: context,
    builder: (_) => _RecommendationDialog(controller: controller),
  );
}

class _RecommendationDialog extends StatefulWidget {
  const _RecommendationDialog({
    this.controller,
  });

  final RecommendationDialogController? controller;

  @override
  State<_RecommendationDialog> createState() => _RecommendationDialogState();
}

class _RecommendationDialogState extends State<_RecommendationDialog> {
  late final Future<List<String>> _cuisinesFuture;
  final TextEditingController _dietaryController = TextEditingController();
  late final Set<String> _selectedCuisines;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _cuisinesFuture = _loadCuisines();
    
    // Use provided controller or create local state
    if (widget.controller != null) {
      _selectedCuisines = widget.controller!.selectedCuisines;
      _dietaryController.text = widget.controller!.selectedDietaryRestrictions.join(', ');
      // Listen for changes from voice commands
      widget.controller!.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
      // Register submit callback
      widget.controller!.registerSubmitCallback(_submit);
    } else {
      _selectedCuisines = {};
    }
  }

  @override
  void dispose() {
    _dietaryController.dispose();
    super.dispose();
  }

  Future<List<String>> _loadCuisines() async {
    final content = await rootBundle.loadString('lib/utils/info/cuisines.txt');
    final cuisines = content
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    
    // Update voice context with available cuisines
    RecommendationVoiceContext.instance.update(
      selectedCuisines: _selectedCuisines,
      selectedDietaryRestrictions: _dietaryController.text
          .split(',')
          .map((v) => v.trim())
          .where((v) => v.isNotEmpty)
          .toList(),
      availableCuisines: cuisines,
    );
    
    return cuisines;
  }

  void _submit() {
    final dietaryRestrictions = _dietaryController.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    if (_selectedCuisines.isEmpty) {
      setState(() => _errorText = 'Select at least one cuisine preference.');
      return;
    }

    if (widget.controller != null) {
      widget.controller!.selectedCuisines.clear();
      widget.controller!.selectedCuisines.addAll(_selectedCuisines);
      widget.controller!.selectedDietaryRestrictions.clear();
      widget.controller!.selectedDietaryRestrictions.addAll(dietaryRestrictions);
    }

    Navigator.of(context).pop(
      RecommendationRequest(
        cuisinePreferences: _selectedCuisines.toList(),
        dietaryRestrictions: dietaryRestrictions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Give recommendation'),
      content: FutureBuilder<List<String>>(
        future: _cuisinesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              width: 320,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (snapshot.hasError) {
            return Text(
              'Could not load cuisine options: ${snapshot.error}',
              style: Theme.of(context).textTheme.bodyMedium,
            );
          }

          final cuisines = snapshot.data ?? const <String>[];
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose one or more cuisine preferences.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: cuisines.map((cuisine) {
                      final selected = _selectedCuisines.contains(cuisine);
                      return ChoiceChip(
                        label: Text(cuisine),
                        selected: selected,
                        selectedColor: AppColors.Ocean,
                        labelStyle: TextStyle(
                          color: selected ? AppColors.Alabaster : AppColors.Onyx,
                        ),
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selectedCuisines.add(cuisine);
                            } else {
                              _selectedCuisines.remove(cuisine);
                            }
                            _errorText = null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _dietaryController,
                    decoration: const InputDecoration(
                      labelText: 'Dietary restrictions',
                      hintText: 'Comma separated, for example: vegetarian, gluten free',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Submit recommendation'),
        ),
      ],
    );
  }
}
