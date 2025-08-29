class PrinterTemplate {
  final String? id;
  final String name;
  final String? printerName;
  final String? ipAddress;
  final int? port;
  final String? accessCode;
  final String? model;
  final String? deviceID;
  final DateTime createdAt;
  final DateTime updatedAt;

  PrinterTemplate({
    this.id,
    required this.name,
    this.printerName,
    this.ipAddress,
    this.port,
    this.accessCode,
    this.model,
    this.deviceID,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'printerName': printerName,
      'ipAddress': ipAddress,
      'port': port,
      'accessCode': accessCode,
      'model': model,
      'deviceID': deviceID,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PrinterTemplate.fromJson(Map<String, dynamic> json) {
    return PrinterTemplate(
      id: json['id'],
      name: json['name'] ?? '',
      printerName: json['printerName'],
      ipAddress: json['ipAddress'],
      port: json['port'],
      accessCode: json['accessCode'],
      model: json['model'],
      deviceID: json['deviceID'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  PrinterTemplate copyWith({
    String? id,
    String? name,
    String? printerName,
    String? ipAddress,
    int? port,
    String? accessCode,
    String? model,
    String? deviceID,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrinterTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      printerName: printerName ?? this.printerName,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      accessCode: accessCode ?? this.accessCode,
      model: model ?? this.model,
      deviceID: deviceID ?? this.deviceID,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PrinterTemplate{id: $id, name: $name, printerName: $printerName, ipAddress: $ipAddress, port: $port, accessCode: $accessCode, model: $model, deviceID: $deviceID, createdAt: $createdAt, updatedAt: $updatedAt}';
  }
}
