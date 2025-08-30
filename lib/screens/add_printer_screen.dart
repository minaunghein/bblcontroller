import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/printer.dart';
import '../providers/printer_provider.dart';
import '../services/database_helper.dart';

class AddPrinterScreen extends StatefulWidget {
  const AddPrinterScreen({Key? key}) : super(key: key);

  @override
  State<AddPrinterScreen> createState() => _AddPrinterScreenState();
}

class _AddPrinterScreenState extends State<AddPrinterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  final _accessCodeController = TextEditingController();
  final _snController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _accessCodeController.dispose();
    _snController.dispose();
    super.dispose();
  }

  // Function to get model name from deviceID prefix
  String _getModelFromDeviceID(String deviceID) {
    if (deviceID.length >= 3) {
      final prefix = deviceID.substring(0, 3);
      switch (prefix) {
        case '00M':
          return 'X1 Carbon';
        case '03W':
          return 'X1E';
        case '01P':
          return 'P1S';
        case '01S':
          return 'P1P';
        case '039':
          return 'A1';
        case '030':
          return 'A1 mini';
        case '094':
          return 'H2D';
        default:
          return 'Unknown Model';
      }
    }
    return '';
  }

  Future<void> _addPrinter() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Determine model from SN if provided
      String? model;
      if (_snController.text.isNotEmpty) {
        model = _getModelFromDeviceID(_snController.text);
      }

      // Create printer object
      final printer = Printer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        ipAddress: _ipController.text,
        port: 8883, // Default MQTT port
        accessCode: _accessCodeController.text,
        model: model,
        deviceID: _snController.text.isNotEmpty ? _snController.text : null,
      );

      // Try to connect and get device information
      try {
        final printerProvider =
            Provider.of<PrinterProvider>(context, listen: false);
        printerProvider.setPrinter(printer);
        await printerProvider.connect();

        // Wait for device information
        await Future.delayed(const Duration(seconds: 3));

        final updatedPrinter = printerProvider.currentPrinter ?? printer;
        await printerProvider.disconnect();

        // Save printer with device information
        final result = await _databaseHelper.insertPrinter(updatedPrinter);
        if (result > 0) {
          _showSuccessMessage(
              'Printer added successfully with device information');
          Navigator.of(context).pop(true); // Return true to indicate success
        } else {
          _showErrorMessage('Failed to add printer');
        }
      } catch (e) {
        // If connection fails, save basic printer info
        final result = await _databaseHelper.insertPrinter(printer);
        if (result > 0) {
          _showSuccessMessage(
              'Printer added successfully (device info will be updated on first connection)');
          Navigator.of(context).pop(true);
        } else {
          _showErrorMessage('Failed to add printer');
        }
      }
    } catch (e) {
      _showErrorMessage('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _scanForPrinter() {
    // TODO: Implement network scanning functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scan functionality coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Function to get image path from deviceID prefix
  String _getPrinterImagePath(String deviceID) {
    if (deviceID.length >= 3) {
      final prefix = deviceID.substring(0, 3);
      switch (prefix) {
        case '00M':
          return 'assets/X1 Carbon_cover.png';
        case '03W':
          return 'assets/X1E_cover.png';
        case '01P':
          return 'assets/P1S_cover.png';
        case '01S':
          return 'assets/P1P_cover.png';
        case '039':
          return 'assets/A1_cover.png';
        case '030':
          return 'assets/A1 mini_cover.png';
        case '094':
          return 'assets/H2D_cover.png';
        default:
          return 'assets/unknown_cover.png';
      }
    }
    return 'assets/unknown_cover.png';
  }

  Widget _buildPrinterImage() {
    // Get the appropriate image path based on SN input
    String imagePath = _snController.text.isNotEmpty
        ? _getPrinterImagePath(_snController.text)
        : 'assets/unknown_cover.png';

    return Container(
      padding: const EdgeInsets.all(10),
      child: Center(
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.print,
                  size: 100,
                  color: Colors.white70,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field
              const Text(
                'Name:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: '(Required)Input your printer name',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF4A6B6B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a printer name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Printer IP field
              const Text(
                'Printer IP:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ipController,
                decoration: InputDecoration(
                  hintText: '(Required)Input your printer IP',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF4A6B6B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the printer IP address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Access Code field
              const Text(
                'Access Code:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _accessCodeController,
                decoration: InputDecoration(
                  hintText: '(Required)Input your access code',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF4A6B6B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the access code';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // SN field
              const Text(
                'SN:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _snController,
                decoration: InputDecoration(
                  hintText: '(Required)Input your SN',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF4A6B6B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  // Auto-detect model when SN is entered
                  setState(() {});
                },
              ),

              const SizedBox(height: 40),

              // Info text
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Show help dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text(
                                'How to get IP, Access Code, and SN Code'),
                            content: const Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '1. On your printer screen, go to Settings'),
                                Text('2. Navigate to Network > WiFi'),
                                Text('3. Find the IP address'),
                                Text(
                                    '4. Go to Settings > General > Access Code'),
                                Text(
                                    '5. Find the SN in Settings > General > Device Info'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text(
                        'How to get IP, Access Code, and SN Code.',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add Printer',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height - 100,
                child: OrientationBuilder(
                  builder: (context, orientation) {
                    if (orientation == Orientation.portrait) {
                      // Portrait: Image on top, form on bottom
                      return Column(
                        children: [
                          // Top - Printer image
                          Expanded(
                            flex: 1,
                            child: _buildPrinterImage(),
                          ),
                          // Bottom - Form
                          Expanded(
                            flex: 3,
                            child: _buildForm(),
                          ),
                        ],
                      );
                    } else {
                      // Landscape: Image on left, form on right
                      return Row(
                        children: [
                          // Left side - Printer image
                          Expanded(
                            flex: 2,
                            child: _buildPrinterImage(),
                          ),
                          // Right side - Form
                          Expanded(
                            flex: 3,
                            child: _buildForm(),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),

              // Bottom buttons
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Confirm button
                  SizedBox(
                    width: 120,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addPrinter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isLoading ? Colors.grey : Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Confirm',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
