import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/printer_data.dart';
import '../models/printer.dart';

class MqttService {
  // Remove static const values and make them instance variables
  String? _printerIp;
  String? _accessCode;
  String? _deviceId;
  int _port = 8883;

  MqttServerClient? _client;
  Function(PrinterData)? onDataReceived;
  Function(bool)? onConnectionChanged;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 3;
  bool _isConnecting = false;

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  // Add method to configure printer connection details
  void configurePrinter(Printer printer) {
    _printerIp = printer.ipAddress;
    _accessCode = printer.accessCode;
    _deviceId = printer.deviceID;
    _port = printer.port;
  }

  Future<bool> connect() async {
    if (_printerIp == null || _accessCode == null) {
      print('Printer not configured. Call configurePrinter() first.');
      return false;
    }

    if (_isConnecting) {
      print('Connection already in progress, skipping...');
      return false;
    }

    _isConnecting = true;

    try {
      // Clean up any existing connection first
      await _cleanupConnection();

      // Try secure connection first (port 8883)
      bool connected = await _attemptConnection(8883, true);

      if (!connected) {
        print('Secure connection failed, trying insecure connection...');
        await _cleanupConnection();
        // Fallback to insecure connection (port 1883)
        connected = await _attemptConnection(8883, true);
      }

      _isConnecting = false;
      return connected;
    } catch (e) {
      print('MQTT connection error: $e');
      _isConnecting = false;
      return false;
    }
  }

  Future<void> _cleanupConnection() async {
    if (_client != null) {
      try {
        _client!.disconnect();
        await Future.delayed(Duration(milliseconds: 500)); // Wait for cleanup
      } catch (e) {
        print('Error during cleanup: $e');
      }
      _client = null;
    }
  }

  Future<bool> _attemptConnection(int port, bool secure) async {
    try {
      final clientId = 'bbl_flutter_${DateTime.now().millisecondsSinceEpoch}';

      print('Creating MQTT client for $_printerIp:$port (secure: $secure)');
      _client = MqttServerClient(_printerIp ?? "", clientId);

      // Essential configuration
      _client!.port = port;
      _client!.secure = secure;
      _client!.logging(on: false); // Disable verbose logging
      _client!.connectTimeoutPeriod = 8000; // 8 second timeout
      _client!.keepAlivePeriod = 10;
      _client!.autoReconnect = true; // Handle reconnection manually

      // Set socket options to prevent connection issues
      _client!.setProtocolV311();

      if (secure) {
        _client!.securityContext = SecurityContext.defaultContext;
        _client!.onBadCertificate = (Object certificate) => true;
      }

      // Set up event handlers
      _client!.onConnected = () {
        print('✅ MQTT Connected successfully to $_printerIp:$port');
        _reconnectAttempts = 0;
        onConnectionChanged?.call(true);
        _subscribeToReports();
      };

      _client!.onDisconnected = () {
        print('❌ MQTT Disconnected from $_printerIp:$port');
        onConnectionChanged?.call(false);
        if (_reconnectAttempts < maxReconnectAttempts && !_isConnecting) {
          _scheduleReconnect();
        }
      };

      _client!.onSubscribed = (String topic) {
        print('📡 Subscribed to topic: $topic');
      };

      // Create connection message
      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs('bblp', _accessCode)
          .startClean()
          .withWillQos(MqttQos.atMostOnce);

      _client!.connectionMessage = connMessage;

      print('🔄 Attempting connection to $_printerIp:$port...');
      await _client!.connect();

      // Verify connection
      if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
        _setupMessageListener();
        return true;
      } else {
        print(
            '❌ Connection failed - Status: ${_client!.connectionStatus?.state}');
        return false;
      }
    } catch (e) {
      print('❌ Connection attempt failed on $_printerIp:$port: $e');
      await _cleanupConnection();
      return false;
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      print('Max reconnection attempts reached. Stopping reconnection.');
      return;
    }

    _reconnectTimer?.cancel();
    final delay =
        Duration(seconds: (3 * (_reconnectAttempts + 1)).clamp(3, 30));
    _reconnectAttempts++;

    print(
        '⏰ Scheduling reconnection attempt $_reconnectAttempts in ${delay.inSeconds} seconds');

