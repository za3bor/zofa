import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zofa_client/constant.dart';

Future<void> checkServerVersion(BuildContext context) async {
  final response =
      await http.get(Uri.parse("http://$ipAddress/api/checkVersion"));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    String latestVersion = data["latestVersion"];
    bool forceUpdate = data["forceUpdate"]; // Check if update is forced

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = packageInfo.version;

    if (_isUpdateRequired(currentVersion, latestVersion)) {
      if (context.mounted) {
        _showUpdateDialog(context, forceUpdate);
      }
    }
  }
}

bool _isUpdateRequired(String current, String latest) {
  List<int> currentParts = current.split('.').map(int.parse).toList();
  List<int> latestParts = latest.split('.').map(int.parse).toList();

  for (int i = 0; i < latestParts.length; i++) {
    if (currentParts[i] < latestParts[i]) return true;
    if (currentParts[i] > latestParts[i]) return false;
  }
  return false;
}

void _showUpdateDialog(BuildContext context, bool forceUpdate) {
  showDialog(
    context: context,
    barrierDismissible: !forceUpdate, // Prevent closing if update is forced
    builder: (context) => AlertDialog(
      title: Text("עדכון נדרש"),
      content: Text("יש עדכון חדש לאפליקציה. אנא עדכן כדי להמשיך להשתמש."),
      actions: [
        if (!forceUpdate)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("תזכורת מאוחר יותר"),
          ),
        TextButton(
          onPressed: () async {
            final url =
                "https://play.google.com/store/apps/details?id=your.zofa_client";
            final Uri uri = Uri.parse(url);

            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
          child: Text("עדכן עכשיו"),
        ),
      ],
    ),
  );
}
