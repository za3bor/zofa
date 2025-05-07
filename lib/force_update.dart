import 'dart:io';
import 'package:zofa/constant.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateWrapper extends StatefulWidget {
  const ForceUpdateWrapper({required this.child, super.key});
  final Widget child;

  @override
  State<ForceUpdateWrapper> createState() => _ForceUpdateWrapperState();
}

class _ForceUpdateWrapperState extends State<ForceUpdateWrapper> {
  bool _shouldForceUpdate = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkAppVersion();
  }

  Future<void> _checkAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(
        Uri.parse('http://$ipAddress/api/checkVersion'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion =
            Platform.isAndroid
                ? data['latest_android_version']
                : data['latest_ios_version'];

        if (_isVersionLower(currentVersion, latestVersion)) {
          setState(() => _shouldForceUpdate = true);
        }
      }
    } catch (e) {
      print("Version check failed: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  bool _isVersionLower(String current, String latest) {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> latestParts = latest.split('.').map(int.parse).toList();
    final maxLength = [
      currentParts.length,
      latestParts.length,
    ].reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < maxLength; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      final latestPart = i < latestParts.length ? latestParts[i] : 0;
      if (currentPart < latestPart) return true;
      if (currentPart > latestPart) return false;
    }
    return false;
  }

  void _launchStore() {
    final url =
        Platform.isAndroid
            ? 'https://play.google.com/store/apps/details?id=com.zofa_client'
            : 'https://apps.apple.com/app/id6744275359';

    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_shouldForceUpdate) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'יש עדכון חדש. נא לעדכן כדי להמשיך.',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _launchStore,
                child: const Text('עדכן עכשיו'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}
