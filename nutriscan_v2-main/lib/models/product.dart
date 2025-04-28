class Product {
  final String? productName;
  final String? brands;
  final String? ingredientsText;
  final String? allergens;
  final String? imageUrl;
  final double? energy;
  final double? fat;
  final double? sugar;
  final double? salt;
  final double? protein;
  final String? nutriScore;
  final String? novaGroup;
  final String? ecoScore;

  Product({
    this.productName,
    this.brands,
    this.ingredientsText,
    this.allergens,
    this.imageUrl,
    this.energy,
    this.fat,
    this.sugar,
    this.salt,
    this.protein,
    this.nutriScore,
    this.novaGroup,
    this.ecoScore,
  });

  factory Product.fromFirestore(Map<String, dynamic> data) {
    return Product(
      productName: data['productName'],
      brands: data['brands'],
      ingredientsText: data['ingredientsText'],
      allergens: data['allergens'],
      imageUrl: data['imageUrl'],
      energy: (data['energy'] as num?)?.toDouble(),
      fat: (data['fat'] as num?)?.toDouble(),
      sugar: (data['sugar'] as num?)?.toDouble(),
      salt: (data['salt'] as num?)?.toDouble(),
      protein: (data['protein'] as num?)?.toDouble(),
      nutriScore: data['nutriScore'],
      novaGroup: data['novaGroup'],
      ecoScore: data['ecoScore'],
    );
  }

  double getEnergy() => energy ?? 0.0;
  double getFat() => fat ?? 0.0;
  double getSugar() => sugar ?? 0.0;
  double getSalt() => salt ?? 0.0;
  double getProtein() => protein ?? 0.0;

  double getEnergyIndex() {
    final energyVal = getEnergy();
    if (energyVal <= 0) return 100.0;
    return (1 - (energyVal / 8400)) * 100;
  }

  double getNutritionalIndex() {
    final sugarVal = getSugar();
    final fatVal = getFat();
    final saltVal = getSalt();
    double sugarScore = sugarVal > 10 ? (1 - (sugarVal / 100)) : 1.0;
    double fatScore = fatVal > 20 ? (1 - (fatVal / 100)) : 1.0;
    double saltScore = saltVal > 2 ? (1 - (saltVal / 10)) : 1.0;
    return ((sugarScore + fatScore + saltScore) / 3) * 100;
  }

  double getComplianceIndex() {
    double complianceScore = 100.0;
    if (allergens != null && allergens!.isNotEmpty) {
      complianceScore -= 20;
    }
    if (novaGroup != null && novaGroup == '4') {
      complianceScore -= 20;
    }
    return complianceScore.clamp(0, 100);
  }

  double getQualityPercentage() {
    return (getEnergyIndex() * 0.3 +
            getNutritionalIndex() * 0.4 +
            getComplianceIndex() * 0.3)
        .clamp(0, 100);
  }

  String analyze() {
    final quality = getQualityPercentage();
    if (quality >= 70) {
      return "This product is generally healthy.";
    } else if (quality >= 50) {
      return "This product is moderately healthy.";
    } else {
      return "This product may be unhealthy.";
    }
  }

  // New method to identify positive aspects
  List<String> getPositiveAspects() {
    List<String> positives = [];
    if (getSugar() < 5) {
      positives.add("Low sugar content (${getSugar()}g per 100g)");
    }
    if (getFat() < 5) {
      positives.add("Low fat content (${getFat()}g per 100g)");
    }
    if (getSalt() < 0.5) {
      positives.add("Low salt content (${getSalt()}g per 100g)");
    }
    if (getProtein() > 10) {
      positives.add("High protein content (${getProtein()}g per 100g)");
    }
    if (nutriScore != null && ['a', 'b'].contains(nutriScore!.toLowerCase())) {
      positives.add("Good Nutri-Score (${nutriScore!.toUpperCase()})");
    }
    if (novaGroup != null && ['1', '2'].contains(novaGroup)) {
      positives.add("Low processing level (NOVA Group $novaGroup)");
    }
    if (ecoScore != null && ['a', 'b'].contains(ecoScore!.toLowerCase())) {
      positives.add("Eco-friendly (Eco-Score ${ecoScore!.toUpperCase()})");
    }
    if (allergens == null || allergens!.isEmpty) {
      positives.add("No allergens detected");
    }
    return positives.isNotEmpty ? positives : ["No notable positive aspects"];
  }

  // New method to identify negative aspects
  List<String> getNegativeAspects() {
    List<String> negatives = [];
    if (getSugar() > 10) {
      negatives.add("High sugar content (${getSugar()}g per 100g)");
    }
    if (getFat() > 20) {
      negatives.add("High fat content (${getFat()}g per 100g)");
    }
    if (getSalt() > 2) {
      negatives.add("High salt content (${getSalt()}g per 100g)");
    }
    if (getEnergy() > 500) {
      negatives.add("High energy content (${getEnergy()} kcal per 100g)");
    }
    if (nutriScore != null && ['d', 'e'].contains(nutriScore!.toLowerCase())) {
      negatives.add("Poor Nutri-Score (${nutriScore!.toUpperCase()})");
    }
    if (novaGroup != null && novaGroup == '4') {
      negatives.add("Highly processed (NOVA Group 4)");
    }
    if (ecoScore != null && ['d', 'e'].contains(ecoScore!.toLowerCase())) {
      negatives.add("Poor environmental impact (Eco-Score ${ecoScore!.toUpperCase()})");
    }
    if (allergens != null && allergens!.isNotEmpty) {
      negatives.add("Contains allergens: $allergens");
    }
    return negatives.isNotEmpty ? negatives : ["No notable negative aspects"];
  }

  // New method for recommendations
  List<String> getRecommendations() {
    List<String> recommendations = [];
    if (getSugar() > 10 || getFat() > 20 || getSalt() > 2) {
      recommendations.add("Consume in moderation due to high sugar, fat, or salt content.");
    }
    if (allergens != null && allergens!.isNotEmpty) {
      recommendations.add("Avoid if you are allergic to any of the listed allergens ($allergens).");
    }
    if (novaGroup != null && novaGroup == '4') {
      recommendations.add("Consider choosing less processed alternatives (lower NOVA Group).");
    }
    if (ecoScore != null && ['d', 'e'].contains(ecoScore!.toLowerCase())) {
      recommendations.add("Look for more eco-friendly alternatives with a better Eco-Score.");
    }
    if (getProtein() > 10) {
      recommendations.add("Good choice for a high-protein diet.");
    }
    return recommendations.isNotEmpty ? recommendations : ["No specific recommendations"];
  }

  // New method to extract additives from ingredientsText
  List<String> getAdditives() {
    if (ingredientsText == null || ingredientsText!.isEmpty) {
      return [];
    }
    // Common additive patterns (e.g., E numbers like E100, E322)
    final RegExp additivePattern = RegExp(r'\bE\d{3,4}(?:\w)?\b', caseSensitive: false);
    final matches = additivePattern.allMatches(ingredientsText!);
    List<String> additives = matches.map((match) => match.group(0)!).toList();

    // Add other common additives not covered by E numbers (you can expand this list)
    final commonAdditives = [
      'monosodium glutamate',
      'aspartame',
      'sodium benzoate',
      'potassium sorbate',
      'calcium propionate',
      'sodium nitrate',
      'sodium nitrite',
    ];
    for (var additive in commonAdditives) {
      if (ingredientsText!.toLowerCase().contains(additive)) {
        additives.add(additive);
      }
    }

    return additives;
  }
}