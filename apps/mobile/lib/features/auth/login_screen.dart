import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/pixel/pixel_anim.dart';
import '../../core/pixel/pixel_sprite.dart';
import '../../core/pixel/pixel_widgets.dart';
import '../../core/pixel/sprites.dart';
import '../../core/theme/app_theme.dart';

/// Title screen. Authentication is via Steam OpenID (wired up in F5/F7).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _connecting = false;

  Future<void> _connectWithSteam() async {
    setState(() => _connecting = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PixelBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Crest: a single entrance, then stillness — the moving
                  // parts of the title screen are the heroes below.
                  const PixelArt(Sprites.emblem, size: 128)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
                  const SizedBox(height: 20),
                  const PixelText('Idle RPG', size: 34, align: TextAlign.center)
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 500.ms),
                  const SizedBox(height: 10),
                  const PixelText(
                    'IDLE PROGRESSION, POWERED BY YOUR STEAM INVENTORY',
                    size: 10,
                    color: AppColors.muted,
                    align: TextAlign.center,
                  ).animate().fadeIn(delay: 250.ms, duration: 500.ms),
                  const SizedBox(height: 44),
                  // The heroes waiting on the title screen.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final (i, frames) in const [
                        Sprites.warriorFrames,
                        Sprites.berserkerFrames,
                        Sprites.clericFrames,
                        Sprites.mageFrames,
                      ].indexed)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: AnimatedPixelArt(
                            frames,
                            size: 52,
                            stepMs: 650,
                            startFrame: i % 2,
                          ),
                        ),
                    ],
                  ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                  const SizedBox(height: 44),
                  SizedBox(
                    width: double.infinity,
                    child: PixelButton(
                      label: _connecting ? 'Connecting…' : 'Conectar con Steam',
                      onPressed: _connecting ? null : _connectWithSteam,
                      icon: _connecting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.text,
                              ),
                            )
                          : const PixelArt(Sprites.crystal, size: 20),
                    ),
                  ).animate().fadeIn(delay: 350.ms, duration: 500.ms),
                  const SizedBox(height: 14),
                  // Hard on/off blink, cartridge style — no alpha pulsing.
                  const PixelBlink(
                    child: PixelText(
                      '> PRESS TO START YOUR ADVENTURE <',
                      size: 10,
                      color: AppColors.accent,
                      align: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const PixelText(
                    'WE ONLY REQUEST READ ACCESS TO YOUR PUBLIC INVENTORY.',
                    size: 8,
                    color: AppColors.muted,
                    align: TextAlign.center,
                  ).animate().fadeIn(delay: 450.ms, duration: 500.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
