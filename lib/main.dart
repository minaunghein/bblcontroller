import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/printer_provider.dart';
import 'screens/printers_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PrinterProvider(),
      child: MaterialApp(
        title: 'Bambulab Controller',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: const Color(0xFF1e1e1e),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2d2d2d),
            foregroundColor: Colors.white,
          ),
          cardTheme: const CardTheme(
            color: Color(0xFF2d2d2d),
          ),
          drawerTheme: const DrawerThemeData(
            backgroundColor: Color(0xFF1e1e1e),
          ),
        ),
        home: const PrintersListScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
