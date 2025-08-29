import 'package:flutter/material.dart';

class TemperatureCard extends StatelessWidget {
  final IconData icon; // Change from String to IconData
  final String title;
  final double temperature;
  final double target;
  final bool isActive;

  const TemperatureCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.temperature,
    required this.target,
    required this.isActive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.orange : Colors.grey.shade700,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? Colors.orange : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
