import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/printer.dart';
import '../providers/printer_provider.dart';
import '../services/database_helper.dart';
import '../services/printer_connectivity_service.dart';
import 'printer_control_screen.dart';
import 'settings_screen.dart';
import '../models/printer_template.dart';

class PrintersListScreen extends StatefulWidget {
  const PrintersListScreen({Key? key}) : super(key: key);

  @override
  State<PrintersListScreen> createState() => _PrintersListScreenState();
}

class _PrintersListScreenState extends State<PrintersListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPrinters,
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
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Database Info'),
                onTap: () => _showDatabaseInfo(),
              ),
              PopupMenuItem(
                child: const Text('About'),
                onTap: () => _showAboutDialog(),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
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
                        : ListView.builder(
                            itemCount: _filteredPrinters.length,
                            itemBuilder: (context, index) {
                              final printer = _filteredPrinters[index];
                              final isOnline = _connectivityService
                                  .isPrinterOnline(printer.id);

                              return ListTile(
                                leading: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isOnline ? Colors.green : Colors.red,
                                  ),
                                ),
                                title: Text(printer.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(printer.ipAddress),
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
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isOnline ? Icons.wifi : Icons.wifi_off,
                                      color:
                                          isOnline ? Colors.green : Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    PopupMenuButton(
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          child: const Text('Edit'),
                                          onTap: () => _editPrinter(printer),
                                        ),
                                        PopupMenuItem(
                                          child: const Text('Delete'),
                                          onTap: () => _deletePrinter(printer),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () => _connectToPrinter(
                                    printer, printer.isOnline),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPrinterDialog,
        child: const Icon(Icons.add),
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

  @override
  void initState() {
    super.initState();
    _loadPrinters();
    _loadTemplates();
    _setupConnectivityService();
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
    final nameController = TextEditingController();
    final ipController = TextEditingController();
    final portController = TextEditingController(text: '8883');
    final accessCodeController = TextEditingController();
    final modelController = TextEditingController();
    final deviceIDController = TextEditingController();
    final templateNameController = TextEditingController();

    PrinterTemplate? selectedTemplate;
    bool saveAsTemplate = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Printer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Template selection section with enhanced UI
                if (_templates.isNotEmpty) ...<Widget>[
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<PrinterTemplate>(
                          value: selectedTemplate,
                          decoration: const InputDecoration(
                            labelText: 'Select Template',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<PrinterTemplate>(
                              value: null,
                              child: Text('None - Enter manually'),
                            ),
                            ..._templates.map((template) => DropdownMenuItem(
                                  value: template,
                                  child: Text(template.name),
                                )),
                          ],
                          onChanged: (template) {
                            setDialogState(() {
                              selectedTemplate = template;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: selectedTemplate != null
                            ? () {
                                setDialogState(() {
                                  if (selectedTemplate != null) {
                                    nameController.text =
                                        selectedTemplate!.printerName ?? '';
                                    ipController.text =
                                        selectedTemplate!.ipAddress ?? '';
                                    portController.text =
                                        selectedTemplate!.port?.toString() ??
                                            '8883';
                                    accessCodeController.text =
                                        selectedTemplate!.accessCode ?? '';
                                    modelController.text =
                                        selectedTemplate!.model ?? '';
                                    deviceIDController.text =
                                        selectedTemplate!.deviceID ?? '';

                                    // Show confirmation snackbar
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Template "${selectedTemplate!.name}" loaded successfully!'),
                                        backgroundColor: Colors.green,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                });
                              }
                            : null,
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Load'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (selectedTemplate != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade600, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Template "${selectedTemplate!.name}" selected. Click "Load" to fill the form.',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                ] else ...<Widget>[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: Colors.orange.shade600, size: 16),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'No templates available. Add a printer and save it as a template for future use.',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Clear form button
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            nameController.clear();
                            ipController.clear();
                            portController.text = '8883';
                            accessCodeController.clear();
                            modelController.clear();
                            deviceIDController.clear();
                            selectedTemplate = null;
                          });
                        },
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Clear Form'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Existing form fields
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Printer Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ipController,
                  decoration: const InputDecoration(
                    labelText: 'IP Address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: portController,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: accessCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Access Code',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: modelController,
                  decoration: const InputDecoration(
                    labelText: 'Model (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: deviceIDController,
                  decoration: const InputDecoration(
                    labelText: 'Device ID (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Save as template option
                CheckboxListTile(
                  title: const Text('Save as template'),
                  value: saveAsTemplate,
                  onChanged: (value) {
                    setDialogState(() {
                      saveAsTemplate = value ?? false;
                    });
                  },
                ),

                if (saveAsTemplate) ...<Widget>[
                  const SizedBox(height: 8),
                  TextField(
                    controller: templateNameController,
                    decoration: const InputDecoration(
                      labelText: 'Template Name',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Home Printer, Office Setup',
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    ipController.text.isNotEmpty &&
                    accessCodeController.text.isNotEmpty) {
                  // Save as template if requested
                  if (saveAsTemplate &&
                      templateNameController.text.isNotEmpty) {
                    final template = PrinterTemplate(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: templateNameController.text,
                      printerName: nameController.text,
                      ipAddress: ipController.text,
                      port: int.tryParse(portController.text) ?? 8883,
                      accessCode: accessCodeController.text,
                      model: modelController.text.isEmpty
                          ? null
                          : modelController.text,
                      deviceID: deviceIDController.text.isEmpty
                          ? null
                          : deviceIDController.text,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    await _databaseHelper.insertTemplate(template);
                    await _loadTemplates();
                  }

                  // Add the printer
                  await _addPrinter(
                    nameController.text,
                    ipController.text,
                    int.tryParse(portController.text) ?? 8883,
                    accessCodeController.text,
                    modelController.text.isEmpty ? null : modelController.text,
                    deviceIDController.text.isEmpty
                        ? null
                        : deviceIDController.text,
                  );

                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPrinter(String name, String ip, int port, String accessCode,
      String? model, String? deviceID) async {
    try {
      final newPrinter = Printer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        ipAddress: ip,
        port: port,
        accessCode: accessCode,
        model: model,
        deviceID: deviceID,
      );

      final result = await _databaseHelper.insertPrinter(newPrinter);
      if (result > 0) {
        _showSuccessSnackBar('Printer added successfully');
        _loadPrinters();
      } else {
        _showErrorSnackBar('Failed to add printer');
      }
    } catch (e) {
      print('Error adding printer: $e');
      _showErrorSnackBar('Failed to add printer');
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                  labelText: 'Device ID (Optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(
                  labelText: 'Model (Optional)',
                ),
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

  void _connectToPrinter(Printer printer, bool isConnected) async {
    // Show loading indicator

    try {
      // Attempt to connect to the printer
      if (!isConnected) {
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

      if (isConnected) {
        // Show success message
        //_showSuccessSnackBar('Connected to ${printer.name} successfully!');

        // Connect to MQTT and start listening for printer data
        final printerProvider =
            Provider.of<PrinterProvider>(context, listen: false);
        printerProvider.setPrinter(printer);
        await printerProvider.connect();

        // Navigate to printer control screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PrinterControlScreen(printer: printer),
          ),
        );
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
