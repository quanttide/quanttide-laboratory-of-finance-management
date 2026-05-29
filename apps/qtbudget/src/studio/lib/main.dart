import 'package:flutter/material.dart';
import 'pages/dashboard_page.dart';

void main() {
  runApp(const QtBudgetApp());
}

class QtBudgetApp extends StatelessWidget {
  const QtBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '量潮预算管家',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const DashboardPage(),
    );
  }
}
