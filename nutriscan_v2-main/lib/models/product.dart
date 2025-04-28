class Product {
  final String? productName;
  final String? brands;
  final String? ingredientsText;
  final String? allergens;
  final String? nutriScore;
  final String? novaGroup;
  final String? ecoScore;
  final String? imageUrl;
  final double? energy;
  final double? fat;
  final double? sugar;
  final double? salt;
  final double? protein;
  final double? qualityPercentage; // New field for overall quality score
  final double? energyIndex; // New field for energy KPI
  final double? nutritionalIndex; // New field for nutritional KPI
  final double? complianceIndex; // New field for compliance KPI

  Product({
    this.productName,
    this.brands,
    this.ingredientsText,
    this.allergens,
    this.nutriScore,
    this.novaGroup,
    this.ecoScore,
    this.imageUrl,
    this.energy,
    this.fat,
    this.sugar,
    this.salt,
    this.protein,
    this.qualityPercentage,
    this.energyIndex,
    this.nutritionalIndex,
    this.complianceIndex,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final product = Product(
      productName: json['product_name'] as String?,
      brands: json['brands'] as String?,
      ingredientsText: json['ingredients_text'] as String?,
      allergens: json['allergens'] as String?,
      nutriScore: json['nutriscore_grade'] as String?,
      novaGroup: json['nova_group']?.toString(),
      ecoScore: json['ecoscore_grade'] as String?,
      imageUrl: json['image_url'] as String? ?? json['image_front_url'] as String?,
      energy: double.tryParse(json['nutriments']?['energy-kcal']?.toString() ?? '0'),
      fat: double.tryParse(json['nutriments']?['fat']?.toString() ?? '0'),
      sugar: double.tryParse(json['nutriments']?['sugars']?.toString() ?? '0'),
      salt: double.tryParse(json['nutriments']?['salt']?.toString() ?? '0'),
      protein: double.tryParse(json['nutriments']?['proteins']?.toString() ?? '0'),
    );

    // Calculate KPIs and quality percentage after creating the initial product
    return Product(
      productName: product.productName,
      brands: product.brands,
      ingredientsText: product.ingredientsText,
      allergens: product.allergens,
      nutriScore: product.nutriScore,
      novaGroup: product.novaGroup,
      ecoScore: product.ecoScore,
      imageUrl: product.imageUrl,
      energy: product.energy,
      fat: product.fat,
      sugar: product.sugar,
      salt: product.salt,
      protein: product.protein,
      qualityPercentage: product.getQualityPercentage(),
      energyIndex: product.getEnergyIndex(),
      nutritionalIndex: product.getNutritionalIndex(),
      complianceIndex: product.getComplianceIndex(),
    );
  }

  factory Product.fromFirestore(Map<String, dynamic> data) {
    return Product(
      productName: data['productName'] as String?,
      brands: data['brands'] as String?,
      ingredientsText: data['ingredientsText'] as String?,
      allergens: data['allergens'] as String?,
      imageUrl: data['imageUrl'] as String?,
      qualityPercentage: data['qualityPercentage'] as double?,
      energyIndex: data['energyIndex'] as double?,
      nutritionalIndex: data['nutritionalIndex'] as double?,
      complianceIndex: data['complianceIndex'] as double?,
    );
  }

  String getEnergy() => energy?.toStringAsFixed(1) ?? 'N/A';
  double getFat() => fat ?? 0.0;
  double getSugar() => sugar ?? 0.0;
  double getSalt() => salt ?? 0.0;
  double getProtein() => protein ?? 0.0;

  double getEnergyIndex() => energyIndex ?? (energy != null ? (energy! > 500 ? 50 : 100 - (energy! / 500) * 50) : 50);
  double getNutritionalIndex() {
    if (nutritionalIndex != null) return nutritionalIndex!;
    double score = 100;
    if (sugar != null && sugar! > 10) score -= 20;
    if (fat != null && fat! > 20) score -= 20;
    if (salt != null && salt! > 1) score -= 20;
    return score.clamp(0, 100);
  }

  double getComplianceIndex() {
    if (complianceIndex != null) return complianceIndex!;
    double score = 100;
    if (allergens != null && allergens!.isNotEmpty) score -= 30;
    return score.clamp(0, 100);
  }

  double getQualityPercentage() {
    if (qualityPercentage != null) return qualityPercentage!;
    return (getEnergyIndex() * 0.3 + getNutritionalIndex() * 0.4 + getComplianceIndex() * 0.3);
  }

  String analyze() {
    if (getQualityPercentage() < 50) return 'This product is unhealthy';
    return 'This product is healthy';
  }
}