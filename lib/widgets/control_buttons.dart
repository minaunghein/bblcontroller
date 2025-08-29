import 'package:flutter/material.dart';
import '../providers/printer_provider.dart';

class ControlButtons extends StatelessWidget {
  final PrinterProvider provider;

  const ControlButtons({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildControlButton(
          'Pause Print',
          Colors.red,
          () async {
            await provider.pausePrint();
          },
        ),
        const SizedBox(height: 15),
        _buildControlButton(
          'LED On',
          Colors.green,
          () async {
            await provider.ledOn();
          },
        ),
        const SizedBox(height: 15),
        _buildControlButton(
          'LED Off',
          Colors.green,
          () async {
            await provider.ledOff();
          },
        ),
        const SizedBox(height: 15),
        _buildControlButton(
          'Cool Nozzle',
          Colors.blue,
          () async {
            await provider.cooldownNozzle();
          },
        ),
        const SizedBox(height: 15),
        _buildControlButton(
          'Cool Bed',
          Colors.blue,
          () async {
            await provider.cooldownBed();
          },
        ),
        const SizedBox(height: 15),
        _buildControlButton(
          'Clean Nozzle',
          Colors.orange,
          () async {
            await provider.cleanNozzle();
          },
        ),
      ],
    );
  }

  Widget _buildControlButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 4,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
