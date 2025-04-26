class Product {
  final String? productName;
  final String? brands;
  final String? ingredientsText;
  final Map<String, dynamic>? nutriments;
  final String? nutriScore;
  final String? novaGroup;
  final String? ecoScore;
  final String? allergens;

  Product({
    this.productName,
    this.brands,
    this.ingredientsText,
    this.nutriments,
    this.nutriScore,
    this.novaGroup,
    this.ecoScore,
    this.allergens,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productName: json['product_name'] as String?,
      brands: json['brands'] as String?,
      ingredientsText: json['ingredients_text'] as String?,
      nutriments: json['nutriments'] as Map<String, dynamic>?,
      nutriScore: json['nutriscore_grade']?.toString().toUpperCase(),
      novaGroup: json['nova_group']?.toString(),
      ecoScore: json['ecoscore_grade']?.toString().toUpperCase(),
      allergens: json['allergens'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'brands': brands,
      'ingredients_text': ingredientsText,
      'nutriments': nutriments,
      'nutriscore_grade': nutriScore,
      'nova_group': novaGroup,
      'ecoscore_grade': ecoScore,
      'allergens': allergens,
    };
  }

  bool get hasData => productName != null || brands != null || ingredientsText != null || nutriments != null;

  double getSugar() => double.tryParse(nutriments?['sugars_100g']?.toString() ?? '0') ?? 0;
  double getFat() => double.tryParse(nutriments?['fat_100g']?.toString() ?? '0') ?? 0;
  double getSalt() => double.tryParse(nutriments?['salt_100g']?.toString() ?? '0') ?? 0;
  double getProtein() => double.tryParse(nutriments?['proteins_100g']?.toString() ?? '0') ?? 0;
  String getEnergy() => nutriments?['energy-kcal_100g']?.toString() ?? 'N/A';

  // Indice Énergétique: Lower energy density is better (0–800 kcal/100g range)
  double getEnergyIndex() {
    final energy = double.tryParse(getEnergy()) ?? 0;
    const maxEnergy = 800.0; // Typical max for food products
    if (energy <= 0) return 100.0; // No energy is ideal
    return ((maxEnergy - energy) / maxEnergy * 100).clamp(0, 100);
  }

  // Indice Nutritionnel: Lower sugar, fat, salt is better (WHO guidelines)
  double getNutritionalIndex() {
    final sugar = getSugar();
    final fat = getFat();
    final salt = getSalt();
    const maxSugar = 22.5; // Approx 10% of 2000 kcal diet
    const maxFat = 17.5; // Approx 30% of 2000 kcal diet
    const maxSalt = 5.0; // WHO daily limit
    double sugarScore = sugar <= 0 ? 100 : ((maxSugar - sugar) / maxSugar * 100).clamp(0, 100);
    double fatScore = fat <= 0 ? 100 : ((maxFat - fat) / maxFat * 100).clamp(0, 100);
    double saltScore = salt <= 0 ? 100 : ((maxSalt - salt) / maxSalt * 100).clamp(0, 100);
    return (sugarScore * 0.4 + fatScore * 0.3 + saltScore * 0.3); // Weighted average
  }

  // Indice de Conformité: Fewer additives/allergens is better
  double getComplianceIndex() {
    int additiveCount = 0;
    final ingredients = ingredientsText?.toLowerCase() ?? '';
    // Common additives (simplified list)
    const additives = ['e1', 'e2', 'e3', 'e4', 'e5', 'monosodium glutamate', 'aspartame'];
    for (var additive in additives) {
      if (ingredients.contains(additive)) additiveCount++;
    }
    final allergenCount = allergens?.split(',').length ?? 0;
    const maxIssues = 10.0; // Arbitrary max for additives + allergens
    final issueCount = additiveCount + allergenCount;
    return ((maxIssues - issueCount) / maxIssues * 100).clamp(0, 100);
  }

  // Product Quality: Weighted average of KPIs
  double getQualityPercentage() {
    return (getNutritionalIndex() * 0.4 + getEnergyIndex() * 0.3 + getComplianceIndex() * 0.3);
  }

  String analyze() {
    final sugar = getSugar();
    final fat = getFat();
    final salt = getSalt();
    if (sugar > 22.5 || fat > 17.5 || salt > 1.5) {
      return 'Potentially unhealthy: High in ${sugar > 22.5 ? 'sugar' : ''} ${fat > 17.5 ? 'fat' : ''} ${salt > 1.5 ? 'salt' : ''}';
    }
    return 'Seems relatively healthy';
  }
}