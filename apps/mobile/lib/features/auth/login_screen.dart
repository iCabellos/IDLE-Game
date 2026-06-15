import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// Entry screen. Authentication is via Steam OpenID (wired up in F5/F7).
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.accent, width: 2),
                  ),
                  child: const Icon(Icons.shield, color: AppColors.accent, size: 48),
                ).animate().fadeIn(duration: 500.ms).scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                    ),
                const SizedBox(height: 24),
                const Text(
                  'Idle RPG',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
                const SizedBox(height: 8),
                const Text(
                  'Idle progression, powered by your Steam inventory.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 14),
                ).animate().fadeIn(delay: 250.ms, duration: 500.ms),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _connecting ? null : _connectWithSteam,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _connecting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.text,
                            ),
                          )
                        : const Icon(Icons.login),
                    label: Text(
                      _connecting ? 'Connecting…' : 'Conectar con Steam',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ).animate().fadeIn(delay: 350.ms, duration: 500.ms),
                const SizedBox(height: 16),
                const Text(
                  'We only request read access to your public inventory.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ).animate().fadeIn(delay: 450.ms, duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
