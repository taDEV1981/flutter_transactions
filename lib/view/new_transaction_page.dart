import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // สำหรับการฟอร์แมตวันที่
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:scop/services/category_service.dart';
import 'package:scop/widgets/category_picker.dart';

class NewTransactionPage extends StatefulWidget {
  final Map<String, dynamic>? transaction; // Accept an optional transaction

  NewTransactionPage({this.transaction});

  @override
  _NewTransactionPageState createState() => _NewTransactionPageState();
}

class _NewTransactionPageState extends State<NewTransactionPage> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedCategory = ''; // Store category name
  String _selectedType = 'Expense'; // Default เป็น Expense
  DateTime _selectedDate = DateTime.now(); // Default เป็นวันที่ปัจจุบัน
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];
  Map<String, dynamic>? _selectedCategoryData; // Store the full category data

  @override
  void initState() {
    super.initState();

    // If a transaction is passed, populate the fields for editing
    if (widget.transaction != null) {
      final transaction = widget.transaction!;
      _amountController.text = transaction['amount'].toString();
      _selectedCategory = transaction['category'] ?? '';
      _selectedType = transaction['type'] ?? 'Expense';
      _selectedDate = DateTime.parse(transaction['transaction_date']);
    }

    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final categories = await CategoryService.fetchCategories();
    setState(() {
      _categories = categories;
      _isLoading = false;
    });
  }

  Future<void> _submitTransaction() async {
    // ตรวจสอบข้อมูลว่ากรอกครบหรือไม่
    if (_amountController.text.isEmpty || _selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please complete all fields, including category')),
      );
      return;
    }

    // Attempt to find the selected category
    final category = _selectedCategoryData;

    if (category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid category selection')),
      );
      return;
    }

    final url = Uri.parse(
        'http://192.168.80.1:3001/api/transaction'); // Adjust this if necessary
    final data = {
      'category_id': category['id'],
      'type': _selectedType,
      'amount': _amountController.text,
      'transaction_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction saved successfully')),
        );
        Navigator.pop(context); // กลับไปหน้าก่อนหน้า
      } else {
        // Log the status code and the response body to understand the failure
        print('Failed with status code: ${response.statusCode}');
        print('Response body: ${response.body}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to save transaction: ${response.body}')),
        );
      }
    } catch (error) {
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input สำหรับ Amount (จำนวนเงิน)
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: '฿ Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),

            // Dropdown สำหรับเลือก Type (Income, Expense)
            DropdownButtonFormField<String>(
              value: _selectedType,
              onChanged: (newValue) {
                setState(() {
                  _selectedType = newValue!;
                });
              },
              items: ['Income', 'Expense']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Transaction Type',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // Date picker สำหรับเลือกวันที่
            ListTile(
              title: Text(
                  "Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}"),
              trailing: Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            SizedBox(height: 20),

            // ส่วนเลือก Category
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected Category: ${_selectedCategory.isEmpty ? 'None' : _selectedCategory}',
                ),
                // Button to add a new category
                IconButton(
                  icon: Icon(Icons.add, color: Colors.blue),
                  onPressed: _addNewCategory,
                ),
              ],
            ),
            SizedBox(height: 10),

            // List ของ Categories
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Expanded(
                    child: ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return ListTile(
                          leading:
                              Icon(category['icon'], color: category['color']),
                          title: Text(category['name']),
                          onTap: () {
                            setState(() {
                              _selectedCategory = category['name'];
                              _selectedCategoryData =
                                  category; // Store full category data
                            });
                          },
                          selected: _selectedCategory == category['name'],
                        );
                      },
                    ),
                  ),

            // ปุ่ม Save เพื่อบันทึกข้อมูล
            ElevatedButton(
              onPressed: _submitTransaction,
              child: Text('Save Transaction'),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewCategory() {
    showDialog(
      context: context,
      builder: (context) => CategoryPicker(
        onSave: (String name, Color color, IconData icon) async {
          await CategoryService.saveCategory(name, color, icon);
          _fetchCategories(); // Refresh category list after saving a new one
        },
      ),
    );
  }
}
