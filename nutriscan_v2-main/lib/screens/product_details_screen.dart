import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../models/product.dart';

class ProductDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Product product = ModalRoute.of(context)!.settings.arguments as Product;

    print('Displaying product: ${product.productName}, Brands: ${product.brands}');

    return DefaultTabController(
      length: 4, // Added KPI tab
      child: Scaffold(
        appBar: AppBar(
          title: Text('Product Details'),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[700]!, Colors.green[300]!],
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
            indicatorColor: Colors.greenAccent,
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.green[100]!, Colors.white],
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
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        shadowColor: Colors.green.withOpacity(0.4),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.productName ?? 'Unknown Product',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _buildInfoTile('Brand', product.brands ?? 'N/A'),
              _buildInfoTile('Nutri-Score', product.nutriScore ?? 'N/A'),
              _buildInfoTile('NOVA Group', product.novaGroup ?? 'N/A'),
              _buildInfoTile('Eco-Score', product.ecoScore ?? 'N/A'),
              _buildInfoTile('Allergens', product.allergens ?? 'N/A'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: product.analyze().contains('unhealthy') ? Colors.red[100] : Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  product.analyze(),
                  style: TextStyle(
                    fontSize: 16,
                    color: product.analyze().contains('unhealthy') ? Colors.red[900] : Colors.green[900],
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
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nutrition (per 100g)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ingredients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(product.ingredientsText ?? 'N/A', style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),
              Text('Allergens', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(product.allergens ?? 'N/A', style: TextStyle(fontSize: 16)),
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
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        shadowColor: Colors.green.withOpacity(0.4),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Key Performance Indicators',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              _buildKpiIndicator(
                'Indice Énergétique',
                energyIndex / 100,
                'Measures energy density (lower is better)',
                Colors.blue,
              ),
              SizedBox(height: 16),
              _buildKpiIndicator(
                'Indice Nutritionnel',
                nutritionalIndex / 100,
                'Evaluates nutritional balance (sugar, fat, salt)',
                Colors.orange,
              ),
              SizedBox(height: 16),
              _buildKpiIndicator(
                'Indice de Conformité',
                complianceIndex / 100,
                'Assesses compliance (fewer additives/allergens)',
                Colors.purple,
              ),
              SizedBox(height: 24),
              Text(
                'Overall Product Quality',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              CircularPercentIndicator(
                radius: 60.0,
                lineWidth: 10.0,
                percent: qualityPercentage / 100,
                center: Text(
                  '${qualityPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                progressColor: Colors.green,
                backgroundColor: Colors.grey[300]!,
                circularStrokeCap: CircularStrokeCap.round,
              ),
              SizedBox(height: 8),
              Text(
                'Weighted average of KPIs',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            progressColor: color,
            backgroundColor: Colors.grey[300]!,
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
          Text('$title: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildNutritionTile(String title, String value, String unit) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$title: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('$value $unit'),
        ],
      ),
    );
  }
}