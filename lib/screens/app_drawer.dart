import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  // Helper method for phone dialing
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint('Could not launch phone dialer for $phoneNumber');
    }
  }

  // Helper method for opening Google Maps to find nearest outlets
  Future<void> _openNearestOutletsMap() async {
    final Uri mapUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=PryceGas+Outlet',
    );
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri, mode: LaunchMode.externalApplication);
    }
  }

  // 1. LPG Safety Rules & Tips Dialog
  void _showSafetyTipsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: PryceColors.primaryRed),
            SizedBox(width: 8),
            Text('LPG Safety Rules & Tips'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('• Store upright in a well-ventilated area.',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Text('• Keep away from electrical outlets, open flames, or heat sources.'),
              SizedBox(height: 10),
              Text('• Check hose & regulator regularly for cracks or leaks using soapy water.'),
              SizedBox(height: 10),
              Text('• If you smell gas:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              SizedBox(height: 4),
              Text('  1. Turn off cylinder valve.\n  2. Open doors and windows.\n  3. Do NOT flip switches or produce sparks.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: PryceColors.primaryRed)),
          ),
        ],
      ),
    );
  }

  // Updated Emergency Hotline Dialog showing PryceGas and BFP numbers
  void _showEmergencyHotlineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone_in_talk, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Emergency Hotlines'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'For urgent gas leaks, cylinder fire risks, or immediate assistance, contact the hotlines below:',
            ),
            const SizedBox(height: 16),
            
            // PryceGas Hotline Option
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: PryceColors.primaryRed),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PryceGas Hotline',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '#98000',
                          style: TextStyle(
                            color: PryceColors.primaryRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.call, color: PryceColors.primaryRed),
                    onPressed: () => _makePhoneCall('#98000'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // BFP Hotline Option
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_police, color: Colors.blue),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BFP (Fire Dept.)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '911',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.call, color: Colors.blue),
                    onPressed: () => _makePhoneCall('911'),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // 3. About PryceHatid Dialog
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'PryceHatid',
      applicationVersion: 'v1.0.0',
      applicationIcon: const Icon(
        Icons.local_fire_department,
        size: 48,
        color: PryceColors.primaryRed,
      ),
      children: [
        const SizedBox(height: 12),
        const Text(
          'PryceHatid provides fast, safe, and reliable PryceGas LPG cylinder ordering and delivery straight to your doorstep.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFFF4400)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.local_fire_department, size: 48, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'PryceHatid Services',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Quality & Safe LPG Delivery',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined, color: PryceColors.primaryRed),
            title: const Text('LPG Safety Rules & Tips'),
            subtitle: const Text('Proper storage & leak prevention'),
            onTap: () {
              Navigator.pop(context);
              _showSafetyTipsDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.store_outlined, color: PryceColors.secondaryNavy),
            title: const Text('Nearest PryceGas Outlets'),
            subtitle: const Text('Find local refilling stations'),
            onTap: () {
              Navigator.pop(context);
              _openNearestOutletsMap();
            },
          ),
          ListTile(
            leading: const Icon(Icons.phone_in_talk_outlined, color: Colors.redAccent),
            title: const Text('Emergency Hotline'),
            subtitle: const Text('Report gas leaks & urgent issues'),
            onTap: () {
              Navigator.pop(context);
              _showEmergencyHotlineDialog(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About PryceHatid'),
            trailing: const Text('v1.0.0', style: TextStyle(color: Colors.grey)),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }
}