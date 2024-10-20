import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SummaryChartPage extends StatefulWidget {
  @override
  _SummaryChartPageState createState() => _SummaryChartPageState();
}

class _SummaryChartPageState extends State<SummaryChartPage> {
  List<FlSpot> incomeData = [];
  List<FlSpot> expenseData = [];
  bool isLoading = true;
  String selectedPeriod = 'daily'; // Default period
  Map<String, dynamic> summaryData = {};

  @override
  void initState() {
    super.initState();
    _fetchTransactionData();
  }

  Future<void> _fetchTransactionData() async {
    final url = Uri.parse('http://192.168.80.1:3001/api/transactions/');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List transactions = jsonDecode(response.body);
        _processTransactionData(transactions);
        _fetchSummaryData();
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (error) {
      print('Error fetching data: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching transaction data')),
      );
    }
  }

  void _processTransactionData(List transactions) {
    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];

    // Group transactions by date and accumulate totals for Income and Expense
    Map<String, double> incomeMap = {};
    Map<String, double> expenseMap = {};

    for (var transaction in transactions) {
      String date =
          transaction['transaction_date']; // Expecting format 'yyyy-MM-dd'
      double amount = double.parse(transaction['amount']);
      String type = transaction['type'];

      if (type == 'Income') {
        incomeMap[date] = (incomeMap[date] ?? 0) + amount;
      } else if (type == 'Expense') {
        expenseMap[date] = (expenseMap[date] ?? 0) + amount;
      }
    }

    final sortedIncomeDates = incomeMap.keys.toList()..sort();
    final sortedExpenseDates = expenseMap.keys.toList()..sort();

    for (int i = 0; i < sortedIncomeDates.length; i++) {
      incomeSpots.add(FlSpot(i.toDouble(), incomeMap[sortedIncomeDates[i]]!));
    }

    for (int i = 0; i < sortedExpenseDates.length; i++) {
      expenseSpots
          .add(FlSpot(i.toDouble(), expenseMap[sortedExpenseDates[i]]!));
    }

    setState(() {
      incomeData = incomeSpots;
      expenseData = expenseSpots;
      isLoading = false;
    });
  }

  Future<void> _fetchSummaryData() async {
    final url = Uri.parse('http://192.168.80.1:3001/api/transactions/');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List transactions = jsonDecode(response.body);

        double totalIncome = 0;
        double totalExpense = 0;
        int smsIncomeCount = 0;
        int smsExpenseCount = 0;

        Map<String, int> incomeCategories = {};
        Map<String, int> expenseCategories = {};

        for (var transaction in transactions) {
          String type = transaction['type'];
          double amount = double.parse(transaction['amount']);
          int categoryId = transaction['category_id'];

          // Assume transactions with category_id == 1 come from SMS
          if (type == 'Income') {
            totalIncome += amount;
            if (categoryId == 1) smsIncomeCount++;

            // นับจำนวนครั้งที่รายได้แต่ละประเภทเกิดขึ้น (เช่น Salary, Freelance)
            incomeCategories[categoryId.toString()] =
                (incomeCategories[categoryId.toString()] ?? 0) + 1;
          } else if (type == 'Expense') {
            totalExpense += amount;
            if (categoryId == 1) smsExpenseCount++;

            // นับจำนวนครั้งที่รายจ่ายแต่ละประเภทเกิดขึ้น (เช่น Food, Shopping)
            expenseCategories[categoryId.toString()] =
                (expenseCategories[categoryId.toString()] ?? 0) + 1;
          }
        }

        setState(() {
          summaryData = {
            'totalIncome': totalIncome,
            'totalExpense': totalExpense,
            'smsIncomeCount': smsIncomeCount,
            'smsExpenseCount': smsExpenseCount,
            'categoryBreakdown': {
              'Income': incomeCategories,
              'Expense': expenseCategories,
            },
          };
        });
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (error) {
      print('Error fetching summary data: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching summary data')),
      );
    }
  }

  void _changePeriod(String period) {
    setState(() {
      selectedPeriod = period;
      isLoading = true;
      _fetchTransactionData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Summary'),
        backgroundColor: Colors.blueGrey[900],
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // กราฟ
                  Expanded(
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: LineChart(
                          LineChartData(
                            backgroundColor: Colors.white,
                            gridData: FlGridData(
                              show: true,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.grey.withOpacity(0.3),
                                strokeWidth: 1,
                              ),
                              getDrawingVerticalLine: (value) => FlLine(
                                color: Colors.grey.withOpacity(0.3),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) => Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Text(
                                      '฿${value.toInt()}',
                                      style: TextStyle(
                                          color: Colors.blueGrey[800],
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) => Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      (value + 1).toInt().toString(),
                                      style: TextStyle(
                                          color: Colors.blueGrey[800],
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: incomeData,
                                isCurved: true,
                                color: Colors.green,
                                barWidth: 3,
                                dotData: FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.green.withOpacity(0.2),
                                ),
                              ),
                              LineChartBarData(
                                spots: expenseData,
                                isCurved: true,
                                color: Colors.red,
                                barWidth: 3,
                                dotData: FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.red.withOpacity(0.2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // ปุ่มสลับช่วงเวลา (รายวัน, รายสัปดาห์, รายเดือน)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPeriodButton('รายวัน', selectedPeriod == 'daily'),
                      _buildPeriodButton(
                          'รายสัปดาห์', selectedPeriod == 'weekly'),
                      _buildPeriodButton(
                          'รายเดือน', selectedPeriod == 'monthly'),
                    ],
                  ),

                  SizedBox(height: 20),

                  // ข้อมูลสรุป
                  _buildSummarySection(),
                ],
              ),
            ),
    );
  }

  ElevatedButton _buildPeriodButton(String text, bool isSelected) {
    return ElevatedButton(
      onPressed: () => _changePeriod(text == 'รายวัน'
          ? 'daily'
          : text == 'รายสัปดาห์'
              ? 'weekly'
              : 'monthly'),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor:
            isSelected ? Colors.blueGrey[900] : Colors.blueGrey[400],
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // กล่องสรุปยอดรวม
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ยอดรวม',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[900],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text('รายรับ: ฿${summaryData['totalIncome']}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green[700],
                      )),
                  Text('รายจ่าย: ฿${summaryData['totalExpense']}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red[700],
                      )),
                ],
              ),
            ),

            // กล่องสรุปจากข้อความ SMS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'จากข้อความ SMS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[900],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text('รายรับจาก SMS: ${summaryData['smsIncomeCount']}'),
                  Text('รายจ่ายจาก SMS: ${summaryData['smsExpenseCount']}'),
                ],
              ),
            ),

            // กล่องหมวดหมู่
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'หมวดหมู่',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[900],
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildCategoryBreakdown('Income'),
                  _buildCategoryBreakdown('Expense'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(String type) {
    if (summaryData['categoryBreakdown'] == null ||
        summaryData['categoryBreakdown'][type] == null) {
      return Text(
        'No data available for $type',
        style: TextStyle(
          fontSize: 16,
          color: Colors.red[700],
        ),
      );
    }

    Map categories = summaryData['categoryBreakdown'][type];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.keys.map<Widget>((category) {
        return Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text('$category: ${categories[category]}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey[700],
              )),
        );
      }).toList(),
    );
  }
}
