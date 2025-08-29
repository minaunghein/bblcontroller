import 'package:bblmanager/models/printer.dart';

class PrinterData {
  final double nozzleTemper;
  final double bedTemper;
  final int mcPercent;
  final int mcRemainingTime;
  final String status;
  final String? lastUpdate;
  final Device? device;

  PrinterData({
    this.nozzleTemper = 0.0,
    this.bedTemper = 0.0,
    this.mcPercent = 0,
    this.mcRemainingTime = 0,
    this.status = 'Unknown',
    this.lastUpdate,
    this.device,
  });

  factory PrinterData.fromJson(Map<String, dynamic> json) {
    return PrinterData(
      nozzleTemper: (json['nozzle_temper'] ?? 0).toDouble(),
      bedTemper: (json['bed_temper'] ?? 0).toDouble(),
      mcPercent: json['mc_percent'] ?? 0,
      mcRemainingTime: json['mc_remaining_time'] ?? 0,
      status: json['status'] ?? 'Unknown',
      lastUpdate: json['last_update'],
      device: json['device'] != null ? Device.fromJson(json['device']) : null,
    );
  }

  PrinterData copyWith({
    double? nozzleTemper,
    double? bedTemper,
    int? mcPercent,
    int? mcRemainingTime,
    String? status,
    String? lastUpdate,
  }) {
    return PrinterData(
      nozzleTemper: nozzleTemper ?? this.nozzleTemper,
      bedTemper: bedTemper ?? this.bedTemper,
      mcPercent: mcPercent ?? this.mcPercent,
      mcRemainingTime: mcRemainingTime ?? this.mcRemainingTime,
      status: status ?? this.status,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}
