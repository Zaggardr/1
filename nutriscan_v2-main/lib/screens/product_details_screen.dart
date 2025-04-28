import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../models/product.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Product product = ModalRoute.of(context)!.settings.arguments as Product;

    print('Displaying product: ${product.productName}, Brands: ${product.brands}');

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Product Details',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF81C784)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Nutrition'),
              Tab(text: 'Ingredients'),
              Tab(text: 'KPIs'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Color(0xFF4CAF50),
            labelStyle: GoogleFonts.poppins(fontSize: 14),
            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE8F5E9), Color(0xFFFFFFFF)],
            ),
          ),
          child: TabBarView(
            children: [
              _buildOverviewTab(product),
              _buildNutritionTab(product),
              _buildIngredientsTab(product),
              _buildKpiTab(product),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(Product product) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: Color(0xFF4CAF50).withOpacity(0.2),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product.imageUrl!,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.broken_image,
                            size: 150,
                            color: Color(0xFF757575),
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.image_not_supported,
                        size: 150,
                        color: Color(0xFF757575),
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                product.productName ?? 'Unknown Product',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 8),
              _buildInfoTile('Brand', product.brands ?? 'N/A'),
              _buildInfoTile('Nutri-Score', product.nutriScore?.toUpperCase() ?? 'N/A'),
              _buildInfoTile('NOVA Group', product.novaGroup ?? 'N/A'),
              _buildInfoTile('Eco-Score', product.ecoScore?.toUpperCase() ?? 'N/A'),
              _buildInfoTile('Allergens', product.allergens ?? 'N/A'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: product.analyze().contains('unhealthy')
                      ? Color(0xFFF44336).withOpacity(0.1)
                      : Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  product.analyze(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: product.analyze().contains('unhealthy')
                        ? Color(0xFFF44336)
                        : Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionTab(Product product) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: Color(0xFF4CAF50).withOpacity(0.2),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nutrition (per 100g)',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 8),
              _buildNutritionTile('Energy', product.getEnergy(), 'kcal'),
              _buildNutritionTile('Fat', product.getFat().toString(), 'g'),
              _buildNutritionTile('Sugar', product.getSugar().toString(), 'g'),
              _buildNutritionTile('Salt', product.getSalt().toString(), 'g'),
              _buildNutritionTile('Protein', product.getProtein().toString(), 'g'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientsTab(Product product) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: Color(0xFF4CAF50).withOpacity(0.2),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ingredients',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 8),
              Text(
                product.ingredientsText ?? 'N/A',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Allergens',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 8),
              Text(
                product.allergens ?? 'N/A',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Color(0xFF212121),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiTab(Product product) {
    final energyIndex = product.getEnergyIndex();
    final nutritionalIndex = product.getNutritionalIndex();
    final complianceIndex = product.getComplianceIndex();
    final qualityPercentage = product.getQualityPercentage();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: Color(0xFF4CAF50).withOpacity(0.2),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Key Performance Indicators',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 16),
              _buildKpiIndicator(
                'Energy Index',
                energyIndex / 100,
                'Measures energy density (lower is better)',
                Color(0xFF2196F3),
              ),
              SizedBox(height: 16),
              _buildKpiIndicator(
                'Nutritional Index',
                nutritionalIndex / 100,
                'Evaluates nutritional balance (sugar, fat, salt)',
                Color(0xFFFF9800),
              ),
              SizedBox(height: 16),
              _buildKpiIndicator(
                'Compliance Index',
                complianceIndex / 100,
                'Assesses compliance (fewer additives/allergens)',
                Color(0xFF9C27B0),
              ),
              SizedBox(height: 24),
              Text(
                'Overall Product Quality',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 8),
              CircularPercentIndicator(
                radius: 60.0,
                lineWidth: 10.0,
                percent: qualityPercentage / 100,
                center: Text(
                  '${qualityPercentage.toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
                progressColor: Color(0xFF4CAF50),
                backgroundColor: Colors.grey[200]!,
                circularStrokeCap: CircularStrokeCap.round,
              ),
              SizedBox(height: 8),
              Text(
                'Weighted average of KPIs',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiIndicator(String title, double percent, String description, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: CircularPercentIndicator(
            radius: 40.0,
            lineWidth: 8.0,
            percent: percent,
            center: Text(
              '${(percent * 100).toStringAsFixed(1)}%',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            progressColor: color,
            backgroundColor: Colors.grey[200]!,
            circularStrokeCap: CircularStrokeCap.round,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Color(0xFF212121),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionTile(String title, String value, String unit) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          Text(
            '$value $unit',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Color(0xFF212121),
            ),
          ),
        ],
      ),
    );
  }
}