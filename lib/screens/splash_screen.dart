import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/session_provider.dart';

/// Branded launch screen shown on app start. Plays a short logo animation, then
/// routes to the right place based on the current session. The router lets
/// `/splash` stay put; this screen is the only thing that navigates away.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _controller,
    curve: Curves.elasticOut,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.2, 1, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _goNext();
  }

  Future<void> _goNext() async {
    final session = context.read<SessionProvider>();
    // Wait for the persisted session to load AND let the animation breathe.
    await Future.wait([
      session.ensureRestored(),
      Future<void>.delayed(const Duration(milliseconds: 1900)),
    ]);
    if (!mounted) return;
    if (!session.isLoggedIn) {
      context.go('/login');
    } else if (session.currentUser!.needsName) {
      context.go('/complete-profile');
    } else {
      context.go('/venues');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
        child: Stack(
          children: [
            // Decorative translucent blobs.
            Positioned(
              top: -60,
              right: -50,
              child: _blob(200),
            ),
            Positioned(
              bottom: -40,
              left: -60,
              child: _blob(180),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      width: 108,
                      height: 108,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.brandDark.withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.bolt_rounded, size: 64, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fade,
                    child: const Column(
                      children: [
                        Text(
                          'QuickSlot',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Play more. Wait less.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Loading hint pinned to the bottom.
            Positioned(
              left: 0,
              right: 0,
              bottom: 48,
              child: FadeTransition(
                opacity: _fade,
                child: const Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
        ),
      );
}
