import 'package:flutter/foundation.dart';
import '../models/printer_data.dart';
import '../models/printer.dart';
import '../services/mqtt_service.dart';
import '../services/database_helper.dart';

class PrinterProvider with ChangeNotifier {
  final MqttService _mqttService = MqttService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  PrinterData _printerData = PrinterData();
  bool _isConnected = false;
  String _lastUpdate = 'Never';
  Printer? _currentPrinter;
  List<Printer> _allPrinters = [];

  PrinterData get printerData => _printerData;
  bool get isConnected => _isConnected;
  String get lastUpdate => _lastUpdate;
  Printer? get currentPrinter => _currentPrinter;
  List<Printer> get allPrinters => _allPrinters;

  PrinterProvider() {
    _mqttService.onDataReceived = _updatePrinterData;
    _mqttService.onConnectionChanged = _updateConnectionStatus;
  }

  // Add method to load all printers
  Future<void> loadAllPrinters() async {
    try {
      _allPrinters = await _databaseHelper.getAllPrinters();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load printers: $e');
      }
    }
  }

  // Add method to get pinned printer
  Future<Printer?> getPinnedPrinter() async {
    try {
      return await _databaseHelper.getPinnedPrinter();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get pinned printer: $e');
      }
      return null;
    }
  }

  // Add setPrinter method to configure the current printer
  void setPrinter(Printer printer) {
    // Disconnect from current printer if connected
    //if (_isConnected) {
    //  disconnect();
    //}

    _currentPrinter = printer;
    _mqttService.configurePrinter(printer);
    notifyListeners();
  }

  // Add public connect method
  Future<void> connect() async {
    if (_currentPrinter == null) {
      if (kDebugMode) {
        print('No printer selected. Call setPrinter() first.');
      }
      return;
    }

    try {
      await _mqttService.connect();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to connect: $e');
      }
    }
  }

  // Add public disconnect method
  Future<void> disconnect() async {
    try {
      _mqttService
          .disconnect(); // Remove 'await' since disconnect() is not async
    } catch (e) {
      if (kDebugMode) {
        print('Failed to disconnect: $e');
      }
    }
  }

  Future<void> _connectToMqtt() async {
    await _mqttService.connect();
  }

  void _updatePrinterData(PrinterData data) async {
    _printerData = data;
    _lastUpdate = DateTime.now().toString().substring(11, 19);

    // Update current printer with real-time data if available

    _currentPrinter = _currentPrinter!.copyWith(
      nozzleTemper: data.nozzleTemper,
      bedTemper: data.bedTemper,
      mcPercent: data.mcPercent,
      mcRemainingTime: data.mcRemainingTime,
      printerStatus: data.status,
    );

    // Update database with new device information if device data was received

    notifyListeners();
  }

  void _updateConnectionStatus(bool connected) {
    _isConnected = connected;
    notifyListeners();
  }

  Future<bool> pausePrint() => _mqttService.pausePrint();
  Future<bool> ledOn() => _mqttService.ledControl('on');
  Future<bool> ledOff() => _mqttService.ledControl('off');
  Future<bool> homeCommand() => _mqttService.homeCommand();
  Future<bool> cooldownNozzle() => _mqttService.cooldownNozzle();
  Future<bool> cooldownBed() => _mqttService.cooldownBed();
  Future<bool> cleanNozzle() => _mqttService.cleanNozzle();

  @override
  void dispose() {
    _mqttService.disconnect();
    super.dispose();
  }
}
