import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/printer.dart';
import '../providers/printer_provider.dart';
import '../services/database_helper.dart';
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
                              return ListTile(
                                title: Text(printer.name),
                                subtitle: Text(printer.ipAddress),
                                trailing: PopupMenuButton(
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
                                onTap: () => _connectToPrinter(printer),
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

  @override
  void initState() {
    super.initState();
    _loadPrinters();
    _loadTemplates();
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
                // Template selection dropdown
                if (_templates.isNotEmpty) ...<Widget>[
                  DropdownButtonFormField<PrinterTemplate>(
                    value: selectedTemplate,
                    decoration: const InputDecoration(
                      labelText: 'Use Template (Optional)',
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
                        if (template != null) {
                          nameController.text = template.printerName ?? '';
                          ipController.text = template.ipAddress ?? '';
                          portController.text =
                              template.port?.toString() ?? '8883';
                          accessCodeController.text = template.accessCode ?? '';
                          modelController.text = template.model ?? '';
                          deviceIDController.text = template.deviceID ?? '';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],

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

  void _connectToPrinter(Printer printer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrinterControlScreen(printer: printer),
      ),
    );
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
