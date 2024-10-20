import 'package:mysql1/mysql1.dart';

class MySQLDatabase {
  // กำหนดการตั้งค่าการเชื่อมต่อ
  final ConnectionSettings settings = ConnectionSettings(
    host: '127.0.0.1',
    port: 3308, // เปลี่ยนเป็น 3306 ถ้าจำเป็น
    user: 'root',
    password: '',
    db: 'transactions',
  );

  // ฟังก์ชันสำหรับดึงข้อมูลธุรกรรม
  Future<List<Map<String, dynamic>>> fetchTransactions() async {
    try {
      // สร้างการเชื่อมต่อกับฐานข้อมูล
      final conn = await MySqlConnection.connect(settings);

      // รันคำสั่ง SQL
      var results = await conn.query('SELECT * FROM transactions');

      // แปลงข้อมูลเป็น List<Map>
      List<Map<String, dynamic>> transactions = [];
      for (var row in results) {
        transactions.add({
          'id': row['id'],
          'category': row['category'],
          'amount': row['amount'],
          'date': row['date'].toString(),
        });
      }

      // ปิดการเชื่อมต่อ
      await conn.close();

      return transactions;
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }
}
