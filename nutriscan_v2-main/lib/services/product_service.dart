import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';

class ProductService {
  static const String baseUrl = 'https://world.openfoodfacts.org'; // Staging for testing

  Future<Product?> fetchProduct(String barcode) async {
    final url = Uri.parse('$baseUrl/api/v0/product/$barcode.json');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 1) {
        return Product.fromJson(data['product']);
      }
    }
    return null;
  }
}