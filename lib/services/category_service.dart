import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CategoryService {
  static const String createApiUrl =
      'http://192.168.80.1:3001/api/categories'; // API for saving categories
  static const String fetchApiUrl =
      'http://192.168.80.1:3001/api/categorie'; // API for fetching categories

// Fetch categories from API
  static Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse(fetchApiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> categoryData = jsonDecode(response.body);
        return categoryData.map((category) {
          // ตรวจสอบค่าของ color ก่อนทำการแปลง
          String colorString = category['color'] ?? ''; // ตรวจสอบค่าว่าง
          int colorValue;

          // ตรวจสอบว่าค่าสีไม่ใช่ค่าว่างและสมบูรณ์
          if (colorString.isNotEmpty && colorString.length == 6) {
            colorString = 'ff' + colorString; // เพิ่มค่า alpha 255
          }

          try {
            colorValue = int.parse(colorString, radix: 16) | 0xFF000000;
          } catch (e) {
            print('Invalid color value: $colorString');
            colorValue = Colors.grey.value; // กำหนดสีเริ่มต้นถ้ามีข้อผิดพลาด
          }

          // ตรวจสอบค่าของ icon
          String iconString = category['icon'] ?? ''; // ตรวจสอบค่าว่าง
          int iconValue;

          try {
            iconValue = int.parse(iconString);
          } catch (e) {
            print('Invalid icon value: $iconString');
            iconValue =
                Icons.error.codePoint; // กำหนดไอคอนเริ่มต้นถ้ามีข้อผิดพลาด
          }

          return {
            'id': category['id'],
            'name': category['name'],
            'color': Color(colorValue),
            'icon': IconData(iconValue, fontFamily: 'MaterialIcons'),
          };
        }).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  // Save a new category to the API
  static Future<void> saveCategory(
      String name, Color color, IconData icon) async {
    try {
      final response = await http.post(
        Uri.parse(createApiUrl), // Use createApiUrl for saving
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'icon': icon.codePoint.toString(), // Save icon's codePoint
          'color': color.value
              .toRadixString(16)
              .padLeft(8, '0'), // Save color as hex string
        }),
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to save category');
      }
    } catch (e) {
      print('Error saving category: $e');
    }
  }
}
