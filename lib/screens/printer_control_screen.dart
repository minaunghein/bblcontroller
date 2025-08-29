import 'package:bblmanager/models/printer.dart';
import 'package:bblmanager/widgets/temperature_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/printer_provider.dart';
import '../widgets/directional_control.dart';
import '../widgets/control_buttons.dart';

class PrinterControlScreen extends StatefulWidget {
  final Printer? printer;

  const PrinterControlScreen({super.key, this.printer});

  @override
  State<PrinterControlScreen> createState() => _PrinterControlScreenState();
}

class _PrinterControlScreenState extends State<PrinterControlScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.printer?.name ?? 'Printer Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to printer-specific settings if needed
            },
          ),
        ],
        centerTitle: true,
      ),
      // actions: [
      //   Consumer<PrinterProvider>(
      //     builder: (context, provider, child) {
      //       return Padding(
      //           padding: const EdgeInsets.only(right: 16.0),
      //           child: ElevatedButton.icon(
      //             onPressed: () {
      //               if (provider.isConnected) {
      //                 //provider.disconnect();
      //               } else {
      //                 provider.connect();
      //               }
      //             },
      //             icon: Icon(
      //               provider.isConnected ? Icons.wifi_off : Icons.wifi,
      //               size: 18,
      //             ),
      //             label: Text(
      //               provider.isConnected ? 'Disconnect' : 'Connect',
      //               style: const TextStyle(fontSize: 12),
      //             ),
      //             style: ElevatedButton.styleFrom(
      //               backgroundColor: provider.isConnected
      //                   ? Colors.red.shade600
      //                   : Colors.green.shade600,
      //               foregroundColor: Colors.white,
      //               padding:
      //                   const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      //               shape: RoundedRectangleBorder(
      //                 borderRadius: BorderRadius.circular(20),
      //               ),
      //             ),
      //           ));
      //     },
      //   ),
      // ],
      body: Consumer<PrinterProvider>(
        builder: (context, provider, child) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1e1e1e), Color(0xFF2d2d2d)],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    // Tablet/Desktop layout
                    return Row(
                      children: [
                        // Left Panel - Temperature
                        Expanded(
                          flex: 1,
                          child: _buildLeftPanel(provider),
                        ),
                        // Center Panel - Controls
                        Expanded(
                          flex: 2,
                          child: _buildCenterPanel(provider),
                        ),
                        // Right Panel - Buttons
                        Expanded(
                          flex: 1,
                          child: _buildRightPanel(provider),
                        ),
                      ],
                    );
                  } else {
                    // Mobile layout
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildTemperatureRow(provider),
                          const SizedBox(height: 20),
                          DirectionalControl(provider: provider),
                          const SizedBox(height: 20),
                          ControlButtons(provider: provider),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<PrinterProvider>(
        builder: (context, provider, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      provider.isConnected ? Icons.wifi : Icons.wifi_off,
                      color: provider.isConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      provider.isConnected ? 'Connected' : 'Disconnected',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                Text(
                  'Last update: ${provider.lastUpdate}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeftPanel(PrinterProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TemperatureCard(
            icon: Icons.thermostat,
            title: 'Nozzle',
            temperature: provider.printerData.nozzleTemper,
            target: 0,
            isActive: provider.printerData.nozzleTemper > 0,
          ),
          const SizedBox(height: 16),
          TemperatureCard(
            icon: Icons.thermostat,
            title: 'Bed',
            temperature: provider.printerData.bedTemper,
            target: 0,
            isActive: provider.printerData.bedTemper > 0,
          ),
          const SizedBox(height: 16),
          const TemperatureCard(
            icon: Icons.thermostat,
            title: 'Chamber',
            temperature: 0,
            target: 0,
            isActive: false,
          ),
          const SizedBox(height: 16),
          _buildFanControl(),
        ],
      ),
    );
  }

  Widget _buildCenterPanel(PrinterProvider provider) {
    return Center(
      child: DirectionalControl(provider: provider),
    );
  }

  Widget _buildRightPanel(PrinterProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildExtruderControl(),
          const SizedBox(height: 20),
          _buildLampControl(),
          const SizedBox(height: 20),
          ControlButtons(provider: provider),
        ],
      ),
    );
  }

  Widget _buildTemperatureRow(PrinterProvider provider) {
    return Row(
      children: [
        Expanded(
          child: TemperatureCard(
            icon: Icons.thermostat,
            title: 'Nozzle',
            temperature: provider.printerData.nozzleTemper,
            target: 0,
            isActive: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TemperatureCard(
            icon: Icons.thermostat,
            title: 'Bed',
            temperature: provider.printerData.bedTemper,
            target: 0,
            isActive: true,
          ),
        ),
      ],
    );
  }

  Widget _buildFanControl() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: const Column(
        children: [
          Text('💨', style: TextStyle(fontSize: 32)),
          SizedBox(height: 8),
          Text('Fan', style: TextStyle(color: Colors.white)),
          SizedBox(height: 4),
          Text('100%',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildExtruderControl() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text('Extruder',
              style: TextStyle(color: Colors.grey, fontSize: 18)),
          const SizedBox(height: 20),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.keyboard_arrow_up,
                color: Colors.white, size: 30),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              shape: const CircleBorder(),
            ),
          ),
          const SizedBox(height: 10),
          const Icon(Icons.circle, color: Colors.green, size: 24),
          const SizedBox(height: 10),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.keyboard_arrow_down,
                color: Colors.white, size: 30),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLampControl() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: const Column(
        children: [
          Text('💡', style: TextStyle(fontSize: 32)),
          SizedBox(height: 8),
          Text('Lamp',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
