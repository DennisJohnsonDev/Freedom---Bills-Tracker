import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/colors.dart';
import '../../../core/haptics.dart';
import '../../../providers/loan_providers.dart';

/// "Meet the creator" card that lives at the bottom of the Insights screen.
///
/// Plays a smooth blur-to-clear reveal every time the Insights tab is opened.
class CreatorCard extends ConsumerWidget {
  const CreatorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Restart the reveal animation on each Insights tab visit.
    final tick = ref.watch(insightsVisitTickProvider);
    return _RevealCard(key: ValueKey('creator-card-$tick'));
  }
}

class _RevealCard extends StatefulWidget {
  const _RevealCard({super.key});

  @override
  State<_RevealCard> createState() => _RevealCardState();
}

class _RevealCardState extends State<_RevealCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _blur;
  late final Animation<double> _scale;
  late final Animation<double> _content;

  static const _githubUrl = 'https://github.com/DennisJohnsonDev';
  static const _linkedinUrl =
      'https://www.linkedin.com/in/dennis-johnson-flutter-developer/';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _blur = Tween<double>(begin: 22, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _scale = Tween<double>(begin: 1.08, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _content = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );
    // Tiny delay so it feels intentional (not a flash) on tab switch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _open(String url) async {
    Haptics.light();
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 28,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ---- Photo with animated blur + subtle Ken Burns ----
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, child) => Transform.scale(
                  scale: _scale.value,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: _blur.value,
                      sigmaY: _blur.value,
                      tileMode: TileMode.decal,
                    ),
                    child: child,
                  ),
                ),
                child: const Image(
                  image: AssetImage(
                      'assets/images/developer_me_full_size.jpg'),
                  fit: BoxFit.cover,
                  alignment: Alignment(0, -0.05),
                ),
              ),

              // ---- Vignette / gradient overlay ----
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x66000000),
                        Color(0x00000000),
                        Color(0x00000000),
                        Color(0xCC000000),
                        Color(0xF2000000),
                      ],
                      stops: [0.0, 0.18, 0.45, 0.82, 1.0],
                    ),
                  ),
                ),
              ),

              // ---- Top label ----
              Positioned(
                top: 20,
                left: 22,
                right: 22,
                child: FadeTransition(
                  opacity: _content,
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        'MEET THE CREATOR',
                        style: t.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ---- Bottom content ----
              Positioned(
                left: 22,
                right: 22,
                bottom: 22,
                child: FadeTransition(
                  opacity: _content,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.18),
                      end: Offset.zero,
                    ).animate(_content),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Dennis Johnson',
                          style: t.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 26,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Gap(6),
                        Container(
                          width: 28,
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const Gap(12),
                        Text(
                          'Flutter developer & product engineer',
                          style: t.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Gap(6),
                        Text(
                          'Designing apps that respect your time,\nattention, and money.',
                          style: t.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.65),
                            height: 1.45,
                            fontSize: 12,
                          ),
                        ),
                        const Gap(18),
                        Row(
                          children: [
                            _SocialPill(
                              label: 'GitHub',
                              onTap: () => _open(_githubUrl),
                            ),
                            const Gap(10),
                            _SocialPill(
                              label: 'LinkedIn',
                              onTap: () => _open(_linkedinUrl),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialPill extends StatelessWidget {
  const _SocialPill({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: Colors.white.withValues(alpha: 0.10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 0.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: t.labelLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(8),
                  Icon(
                    LucideIcons.arrowUpRight,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
