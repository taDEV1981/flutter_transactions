import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import the intl package
import 'package:intl/date_symbol_data_local.dart'; // Correct import for local data
import 'package:scop/view/home_page.dart'; // Import your HomePage widget

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for the 'th' (Thai) locale
  await initializeDateFormatting('th', null);

  // Start the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transactions Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}

// Format date function
String formatDate(String dateString) {
  final DateTime date = DateTime.parse(dateString);
  final DateFormat formatter =
      DateFormat('d MMMM yyyy, HH:mm', 'th'); // Thai locale
  return formatter.format(date); // Format date correctly
}
