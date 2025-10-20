import 'package:fcode_pos/ui/components/responsive_layout.dart';
import 'package:fcode_pos/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A widget that contains a list of informational cards displayed vertically.
class GettingStartedCards extends StatelessWidget {
  const GettingStartedCards({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      smallDeviceLayout: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GeneralInfoCard(
              title: "Edit your app",
              link: null,
              subtitle: const HighlightedText(),
            ),
            GeneralInfoCard(
              title: "Head to Appwrite Cloud",
              link: "https://cloud.appwrite.io",
              subtitle: const Text(
                "Start managing your project from the Appwrite console",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF56565C),
                ),
              ),
            ),
            GeneralInfoCard(
              title: "Explore docs",
              link: "https://appwrite.io/docs",
              subtitle: const Text(
                "Discover the full power of Appwrite by diving into our documentation",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF56565C),
                ),
              ),
            ),
          ],
        ),
      ),
      largeDeviceLayout: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: context.isExtraWideScreen ? 64 : 16.0, vertical: 16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            Flexible(
              child: GeneralInfoCard(
                title: "Edit your app",
                link: null,
                subtitle: const HighlightedText(),
              ),
            ),
            Flexible(
              child: GeneralInfoCard(
                title: "Head to Appwrite Cloud",
                link: "https://cloud.appwrite.io",
                subtitle: const Text(
                  "Start managing your project from the Appwrite console",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF56565C),
                  ),
                ),
              ),
            ),
            Flexible(
              child: GeneralInfoCard(
                title: "Explore docs",
                link: "https://appwrite.io/docs",
                subtitle: const Text(
                  "Discover the full power of Appwrite by diving into our documentation",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF56565C),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A reusable card component that displays a title and subtitle with optional link functionality.
class GeneralInfoCard extends StatelessWidget {
  final String title;
  final String? link;
  final Widget subtitle;

  const GeneralInfoCard({
    super.key,
    required this.title,
    this.link,
    required this.subtitle,
  });

  void _openLink() async {
    if (link != null && await canLaunchUrl(Uri.parse(link!))) {
      await launchUrl(Uri.parse(link!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double cardWidth = context.isExtraWideScreen
          ? constraints.maxWidth.clamp(0, 350)
          : constraints.maxWidth;

      return SizedBox(
        width: cardWidth,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFEDEDF0), width: 1),
          ),
          color: Colors.white,
          child: InkWell(
            onTap: link != null ? _openLink : null,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          height: 26 / 20,
                        ),
                      ),
                      if (link != null) ...[
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: Color(0xFFD8D8DB),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 8),
                  subtitle,
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// A widget that displays highlighted text with a specific word or phrase styled differently.
class HighlightedText extends StatelessWidget {
  const HighlightedText({super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF56565C),
        ),
        children: [
          const TextSpan(text: "Edit "),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEDEDF0),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: const Text(
                " lib/main.dart ",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
          const TextSpan(text: " to get started with building your app"),
        ],
      ),
    );
  }
}
