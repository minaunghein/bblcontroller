import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/printer_provider.dart';
import '../services/database_helper.dart';
import '../models/printer.dart';
import 'printers_list_screen.dart';
import 'printer_control_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isLoading = true;
  String _loadingText = 'Loading printers...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _loadingText = 'Loading printers...';
      });

      // Load all printers from database
      final List<Printer> allPrinters = await _databaseHelper.getAllPrinters();
      
      setState(() {
        _loadingText = 'Checking for pinned printer...';
      });

      // Check if there's a pinned printer
      final Printer? pinnedPrinter = await _databaseHelper.getPinnedPrinter();
      
      if (pinnedPrinter != null) {
        setState(() {
          _loadingText = 'Connecting to ${pinnedPrinter.name}...';
        });

        // Set up the printer provider with the pinned printer
        if (mounted) {
          final printerProvider = Provider.of<PrinterProvider>(context, listen: false);
          printerProvider.setPrinter(pinnedPrinter);
          
          // Connect to the printer
          await printerProvider.connect();
          
          // Navigate to printer control screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PrinterControlScreen(printer: pinnedPrinter),
            ),
          );
        }
      } else {
        // No pinned printer, navigate to printer list
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const PrintersListScreen(),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _loadingText = 'Error loading printers: $e';
      });
      
      // Wait a bit then navigate to printer list as fallback
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const PrintersListScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1e1e1e), Color(0xFF2d2d2d)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo or icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.print,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              
              // App title
              const Text(
                'Bambulab Controller',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 20),
              
              // Loading text
              Text(
                _loadingText,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}