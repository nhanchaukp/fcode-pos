import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';

class AppVersionText extends StatefulWidget {
  const AppVersionText({super.key});

  @override
  State<AppVersionText> createState() => _AppVersionTextState();
}

class _AppVersionTextState extends State<AppVersionText> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _version = 'v${info.version} (${info.buildNumber})';
      });
    } catch (_) {
      setState(() {
        _version = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_version == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 16),
      child: Text(
        'Phiên bản: $_version',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }
}
