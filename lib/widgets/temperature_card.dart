import 'package:flutter/material.dart';

class TemperatureCard extends StatelessWidget {
  final IconData icon;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: isActive ? Colors.orange : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : Colors.grey.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${temperature.toStringAsFixed(1)}°C',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.orange : Colors.white,
                ),
              ),
              if (target > 0)
                Text(
                  '/${target.toStringAsFixed(0)}°C',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade400,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
