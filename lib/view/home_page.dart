import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:badges/badges.dart' as badges_lib;
import 'package:intl/intl.dart'; // นำเข้า intl package สำหรับการจัดรูปแบบวันที่
import 'package:scop/view/transactions_page.dart';
import 'new_transaction_page.dart';
import 'summary_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> transactions = [];
  double totalIncome = 0.0;
  double totalExpense = 0.0;
  int notificationCount = 0;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.80.1:3001/api/transactions_g'));

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        if (decodedResponse is List) {
          setState(() {
            transactions = decodedResponse;
          });
        } else {
          throw Exception(
              'Expected a list of transactions but got: $decodedResponse');
        }
      } else {
        throw Exception('Failed to load transactions: ${response.statusCode}');
      }

      List<String> lineMessages = await fetchLineMessages();
      for (var message in lineMessages) {
        Map<String, dynamic>? parsedTransaction = parseLineMessage(message);
        if (parsedTransaction != null) {
          setState(() {
            transactions.add(parsedTransaction);
            notificationCount++;
          });
        }
      }
      _calculateTotals();
    } catch (e) {
      setState(() {
        transactions = [];
        totalIncome = 0.0;
        totalExpense = 0.0;
      });
    }
  }

  void _calculateTotals() {
    totalIncome = 0.0;
    totalExpense = 0.0;

    for (var transaction in transactions) {
      if (transaction is Map<String, dynamic>) {
        double amount =
            double.tryParse(transaction['amount']?.toString() ?? '0.0') ?? 0.0;

        if (transaction['type'] == 'Income') {
          totalIncome += amount;
        } else if (transaction['type'] == 'Expense') {
          totalExpense += amount;
        }
      }
    }
  }

  Future<void> _navigateToAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewTransactionPage()),
    );

    if (result != null) {
      setState(() {
        transactions.add(result);
        _calculateTotals();
        notificationCount++;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      List<FlSpot> incomeData = [];
      List<FlSpot> expenseData = [];

      for (int i = 0; i < transactions.length; i++) {
        var transaction = transactions[i];
        double amount =
            double.tryParse(transaction['amount'].toString()) ?? 0.0;
        if (transaction['type'] == 'income') {
          incomeData.add(FlSpot(i.toDouble(), amount));
        } else if (transaction['type'] == 'expense') {
          expenseData.add(FlSpot(i.toDouble(), amount));
        }
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SummaryChartPage(),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  String formatDate(String dateString) {
    try {
      // ระบุรูปแบบวันที่ที่ตรงกับข้อมูลต้นฉบับ
      final DateFormat inputFormat = DateFormat('dd/MM/yyyy HH:mm');
      final DateTime date =
          inputFormat.parse(dateString); // แปลงวันที่จาก input
      final DateFormat outputFormat =
          DateFormat('d MMMM yyyy, HH:mm', 'th'); // รูปแบบวันที่ที่ต้องการ
      return outputFormat.format(date); // คืนค่ารูปแบบวันที่ใหม่
    } catch (e) {
      print('Error formatting date: $e');
      return 'Invalid Date'; // กรณีเกิดข้อผิดพลาด
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Total Balance"),
        actions: [
          badges_lib.Badge(
            position: badges_lib.BadgePosition.topEnd(top: 0, end: 3),
            badgeContent: Text(
              notificationCount.toString(),
              style: TextStyle(color: Colors.white),
            ),
            child: IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () {
                setState(() {
                  notificationCount = 0;
                });
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionCrudPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Display total balance, income, and expense
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.orange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            margin: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "฿ ${(totalIncome - totalExpense).toStringAsFixed(2)}", // Total balance
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Income: ฿ ${totalIncome.toStringAsFixed(2)}", // Total income
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      "Expense: ฿ ${totalExpense.toStringAsFixed(2)}", // Total expense
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];

                if (transaction is Map<String, dynamic>) {
                  // Null-checks and default values for transaction data
                  String type = transaction['type'] ?? 'Unknown';
                  String categoryName = transaction['category_name'] ??
                      'LINE'; // Default to LINE if missing

                  // Check if the category is LINE and apply special rules
                  bool isLineCategory = categoryName == 'LINE';

                  // Ensure the icon code is valid, if null, default to a fallback icon
                  int categoryIconCode = isLineCategory
                      ? 0xe0b0 // Default to LINE-like icon if category is LINE (use a message icon)
                      : int.tryParse(transaction['category_icon'] ?? '') ??
                          0xe14c; // Default icon

                  // Ensure the color is valid, if null or LINE, use green
                  Color categoryColor = isLineCategory
                      ? Colors.green // LINE transactions get a green color
                      : (transaction['category_color'] != null
                          ? Color(
                              int.parse('0xff${transaction['category_color']}'))
                          : Colors.grey); // Default color

                  // Ensure the date is valid
                  String transactionDate =
                      transaction['transaction_date'] ?? 'Unknown Date';

                  // Ensure the amount is valid
                  double amount = double.tryParse(
                          transaction['amount']?.toString() ?? '0.0') ??
                      0.0;

                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: categoryColor,
                        child: Icon(
                          IconData(categoryIconCode,
                              fontFamily: 'MaterialIcons'),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(categoryName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(formatDate(transactionDate)), // Format date
                          Text(type), // Display type (Expense/Income)
                        ],
                      ),
                      trailing: Text(
                        "฿ ${amount.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: type == 'income' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                } else {
                  return ListTile(
                    title: Text('Invalid transaction format'),
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTransaction,
        child: Icon(Icons.add),
        backgroundColor: Colors.orangeAccent,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "Summary"),
        ],
      ),
    );
  }

  Future<List<String>> fetchLineMessages() async {
    return [
      'เงินเข้า: มีเงินโอน 80.00 บาท จาก "John Doe" บัญชี X -XXXX ธนาคาร SCB เข้าบัญชีออมทรัพย์ X-XXXX วันที่ 09/09/2024 @11:52 ผ่าน ENET ยอดเงินที่ใช้ได้ 731.78 บาท',
      'เงินออก: โอนเงิน 40.00 บาท จากบัญชีออมทรัพย์ X-XXXX วันที่ 16/09/2024 @17:01 ผ่าน ENET ยอดเงินที่ใช้ได้ 298.78 บาท',
      'เงินออก: ถอน/โอนเงิน 10.00 บาท จากบัญชีออมทรัพย์ X-XXXX วันที่ 02/10/2024 @17:45 ผ่าน ENET ยอดเงินที่ใช้ได้ 5,678.51 บาท',
    ];
  }
}

// ฟังก์ชันการจัดรูปแบบจากข้อความ LINE
Map<String, dynamic>? parseLineMessage(String message) {
  RegExp incomePattern = RegExp(r'เงินเข้า: มีเงินโอน ([\d,.]+) บาท');
  RegExp expensePattern =
      RegExp(r'เงินออก: (?:ถอน\/โอนเงิน|โอนเงิน) ([\d,.]+) บาท');
  RegExp datePattern = RegExp(r'วันที่ (\d{2}\/\d{2}\/\d{4}) @(\d{2}:\d{2})');

  var incomeMatch = incomePattern.firstMatch(message);
  if (incomeMatch != null) {
    double amount = double.parse(incomeMatch.group(1)!.replaceAll(',', ''));
    var dateMatch = datePattern.firstMatch(message);
    String date = dateMatch != null
        ? dateMatch.group(1)! + " " + dateMatch.group(2)!
        : 'Unknown Date';
    return {
      'type': 'income',
      'amount': amount,
      'transaction_date': date,
      'category': 'LINE'
    };
  }

  var expenseMatch = expensePattern.firstMatch(message);
  if (expenseMatch != null) {
    double amount = double.parse(expenseMatch.group(1)!.replaceAll(',', ''));
    var dateMatch = datePattern.firstMatch(message);
    String date = dateMatch != null
        ? dateMatch.group(1)! + " " + dateMatch.group(2)!
        : 'Unknown Date';
    return {
      'type': 'expense',
      'amount': amount,
      'transaction_date': date,
      'category': 'LINE'
    };
  }

  return null;
}
