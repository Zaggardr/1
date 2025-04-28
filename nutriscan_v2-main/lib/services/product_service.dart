import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';

class ProductService {
  Future<Product?> fetchProduct(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          final productData = data['product'];
          return Product(
            productName: productData['product_name'],
            brands: productData['brands'],
            ingredientsText: productData['ingredients_text'],
            allergens: productData['allergens'],
            imageUrl: productData['image_url'],
            energy: double.tryParse(
                productData['nutriments']?['energy-kcal_100g']?.toString() ?? ''),
            fat: double.tryParse(
                productData['nutriments']?['fat_100g']?.toString() ?? ''),
            sugar: double.tryParse(
                productData['nutriments']?['sugars_100g']?.toString() ?? ''),
            salt: double.tryParse(
                productData['nutriments']?['salt_100g']?.toString() ?? ''),
            protein: double.tryParse(
                productData['nutriments']?['proteins_100g']?.toString() ?? ''),
            nutriScore: productData['nutriscore_grade'],
            novaGroup: productData['nova_group']?.toString(),
            ecoScore: productData['ecoscore_grade'],
          );
        } else {
          print('Product not found for barcode: $barcode');
          return null;
        }
      } else {
        print('Failed to fetch product: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }
}