import 'package:flutter/material.dart';
import '../providers/printer_provider.dart';

class DirectionalControl extends StatelessWidget {
  final PrinterProvider provider;

  const DirectionalControl({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Circular background
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    colors: [
                      Color(0xFF444444),
                      Color(0xFF666666),
                      Color(0xFF444444)
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 50,
                      spreadRadius: 0,
                      //inset: true,
                    ),
                  ],
                ),
              ),
              // Home button
              GestureDetector(
                onTap: () async {
                  await provider.homeCommand();
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                  child: const Icon(
                    Icons.home,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              // Direction buttons
              Positioned(
                top: -20,
                child: _buildDirectionButton('Y', () {}),
              ),
              Positioned(
                bottom: -20,
                child: _buildDirectionButton('-Y', () {}),
              ),
              Positioned(
                right: -40,
                child: _buildDirectionButton('X', () {}),
              ),
              Positioned(
                left: -40,
                child: _buildDirectionButton('-X', () {}),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        // Bed controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBedButton('⬆️ 10', () {}),
            const SizedBox(width: 15),
            _buildBedButton('⬆️ 1', () {}),
            const SizedBox(width: 15),
            const Text(
              'Bed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 15),
            _buildBedButton('⬇️ 1', () {}),
            const SizedBox(width: 15),
            _buildBedButton('⬇️ 10', () {}),
          ],
        ),
      ],
    );
  }

  Widget _buildDirectionButton(String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 80,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBedButton(String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
