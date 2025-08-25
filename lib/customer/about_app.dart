import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zofa/constant.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  String? _appVersion;
  bool _versionLoadFailed = false;

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      final bool canLaunch = await canLaunchUrl(uri);
      final bool launched = await launchUrl(
        uri,
        mode: canLaunch ? LaunchMode.externalApplication : LaunchMode.platformDefault,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('לא ניתן לפתוח את הקישור')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('אירעה שגיאה בפתיחת הקישור')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
          _versionLoadFailed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _versionLoadFailed = true;
        });
      }
    }
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 24.w),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.right,
      ),
      onTap: onTap,
      trailing: trailing,
      visualDensity: VisualDensity.compact,
      dense: true,
      horizontalTitleGap: 8.w,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Replace with your actual URLs
    const String linkedinUrl = 'https://www.linkedin.com/in/fadi-srour';

    return Scaffold(
      appBar: const CustomAppBar(title: 'אודות האפליקציה'),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(16.0.w),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.asset(
                      'assets/background.jpg',
                      width: 64.w,
                      height: 64.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zofa Health Shop',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        SizedBox(height: 6.h),
                        if (_appVersion == null && !_versionLoadFailed)
                          Text('בודק גרסה...',
                              style: Theme.of(context).textTheme.bodyMedium)
                        else if (_versionLoadFailed)
                          Text('שגיאה בקבלת גרסה',
                              style: Theme.of(context).textTheme.bodyMedium)
                        else
                          Text('גרסה: $_appVersion',
                              style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Text(
                'מפתח: פאדי סרור',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 24.h),
              Text(
                'צור קשר:',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12.h),
              _buildActionTile(
                icon: Icons.person_outline,
                label: 'פאדי סרור (LinkedIn)',
                onTap: () => _launchURL(linkedinUrl),
              ),
              _buildActionTile(
                icon: Icons.email_outlined,
                label: 'fadisrour.za3bor@gmail.com',
                onTap: () {
                  final Uri mailUri = Uri(
                    scheme: 'mailto',
                    path: 'fadisrour.za3bor@gmail.com',
                  );
                  _launchURL(mailUri.toString());
                },
                trailing: IconButton(
                  tooltip: 'העתק',
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () async {
                    await Clipboard.setData(
                      const ClipboardData(text: 'fadisrour.za3bor@gmail.com'),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('האימייל הועתק')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
