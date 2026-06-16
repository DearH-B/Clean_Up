import 'package:url_launcher/url_launcher.dart';

typedef ExternalLinkLauncher = Future<bool> Function(Uri uri);

Future<bool> launchExternalLink(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
