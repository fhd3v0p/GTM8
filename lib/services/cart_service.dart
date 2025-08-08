import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_config.dart';

class CartService {
  // Используем Supabase API
  static String get baseUrl => ApiConfig.apiBaseUrl;
  static Map<String, String> get headers => ApiConfig.headers;

  // === CART OPERATIONS ===
  static Future<List<Map<String, dynamic>>> getCart(int telegramId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cart?telegram_id=eq.$telegramId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to load cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching cart: $e');
    }
  }

  static Future<Map<String, dynamic>> addToCart(Map<String, dynamic> cartItem) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart'),
        headers: headers,
        body: json.encode(cartItem),
      );

      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to add to cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding to cart: $e');
    }
  }

  static Future<bool> removeFromCart(int itemId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cart?id=eq.$itemId'),
        headers: headers,
      );

      return response.statusCode == 204;
    } catch (e) {
      throw Exception('Error removing from cart: $e');
    }
  }

  static Future<bool> clearCart(int telegramId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cart?telegram_id=eq.$telegramId'),
        headers: headers,
      );

      return response.statusCode == 204;
    } catch (e) {
      throw Exception('Error clearing cart: $e');
    }
  }
} 