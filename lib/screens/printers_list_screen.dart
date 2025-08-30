import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/printer.dart';
import '../providers/printer_provider.dart';
import '../services/database_helper.dart';
import '../services/printer_connectivity_service.dart';
import 'printer_control_screen.dart';
import 'settings_screen.dart';
import 'add_printer_screen.dart'; // Add this import
import '../models/printer_template.dart';

class PrintersListScreen extends StatefulWidget {
  const PrintersListScreen({Key? key}) : super(key: key);

  @override
  State<PrintersListScreen> createState() => _PrintersListScreenState();
}

class _PrintersListScreenState extends State<PrintersListScreen> {
  bool isSearchable = false; // Set to true to enable search functionality
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printers'),
        backgroundColor: Colors.greenAccent[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                isSearchable = !isSearchable;
                if (!isSearchable) {
                  _searchController.clear();
                  _filteredPrinters = _printers;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPrinters,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddPrinterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (isSearchable)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search Printers',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _filteredPrinters = _printers
                              .where((printer) => printer.name
                                  .toLowerCase()
                                  .contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshPrinters,
                    child: _filteredPrinters.isEmpty
                        ? const Center(
                            child: Text('No printers found'),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(6),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 5,
                              mainAxisSpacing: 6,
                              childAspectRatio: .7,
                            ),
                            itemCount: _filteredPrinters.length,
                            itemBuilder: (context, index) {
                              final printer = _filteredPrinters[index];
                              final isOnline = _connectivityService
                                  .isPrinterOnline(printer.id);

                              return Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: InkWell(
                                    onTap: () => _connectToPrinter(
                                        printer, printer.isOnline),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Status indicator and menu

                                          // Printer image
                                          Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.asset(
                                                  _getPrinterImageAsset(
                                                      printer.model),
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    // Fallback to icon if image fails to load
                                                    return Icon(
                                                      Icons.print,
                                                      size: 48,
                                                      color: isOnline
                                                          ? Colors.blue
                                                          : Colors.grey,
                                                    );
                                                  },
                                                ),
                                              ),

                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Container(
                                                    width: 12,
                                                    height: 12,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: isOnline
                                                          ? Colors.green
                                                          : Colors.red,
                                                    ),
                                                  ),
                                                  PopupMenuButton(
                                                    itemBuilder: (context) => [
                                                      PopupMenuItem(
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              printer.isPin
                                                                  ? Icons
                                                                      .lock_open
                                                                  : Icons
                                                                      .push_pin,
                                                              size: 18,
                                                            ),
                                                            const SizedBox(
                                                                width: 8),
                                                            Text(printer.isPin
                                                                ? 'Unpin'
                                                                : 'Pin'),
                                                          ],
                                                        ),
                                                        onTap: () =>
                                                            _togglePinPrinter(
                                                                printer),
                                                      ),
                                                      PopupMenuItem(
                                                        child: const Row(
                                                          children: [
                                                            Icon(Icons.edit,
                                                                size: 18),
                                                            SizedBox(width: 8),
                                                            Text('Edit'),
                                                          ],
                                                        ),
                                                        onTap: () =>
                                                            _editPrinter(
                                                                printer),
                                                      ),
                                                      PopupMenuItem(
                                                        child: const Row(
                                                          children: [
                                                            Icon(Icons.delete,
                                                                size: 18,
                                                                color:
                                                                    Colors.red),
                                                            SizedBox(width: 8),
                                                            Text('Delete',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .red)),
                                                          ],
                                                        ),
                                                        onTap: () =>
                                                            _deletePrinter(
                                                                printer),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              // Pin indicator (lock icon)
                                              if (printer.isPin)
                                                Positioned(
                                                  top: 15,
                                                  left: 20,
                                                  child: const Icon(
                                                    Icons.push_pin,
                                                    color: Colors.black,
                                                    size: 16,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          // Printer name
                                          Text(
                                            printer.name +
                                                " (${printer.model})",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),

                                          const SizedBox(height: 2),
                                          // IP Address
                                          Text(
                                            'IP: ${printer.ipAddress}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Spacer(),
                                          // Status text and wifi icon
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                isOnline ? 'Online' : 'Offline',
                                                style: TextStyle(
                                                  color: isOnline
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Icon(
                                                isOnline
                                                    ? Icons.wifi
                                                    : Icons.wifi_off,
                                                color: isOnline
                                                    ? Colors.green
                                                    : Colors.red,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Printer> _printers = [];
  List<Printer> _filteredPrinters = [];
  List<PrinterTemplate> _templates = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  final PrinterConnectivityService _connectivityService =
      PrinterConnectivityService();

  // Helper method to map printer models to image assets
  String _getPrinterImageAsset(String? model) {
    if (model == null) return 'assets/P1P_cover.png'; // Default fallback

    // Map printer models to their corresponding image assets
    final Map<String, String> modelImageMap = {
      'A1Mini': 'assets/A1 mini_cover.png',
      'A1': 'assets/A1_cover.png',
      'H2DPro': 'assets/H2D Pro_cover.png',
      'H2D': 'assets/H2D_cover.png',
      'P1P': 'assets/P1P_cover.png',
      'P1S': 'assets/P1S_cover.png',
      'X1C': 'assets/X1 Carbon_cover.png',
      'X1E': 'assets/X1E_cover.png',
      'X1': 'assets/X1_cover.png',
    };

    return modelImageMap[model] ??
        'assets/P1P_cover.png'; // Default to P1P if model not found
  }

  @override
  void initState() {
    super.initState();
    _loadPrinters();
    _loadTemplates();
    _setupConnectivityService();
  }

// Add this method to handle pin/unpin functionality
  void _togglePinPrinter(Printer printer) async {
    try {
      int result;
      if (printer.isPin) {
        // Unpin the printer
        result = await _databaseHelper.unpinPrinter(printer.id);
        if (result > 0) {
          _showSuccessSnackBar('${printer.name} unpinned successfully');
        } else {
          _showErrorSnackBar('Failed to unpin printer');
        }
      } else {
        // Pin the printer (this will automatically unpin others)
        result = await _databaseHelper.pinPrinter(printer.id);
        if (result > 0) {
          _showSuccessSnackBar('${printer.name} pinned successfully');
        } else {
          _showErrorSnackBar('Failed to pin printer');
        }
      }

      // Refresh the printer list to show updated pin status
      if (result > 0) {
        _loadPrinters();
      }
    } catch (e) {
      print('Error toggling pin status: $e');
      _showErrorSnackBar('Failed to update pin status');
    }
  }

  void _setupConnectivityService() {
    _connectivityService.onPrinterStatusChanged = (printerId, isOnline) {
      setState(() {
        // Update the printer status in the local list
        final printerIndex = _printers.indexWhere((p) => p.id == printerId);
        if (printerIndex != -1) {
          _printers[printerIndex] =
              _printers[printerIndex].copyWith(isOnline: isOnline);
          _filteredPrinters = _printers
              .where((printer) => printer.name
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()))
              .toList();
        }
      });
    };
  }

  Future<void> _loadPrinters() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final printers = await _databaseHelper.getAllPrinters();
      setState(() {
        _printers = printers;
        _filteredPrinters = printers;
        _isLoading = false;
      });

      // Start monitoring printer connectivity
      _connectivityService.startMonitoring(printers);
    } catch (e) {
      print('Error loading printers: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load printers');
    }
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await _databaseHelper.getAllTemplates();
      setState(() {
        _templates = templates;
      });
    } catch (e) {
      print('Error loading templates: $e');
    }
  }

  void _showAddPrinterDialog() {
    // Replace the existing dialog with navigation to new screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddPrinterScreen(),
      ),
    ).then((result) {
      // Refresh the printer list if a printer was added
      if (result == true) {
        _loadPrinters();
      }
    });
  }

