class Printer {
  final String id;
  final String name;
  final String ipAddress;
  final int port;
  final String accessCode;
  final bool isOnline;
  final String? model;
  final String? status;
  final String? deviceID;
  final DateTime? lastSeen;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Additional properties from flask_app.py
  final double nozzleTemper;
  final double bedTemper;
  final int mcPercent;
  final int mcRemainingTime;
  final String printerStatus;
  final bool isPin; // New property for pinning functionality
  // Device subproperties

  Printer({
    required this.id,
    required this.name,
    required this.ipAddress,
    this.port = 8883,
    required this.accessCode,
    this.isOnline = false,
    this.model,
    this.status,
    this.deviceID,
    this.lastSeen,
    this.createdAt,
    this.updatedAt,
    this.nozzleTemper = 0.0,
    this.bedTemper = 0.0,
    this.mcPercent = 0,
    this.mcRemainingTime = 0,
    this.printerStatus = 'Unknown',
    this.isPin = false, // Default to false
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ipAddress': ipAddress,
      'port': port,
      'accessCode': accessCode,
      'isOnline': isOnline,
      'model': model,
      'status': status,
      'deviceID': deviceID,
      'lastSeen': lastSeen?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isPin': isPin, // Include in JSON serialization
      // 'nozzleTemper': nozzleTemper,
      // 'bedTemper': bedTemper,
      // 'mcPercent': mcPercent,
      // 'mcRemainingTime': mcRemainingTime,
      // 'printerStatus': printerStatus,
    };
  }

  factory Printer.fromJson(Map<String, dynamic> json) {
    return Printer(
      id: json['id'],
      name: json['name'],
      ipAddress: json['ipAddress'],
      port: json['port'] ?? 8883,
      accessCode: json['accessCode'],
      isOnline: json['isOnline'] ?? false,
      model: json['model'],
      status: json['status'],
      deviceID: json['deviceID'],
      lastSeen:
          json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      nozzleTemper: (json['nozzleTemper'] ?? 0).toDouble(),
      bedTemper: (json['bedTemper'] ?? 0).toDouble(),
      mcPercent: json['mcPercent'] ?? 0,
      mcRemainingTime: json['mcRemainingTime'] ?? 0,
      printerStatus: json['printerStatus'] ?? 'Unknown',
      isPin: json['isPin'] ?? false, // Handle isPin from JSON
    );
  }

  Printer copyWith({
    String? id,
    String? name,
    String? ipAddress,
    int? port,
    String? accessCode,
    bool? isOnline,
    String? model,
    String? status,
    String? deviceID,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? nozzleTemper,
    double? bedTemper,
    int? mcPercent,
    int? mcRemainingTime,
    String? printerStatus,
    bool? isPin, // Add isPin to copyWith method
  }) {
    return Printer(
      id: id ?? this.id,
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      accessCode: accessCode ?? this.accessCode,
      isOnline: isOnline ?? this.isOnline,
      model: model ?? this.model,
      status: status ?? this.status,
      deviceID: deviceID ?? this.deviceID,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nozzleTemper: nozzleTemper ?? this.nozzleTemper,
      bedTemper: bedTemper ?? this.bedTemper,
      mcPercent: mcPercent ?? this.mcPercent,
      mcRemainingTime: mcRemainingTime ?? this.mcRemainingTime,
      printerStatus: printerStatus ?? this.printerStatus,
      isPin: isPin ?? this.isPin, // Include isPin in copyWith
    );
  }

  @override
  String toString() {
    return 'Printer{id: $id, name: $name, ipAddress: $ipAddress, deviceID: $deviceID, isOnline: $isOnline, isPin: $isPin}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Printer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Utility getters
  String get displayStatus {
    if (!isOnline) return 'Offline';
    return status ?? 'Online';
  }

  String get lastSeenFormatted {
    if (lastSeen == null) return 'Never';
    final now = DateTime.now();
    final difference = now.difference(lastSeen!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
