import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const SocialHubApp());
}

class SocialHubApp extends StatelessWidget {
  const SocialHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SocialHub',
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7C5CFF),
          surface: Color(0xFF0F0F1A),
          background: Color(0xFF0A0A0F),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static final platforms = loadPlatformLinks();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF141421), Color(0xFF0A0A0F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.05,
          ),
          itemCount: platforms.length,
          itemBuilder: (context, index) {
            final platform = platforms[index];
            return _PlatformCard(platform: platform);
          },
        ),
      ),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  final PlatformLink platform;
  const _PlatformCard({required this.platform});

  Future<void> _open(BuildContext context) async {
    final appUri = Uri.parse(platform.appUrl);
    final webUri = Uri.parse(platform.webUrl);
    // Try app directly, no preflight (more reliable on Android 11+)
    try {
      final ok = await launchUrl(appUri, mode: LaunchMode.externalApplication);
      if (ok) return;
    } catch (_) {
      // ignore and fall back
    }
    try {
      final ok = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      if (ok) return;
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${platform.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: platform.color.withOpacity(0.18),
              child: Icon(platform.icon, color: platform.color),
            ),
            const SizedBox(height: 12),
            Text(platform.name,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: platform.color.withOpacity(0.18),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _open(context),
              child: const Text('Open App'),
            ),
          ],
        ),
      ),
    );
  }
}

class PlatformLink {
  final String name;
  final Color color;
  final String appUrl;
  final String webUrl;
  final IconData icon;
  const PlatformLink({
    required this.name,
    required this.color,
    required this.appUrl,
    required this.webUrl,
    required this.icon,
  });
}

Color _colorFromHex(String? hex, Color fallback) {
  if (hex == null || hex.isEmpty) return fallback;
  var cleaned = hex.trim().replaceAll('#', '');
  if (cleaned.length == 6) cleaned = 'FF$cleaned';
  if (cleaned.length != 8) return fallback;
  try {
    return Color(int.parse(cleaned, radix: 16));
  } catch (_) {
    return fallback;
  }
}

String _env(String key, String fallback) =>
    (dotenv.env[key]?.trim().isNotEmpty ?? false) ? dotenv.env[key]!.trim() : fallback;

String _profileAppUrl({
  required String primary,
  required String fallback,
  String? username,
}) {
  if (username != null && username.trim().isNotEmpty) {
    return primary.replaceAll('{username}', username.trim());
  }
  return fallback;
}

String _profileWebUrl({
  required String primary,
  required String fallback,
  String? username,
}) {
  if (username != null && username.trim().isNotEmpty) {
    return primary.replaceAll('{username}', username.trim());
  }
  return fallback;
}

List<PlatformLink> loadPlatformLinks() {
  return [
    PlatformLink(
      name: 'Instagram',
      color: _colorFromHex(dotenv.env['INSTAGRAM_COLOR'], const Color(0xFFE1306C)),
      appUrl: _profileAppUrl(
        primary: 'instagram://user?username={username}',
        fallback: _env('INSTAGRAM_APP_URL', 'instagram://app'),
        username: dotenv.env['INSTAGRAM_USERNAME'],
      ),
      webUrl: _profileWebUrl(
        primary: 'https://www.instagram.com/{username}/',
        fallback: _env('INSTAGRAM_WEB_URL', 'https://www.instagram.com/accounts/edit/'),
        username: dotenv.env['INSTAGRAM_USERNAME'],
      ),
      icon: Icons.camera_alt_rounded,
    ),
    PlatformLink(
      name: 'Threads',
      color: _colorFromHex(dotenv.env['THREADS_COLOR'], Colors.white),
      appUrl: _profileAppUrl(
        primary: 'threads://user?username={username}',
        fallback: _env('THREADS_APP_URL', 'threads://app'),
        username: dotenv.env['THREADS_USERNAME'],
      ),
      webUrl: _profileWebUrl(
        primary: 'https://www.threads.net/@{username}',
        fallback: _env('THREADS_WEB_URL', 'https://www.threads.net/'),
        username: dotenv.env['THREADS_USERNAME'],
      ),
      icon: Icons.bubble_chart_rounded,
    ),
    PlatformLink(
      name: 'X / Twitter',
      color: _colorFromHex(dotenv.env['TWITTER_COLOR'], const Color(0xFF000000)),
      appUrl: _profileAppUrl(
        primary: 'twitter://user?screen_name={username}',
        fallback: _env('TWITTER_APP_URL', 'twitter://'),
        username: dotenv.env['TWITTER_USERNAME'],
      ),
      webUrl: _profileWebUrl(
        primary: 'https://x.com/{username}',
        fallback: _env('TWITTER_WEB_URL', 'https://x.com/'),
        username: dotenv.env['TWITTER_USERNAME'],
      ),
      icon: Icons.close_rounded,
    ),
    PlatformLink(
      name: 'Facebook',
      color: _colorFromHex(dotenv.env['FACEBOOK_COLOR'], const Color(0xFF1877F2)),
      appUrl: _env('FACEBOOK_APP_URL', 'fb://profile'),
      webUrl: _env('FACEBOOK_WEB_URL', 'https://m.facebook.com/me'),
      icon: Icons.facebook_rounded,
    ),
    PlatformLink(
      name: 'Telegram',
      color: _colorFromHex(dotenv.env['TELEGRAM_COLOR'], const Color(0xFF229ED9)),
      appUrl: _env('TELEGRAM_APP_URL', 'tg://settings'),
      webUrl: _env('TELEGRAM_WEB_URL', 'https://web.telegram.org/a/#/settings/profile'),
      icon: Icons.send_rounded,
    ),
    PlatformLink(
      name: 'Discord',
      color: _colorFromHex(dotenv.env['DISCORD_COLOR'], const Color(0xFF5865F2)),
      appUrl: _env('DISCORD_APP_URL', 'discord://'),
      webUrl: _env('DISCORD_WEB_URL', 'https://discord.com/channels/@me'),
      icon: Icons.gamepad_rounded,
    ),
    PlatformLink(
      name: 'LinkedIn',
      color: _colorFromHex(dotenv.env['LINKEDIN_COLOR'], const Color(0xFF0A66C2)),
      appUrl: _profileAppUrl(
        primary: 'linkedin://profile/{username}',
        fallback: _env('LINKEDIN_APP_URL', 'linkedin://'),
        username: dotenv.env['LINKEDIN_USERNAME'],
      ),
      webUrl: _profileWebUrl(
        primary: 'https://www.linkedin.com/in/{username}/',
        fallback: _env('LINKEDIN_WEB_URL', 'https://www.linkedin.com/me/'),
        username: dotenv.env['LINKEDIN_USERNAME'],
      ),
      icon: Icons.work_rounded,
    ),
    PlatformLink(
      name: 'Reddit',
      color: _colorFromHex(dotenv.env['REDDIT_COLOR'], const Color(0xFFFF4500)),
      appUrl: _profileAppUrl(
        primary: 'reddit://user/{username}/overview',
        fallback: _env('REDDIT_APP_URL', 'reddit://'),
        username: dotenv.env['REDDIT_USERNAME'],
      ),
      webUrl: _profileWebUrl(
        primary: 'https://www.reddit.com/user/{username}',
        fallback: _env('REDDIT_WEB_URL', 'https://www.reddit.com/user/me'),
        username: dotenv.env['REDDIT_USERNAME'],
      ),
      icon: Icons.reddit_rounded,
    ),
  ];
}
