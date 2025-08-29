import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/printer.dart';
import 'database_helper.dart';

class PrinterConnectivityService {
  static final PrinterConnectivityService _instance =
      PrinterConnectivityService._internal();
  factory PrinterConnectivityService() => _instance;
  PrinterConnectivityService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final Map<String, MqttServerClient> _clients = {};
  final Map<String, Timer> _heartbeatTimers = {};
  final Map<String, bool> _connectionStates = {};

  Function(String printerId, bool isOnline)? onPrinterStatusChanged;

  Future<void> startMonitoring(List<Printer> printers) async {
    for (final printer in printers) {
      await _connectToPrinter(printer);
    }
  }

  Future<void> _connectToPrinter(Printer printer) async {
    if (_clients.containsKey(printer.id)) {
      await _disconnectPrinter(printer.id);
    }

    try {
      final clientId =
          'bbl_monitor_${printer.id}_${DateTime.now().millisecondsSinceEpoch}';
      final client = MqttServerClient(printer.ipAddress, clientId);

      client.port = printer.port;
      client.secure = printer.port == 8883;
      client.connectTimeoutPeriod = 5000;
      client.keepAlivePeriod = 30;
      client.autoReconnect = false;
      client.logging(on: false);

      if (client.secure) {
        client.onBadCertificate = (Object certificate) => true;
      }

      client.onConnected = () {
        print('✅ Printer ${printer.name} connected');
        _updatePrinterStatus(printer.id, true);
        _startHeartbeat(printer);
      };

      client.onDisconnected = () {
        print('❌ Printer ${printer.name} disconnected');
        _updatePrinterStatus(printer.id, false);
        _stopHeartbeat(printer.id);
      };

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs('bblp', printer.accessCode)
          .startClean()
          .withWillQos(MqttQos.atMostOnce);

      client.connectionMessage = connMessage;

      _clients[printer.id] = client;
      await client.connect();
    } catch (e) {
      print('❌ Failed to connect to printer ${printer.name}: $e');
      _updatePrinterStatus(printer.id, false);
    }
  }

  void _startHeartbeat(Printer printer) {
    _heartbeatTimers[printer.id]?.cancel();
    _heartbeatTimers[printer.id] =
        Timer.periodic(Duration(seconds: 30), (timer) {
      final client = _clients[printer.id];
      if (client?.connectionStatus?.state != MqttConnectionState.connected) {
        _updatePrinterStatus(printer.id, false);
        timer.cancel();
      }
    });
  }

  void _stopHeartbeat(String printerId) {
    _heartbeatTimers[printerId]?.cancel();
    _heartbeatTimers.remove(printerId);
  }

  void _updatePrinterStatus(String printerId, bool isOnline) {
    if (_connectionStates[printerId] != isOnline) {
      _connectionStates[printerId] = isOnline;
      _databaseHelper.updatePrinterStatus(printerId, isOnline);
      onPrinterStatusChanged?.call(printerId, isOnline);
    }
  }

  bool isPrinterOnline(String printerId) {
    return _connectionStates[printerId] ?? false;
  }

  Future<void> _disconnectPrinter(String printerId) async {
    _stopHeartbeat(printerId);
    final client = _clients[printerId];
    if (client != null) {
      client.disconnect();
      _clients.remove(printerId);
    }
    _updatePrinterStatus(printerId, false);
  }

  Future<void> stopMonitoring() async {
    for (final printerId in _clients.keys.toList()) {
      await _disconnectPrinter(printerId);
    }
  }

  void dispose() {
    stopMonitoring();
  }
  // Add this public method to allow manual connection to a specific printer
  Future<bool> connectToPrinter(Printer printer) async {
    try {
      await _connectToPrinter(printer);
      // Wait a moment for connection to establish
      await Future.delayed(const Duration(seconds: 2));
      return isPrinterOnline(printer.id);
    } catch (e) {
      print('Failed to connect to printer ${printer.name}: $e');
      return false;
    }
  }
}
