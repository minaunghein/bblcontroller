import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _autoConnect = false;
  double _refreshInterval = 5.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(
                'Appearance',
                [
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Use dark theme'),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.setTheme(value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Connection',
                [
                  SwitchListTile(
                    title: const Text('Auto Connect'),
                    subtitle: const Text(
                        'Automatically connect to last used printer'),
                    value: _autoConnect,
                    onChanged: (value) {
                      setState(() {
                        _autoConnect = value;
                      });
                    },
                  ),
                  ListTile(
                    title: const Text('Refresh Interval'),
                    subtitle: Text('${_refreshInterval.toInt()} seconds'),
                    trailing: SizedBox(
                      width: 150,
                      child: Slider(
                        value: _refreshInterval,
                        min: 1.0,
                        max: 30.0,
                        divisions: 29,
                        onChanged: (value) {
                          setState(() {
                            _refreshInterval = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Notifications',
                [
                  SwitchListTile(
                    title: const Text('Enable Notifications'),
                    subtitle: const Text('Receive print status notifications'),
                    value: _notifications,
                    onChanged: (value) {
                      setState(() {
                        _notifications = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                'About',
                [
                  ListTile(
                    title: const Text('Version'),
                    subtitle: const Text('1.0.0'),
                    trailing: const Icon(Icons.info_outline),
                  ),
                  ListTile(
                    title: const Text('Licenses'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      showLicensePage(context: context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Data',
                [
                  ListTile(
                    title: const Text('Clear Cache'),
                    subtitle: const Text('Clear app cache and temporary data'),
                    trailing: const Icon(Icons.clear),
                    onTap: _clearCache,
                  ),
                  ListTile(
                    title: const Text('Reset Settings'),
                    subtitle: const Text('Reset all settings to default'),
                    trailing: const Icon(Icons.restore),
                    onTap: _resetSettings,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear the app cache?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
            'Are you sure you want to reset all settings to default?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                Provider.of<ThemeProvider>(context, listen: false)
                    .setTheme(true);
                _notifications = true;
                _autoConnect = false;
                _refreshInterval = 5.0;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to default')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
