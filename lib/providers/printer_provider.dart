import 'package:flutter/foundation.dart';
import '../models/printer_data.dart';
import '../services/mqtt_service.dart';

class PrinterProvider with ChangeNotifier {
  final MqttService _mqttService = MqttService();
  PrinterData _printerData = PrinterData();
  bool _isConnected = false;
  String _lastUpdate = 'Never';

  PrinterData get printerData => _printerData;
  bool get isConnected => _isConnected;
  String get lastUpdate => _lastUpdate;

  PrinterProvider() {
    _mqttService.onDataReceived = _updatePrinterData;
    _mqttService.onConnectionChanged = _updateConnectionStatus;
    // Remove auto-connect, let user manually connect
    // _connectToMqtt();
  }

  // Add public connect method
  Future<void> connect() async {
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

  void _updatePrinterData(PrinterData data) {
    _printerData = data;
    _lastUpdate = DateTime.now().toString().substring(11, 19);
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