    _reconnectTimer = Timer(delay, () {
      if (!isConnected && !_isConnecting) {
        connect();
      }
    });
  }

  void _subscribeToReports() {
    final topic = 'device/$_deviceId/report';
    print('📡 Subscribing to topic: $topic');
    _client!.subscribe(topic, MqttQos.atMostOnce);
  }

  void _setupMessageListener() {
    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);

      try {
        final data = json.decode(payload);
        print('Received MQTT message: $data');

        // Enhanced message handling based on flask_app.py
        if (data['print'] != null) {
          final printData = data['print'];

          // Create PrinterData with enhanced properties
          final printerData = PrinterData(
            nozzleTemper: (printData['nozzle_temper'] ?? 0).toDouble(),
            bedTemper: (printData['bed_temper'] ?? 0).toDouble(),
            mcPercent: printData['mc_percent'] ?? 0,
            mcRemainingTime:
                _parseRemainingTime(printData['mc_remaining_time']),
            status: printData['gcode_state'] ?? 'Unknown',
            lastUpdate: data['timestamp'] ?? DateTime.now().toIso8601String(),
            device: printData['device'] != null
                ? Device.fromJson(printData['device'])
                : null,
          );

          print(
              'Parsed printer data: nozzle=${printerData.nozzleTemper}, bed=${printerData.bedTemper}, progress=${printerData.mcPercent}%, status=${printerData.status}');
          onDataReceived?.call(printerData);
        }
      } catch (e) {
        print('Error parsing MQTT message: $e');
      }
    });
  }

  // Helper method to parse remaining time similar to flask_app.py
  int _parseRemainingTime(dynamic rawTime) {
    if (rawTime == null) return 0;

    try {
      return int.parse(rawTime.toString());
    } catch (e) {
      print('Failed to convert mc_remaining_time: $rawTime');
      return 0;
    }
  }

  Future<bool> sendCommand(Map<String, dynamic> command) async {
    if (!isConnected) {
      print('❌ Cannot send command - MQTT not connected');
      return false;
    }

    try {
      final topic = 'device/$_deviceId/request';
      final message = json.encode(command);

      final builder = MqttClientPayloadBuilder();
      builder.addString(message);

      _client!.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
      print('📤 Command sent: ${command.keys.first}');
      return true;
    } catch (e) {
      print('❌ Error sending command: $e');
      return false;
    }
  }

  Future<bool> pausePrint() async {
    final command = {
      "print": {
        "command": "print",
        "param": "PAUSE",
        "sequence_id": DateTime.now().millisecondsSinceEpoch.toString()
      }
    };
    return await sendCommand(command);
  }

  Future<bool> ledControl(String mode) async {
    final command = {
      "system": {
        "command": "ledctrl",
        "sequence_id": DateTime.now().millisecondsSinceEpoch.toString(),
        "led_mode": mode
      }
    };
    return await sendCommand(command);
  }

  Future<bool> homeCommand() async {
    final command = {
      "print": {
        "command": "gcode_line",
        "param": "G28 \n",
        "sequence_id": DateTime.now().millisecondsSinceEpoch.toString()
      }
    };
    return await sendCommand(command);
  }

  Future<bool> cooldownNozzle() async {
    final command = {
      "print": {
        "command": "gcode_line",
        "param": "M104 S0\n",
        "sequence_id": DateTime.now().millisecondsSinceEpoch.toString()
      }
    };
    return await sendCommand(command);
  }

  Future<bool> cooldownBed() async {
    final command = {
      "print": {
        "command": "gcode_line",
        "param": "M140 S0\n",
        "sequence_id": DateTime.now().millisecondsSinceEpoch.toString()
      }
    };
    return await sendCommand(command);
  }

  Future<bool> cleanNozzle() async {
    final command = {
      "print": {
        "command": "gcode_line",
        "param":
            "G92 E0\nG1 E-0.5 F300\nG1 X60 Y265 F15000\nG1 X100 F5000\nG1 X70 F15000\nG1 X100 F5000\nG1 X70 F15000\nG1 X100 F5000\nG1 X70 F15000\n",
        "sequence_id": DateTime.now().millisecondsSinceEpoch.toString()
      }
    };
    return await sendCommand(command);
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectAttempts = maxReconnectAttempts; // Prevent auto-reconnect
    _client?.disconnect();
  }

  void dispose() {
    disconnect();
    _client = null;
  }
}
