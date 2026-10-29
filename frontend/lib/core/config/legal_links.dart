import 'package:url_launcher/url_launcher.dart';

// Your hosted Terms of Use and Privacy Policy pages, given at build time:
//   --dart-define=TERMS_URL=https://... --dart-define=PRIVACY_URL=https://...
// The app stores require both on the subscription screen. Links whose URL
// isn't set are hidden (development builds).
const termsUrl = String.fromEnvironment('TERMS_URL');
const privacyUrl = String.fromEnvironment('PRIVACY_URL');

/// Opens [url] in the browser; false if it couldn't be opened.
Future<bool> openExternalUrl(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
