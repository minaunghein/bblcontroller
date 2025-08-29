import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/printer_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/printers_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => PrinterProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Bambulab Controller',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const PrintersListScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
