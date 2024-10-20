import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'new_transaction_page.dart'; // ใช้สำหรับแก้ไขและเพิ่มข้อมูล
import 'package:intl/intl.dart'; // นำเข้า intl
import 'package:intl/date_symbol_data_local.dart'; // นำเข้าเพื่อใช้ initializeDateFormatting

class TransactionCrudPage extends StatefulWidget {
  @override
  _TransactionCrudPageState createState() => _TransactionCrudPageState();
}

class _TransactionCrudPageState extends State<TransactionCrudPage> {
  List<dynamic> transactions = [];
  Map<int, Map<String, dynamic>> categories = {}; // เก็บข้อมูลหมวดหมู่

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('th', null); // เรียกใช้ initializeDateFormatting
    fetchTransactions(); // โหลดข้อมูลเมื่อหน้าเริ่มทำงาน
    fetchCategories(); // ดึงข้อมูลหมวดหมู่
  }

  Future<void> fetchTransactions() async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.80.1:3001/api/transactions'));
      if (response.statusCode == 200) {
        setState(() {
          transactions = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error fetching transactions: $e');
    }
  }

  Future<void> fetchCategories() async {
    try {
      final response =
          await http.get(Uri.parse('http://192.168.80.1:3001/api/categorie'));
      if (response.statusCode == 200) {
        List<dynamic> categoryData = json.decode(response.body);
        setState(() {
          for (var category in categoryData) {
            categories[category['id']] = {
              'name': category['name'],
              'icon': _getCategoryIcon(category['name']),
              'color': _getCategoryColor(category['name']),
            };
          }
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  // ฟังก์ชันช่วยในการแมปชื่อหมวดหมู่กับไอคอนที่เหมาะสม
  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName) {
      case 'Food':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_car;
      case 'Entertainment':
        return Icons.movie;
      case 'Shopping':
        return Icons.shopping_cart;
      case 'Bills':
        return Icons.receipt;
      default:
        return Icons.category;
    }
  }

  // ฟังก์ชันช่วยในการแมปชื่อหมวดหมู่กับสีที่เหมาะสม
  Color _getCategoryColor(String categoryName) {
    switch (categoryName) {
      case 'Food':
        return Colors.green;
      case 'Transport':
        return Colors.blue;
      case 'Entertainment':
        return Colors.purple;
      case 'Shopping':
        return Colors.orange;
      case 'Bills':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      final response = await http
          .delete(Uri.parse('http://192.168.80.1:3001/api/transaction/$id'));
      if (response.statusCode == 200) {
        setState(() {
          transactions.removeWhere((transaction) => transaction['id'] == id);
        });
      }
    } catch (e) {
      print('Error deleting transaction: $e');
    }
  }

  Future<void> _navigateToEditTransaction(
      {Map<String, dynamic>? transaction}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => NewTransactionPage(transaction: transaction)),
    );
    if (result != null) {
      setState(() {
        if (transaction != null) {
          int index =
              transactions.indexWhere((t) => t['id'] == transaction['id']);
          transactions[index] = result;
        } else {
          transactions.add(result);
        }
      });
    }
  }

  /// ฟังก์ชันสำหรับจัดรูปแบบวันที่
  String _formatDate(String dateString) {
    final DateTime date = DateTime.parse(dateString);
    final DateFormat formatter =
        DateFormat('d MMMM yyyy, HH:mm', 'th'); // ใช้เวลาและวันที่
    return formatter.format(date); // คืนค่ารูปแบบวันที่ใหม่
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Transactions"),
        backgroundColor: Colors.orangeAccent, // สีหัวข้อของแอป
      ),
      body: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          final categoryId =
              transaction['category_id']; // ดึง category_id จากธุรกรรม
          final category = categories[categoryId] ??
              {
                'icon': Icons.category,
                'color': Colors.grey,
                'name': 'Unknown',
              };

          final amount = transaction['amount']?.toString() ?? '0.00';
          final date = transaction['transaction_date'] != null
              ? _formatDate(transaction[
                  'transaction_date']) // เรียกฟังก์ชันเพื่อจัดรูปแบบวันที่
              : 'Unknown Date';

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 5, // เพิ่มเงาให้กับการ์ดเพื่อความสวยงาม
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: category['color'], // ใช้สีจากหมวดหมู่
                child: Icon(
                  category['icon'], // ใช้ไอคอนจากหมวดหมู่
                  color: Colors.white,
                ),
              ),
              title: Text(
                category['name'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              subtitle: Text(
                "Date: $date", // แสดงวันที่แบบใหม่
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              trailing: Wrap(
                alignment: WrapAlignment.end,
                spacing: 4, // เพิ่มระยะห่างระหว่างปุ่ม
                children: [
                  Text(
                    '฿ $amount', // แสดงจำนวนเงิน
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _getAmountColor(transaction['type']),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, size: 20, color: Colors.blue),
                    onPressed: () =>
                        _navigateToEditTransaction(transaction: transaction),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () => deleteTransaction(transaction['id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditTransaction(),
        child: Icon(Icons.add),
        backgroundColor: Colors.orangeAccent,
      ),
    );
  }

  Color _getAmountColor(String type) {
    return type == 'Income' ? Colors.green : Colors.red;
  }
}