  Future<void> _addPrinter(String name, String ip, int port, String accessCode,
      String? model, String? deviceID) async {
    // Show loading dialog
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
              builder: (context, setDialogState) => AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('Connecting to $name...'),
                    const SizedBox(height: 8),
                    const Text(
                      'Retrieving printer information...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ));

    try {
      // Create temporary printer for connection
      final tempPrinter = Printer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        ipAddress: ip,
        port: port,
        accessCode: accessCode,
        model: model,
        deviceID: deviceID,
      );

      // Connect to printer and retrieve device information
      final printerProvider =
          Provider.of<PrinterProvider>(context, listen: false);
      printerProvider.setPrinter(tempPrinter);

      // Connect and wait for device information
      await printerProvider.connect();

      // Wait a bit for device information to be received
      await Future.delayed(const Duration(seconds: 3));

      // Get updated printer with device information
      final updatedPrinter = printerProvider.currentPrinter ?? tempPrinter;

      // Disconnect after retrieving information
      await printerProvider.disconnect();

      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Save printer with retrieved device information
      final result = await _databaseHelper.insertPrinter(updatedPrinter);
      if (result > 0) {
        // Close loading dialog
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
        _showSuccessSnackBar(
            'Printer added successfully with device information');
        _loadPrinters();
      } else {
        _showErrorSnackBar('Failed to add printer');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('Error adding printer: $e');

      // Show error dialog with option to save without device info
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connection Failed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Failed to retrieve device information from $name.'),
              const SizedBox(height: 12),
              const Text(
                  'Would you like to save the printer without device information?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                // Save printer without device information
                final basicPrinter = Printer(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  ipAddress: ip,
                  port: port,
                  accessCode: accessCode,
                  model: model,
                  deviceID: deviceID,
                );

                final result =
                    await _databaseHelper.insertPrinter(basicPrinter);
                if (result > 0) {
                  _showSuccessSnackBar(
                      'Printer added successfully (device info will be updated on first connection)');
                  _loadPrinters();
                } else {
                  _showErrorSnackBar('Failed to add printer');
                }
              },
              child: const Text('Save Anyway'),
            ),
          ],
        ),
      );
    }
  }

  void _editPrinter(Printer printer) {
    final nameController = TextEditingController(text: printer.name);
    final ipController = TextEditingController(text: printer.ipAddress);
    final portController = TextEditingController(text: printer.port.toString());
    final accessCodeController =
        TextEditingController(text: printer.accessCode);
    final modelController = TextEditingController(text: printer.model ?? '');
    final deviceIDController =
        TextEditingController(text: printer.deviceID ?? '');

    // Function to get model name from deviceID prefix
    String getModelFromDeviceID(String deviceID) {
      if (deviceID.length >= 3) {
        final prefix = deviceID.substring(0, 3);
        switch (prefix) {
          case '00M':
            return 'X1C';
          case '03W':
            return 'X1E';
          case '01P':
            return 'P1S';
          case '01S':
            return 'P1P';
          case '039':
            return 'A1';
          case '030':
            return 'A1Mini';
          case '094':
            return 'H2S';
          default:
            return '';
        }
      }
      return '';
    }

    // Set initial model based on existing deviceID
    if (deviceIDController.text.isNotEmpty) {
      modelController.text = getModelFromDeviceID(deviceIDController.text);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Printer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Printer Name *',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ipController,
                  decoration: const InputDecoration(
                    labelText: 'IP Address *',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: portController,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: accessCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Access Code *',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: deviceIDController,
                  decoration: const InputDecoration(
                    labelText: 'Device ID',
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      modelController.text = getModelFromDeviceID(value);
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: modelController,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                  ),
                  readOnly: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    ipController.text.isNotEmpty &&
                    accessCodeController.text.isNotEmpty) {
                  try {
                    final updatedPrinter = printer.copyWith(
                      name: nameController.text,
                      ipAddress: ipController.text,
                      port: int.tryParse(portController.text) ?? 8883,
                      accessCode: accessCodeController.text,
                      model: modelController.text.isEmpty
                          ? null
                          : modelController.text,
                      deviceID: deviceIDController.text.isEmpty
                          ? null
                          : deviceIDController.text,
                    );

                    final result =
                        await _databaseHelper.updatePrinter(updatedPrinter);
                    if (result > 0) {
                      _showSuccessSnackBar('Printer updated successfully');
                      _loadPrinters();
                      Navigator.pop(context);
                    } else {
                      _showErrorSnackBar('Failed to update printer');
                    }
                  } catch (e) {
                    print('Error updating printer: $e');
                    _showErrorSnackBar('Failed to update printer');
                  }
                } else {
                  _showErrorSnackBar('Please fill in all required fields');
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _deletePrinter(Printer printer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Printer'),
        content: Text('Are you sure you want to delete "${printer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final result = await _databaseHelper.deletePrinter(printer.id);
                if (result > 0) {
                  _showSuccessSnackBar('Printer deleted successfully');
                  _loadPrinters();
                } else {
                  _showErrorSnackBar('Failed to delete printer');
                }
                Navigator.pop(context);
              } catch (e) {
                print('Error deleting printer: $e');
                _showErrorSnackBar('Failed to delete printer');
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _connectToPrinter(Printer printer, bool isOnline) async {
    // Show loading indicator

    try {
      // Attempt to connect to the printer
      if (!isOnline) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Connecting to ${printer.name}...'),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we establish connection...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }
      // Close loading dialog

      if (isOnline) {
        // Show success message
        //_showSuccessSnackBar('Connected to ${printer.name} successfully!');

        // Connect to MQTT and start listening for printer data
        final printerProvider =
            Provider.of<PrinterProvider>(context, listen: false);
        printerProvider.setPrinter(printer);
        await printerProvider.connect().then((value) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PrinterControlScreen(printer: printer),
            ),
          );
        });

        // Navigate to printer control screen
      } else {
        // Show error message with helpful tips
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Connection Failed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Failed to connect to ${printer.name}.'),
                const SizedBox(height: 12),
                const Text('Please check:'),
                const SizedBox(height: 8),
                const Text('• Printer is powered on'),
                const Text('• Network connection is stable'),
                const Text('• IP address is correct'),
                const Text('• Access code is valid'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _editPrinter(printer); // Allow user to edit printer settings
                },
                child: const Text('Edit Settings'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('Error connecting to printer: $e');
      _showErrorSnackBar('Connection error: ${e.toString()}');
    }
  }

  Future<void> _refreshPrinters() async {
    await _loadPrinters();
    _showSuccessSnackBar('Printers refreshed');
  }

  void _showDatabaseInfo() async {
    try {
      final info = await _databaseHelper.getDatabaseInfo();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Database Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Version: ${info['version'] ?? 'Unknown'}'),
              const SizedBox(height: 8),
              Text('Printers Count: ${info['printersCount'] ?? 0}'),
              const SizedBox(height: 8),
              Text('Path: ${info['path'] ?? 'Unknown'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to get database info');
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Bambulab Controller',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.print, size: 48),
      children: [
        const Text(
            'A Flutter app for controlling Bambu Lab 3D printers with SQLite database storage.'),
      ],
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
