class RecommendationVoiceContext {
  RecommendationVoiceContext._();

  static final RecommendationVoiceContext instance = RecommendationVoiceContext._();

  Set<String> selectedCuisines = {};
  List<String> selectedDietaryRestrictions = [];
  List<String> availableCuisines = [];

  bool get isActive => selectedCuisines.isNotEmpty || selectedDietaryRestrictions.isNotEmpty;

  void update({
    required Set<String> selectedCuisines,
    required List<String> selectedDietaryRestrictions,
    required List<String> availableCuisines,
  }) {
    this.selectedCuisines = selectedCuisines;
    this.selectedDietaryRestrictions = selectedDietaryRestrictions;
    this.availableCuisines = availableCuisines;
  }

  void clear() {
    selectedCuisines = {};
    selectedDietaryRestrictions = [];
    availableCuisines = [];
  }
}
