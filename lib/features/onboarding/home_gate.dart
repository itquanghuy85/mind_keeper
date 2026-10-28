import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_services.dart';
import '../shell/app_shell.dart';
import 'onboarding_screen.dart';
import 'onboarding_service.dart';

/// Cổng trước [AppShell]: lần đầu mở app (chưa onboarding và DB còn trống) thì
/// hiện [OnboardingScreen]; người dùng cũ (đã có dữ liệu) vào thẳng app.
class HomeGate extends StatefulWidget {
  const HomeGate({super.key});

  @override
  State<HomeGate> createState() => _HomeGateState();
}

class _HomeGateState extends State<HomeGate> {
  bool? _showOnboarding;

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final AppServices services = context.read<AppServices>();
    bool show;
    try {
      show = await OnboardingService(
        topics: services.topics,
        discovery: services.discovery,
        prefs: services.prefs,
      ).shouldShow();
    } catch (_) {
      // Không đọc được DB → không chặn người dùng.
      show = false;
    }
    if (mounted) setState(() => _showOnboarding = show);
  }

  @override
  Widget build(BuildContext context) {
    final bool? show = _showOnboarding;
    if (show == null) return const Scaffold(body: SizedBox.shrink());
    if (show) {
      return OnboardingScreen(
        onDone: () => setState(() => _showOnboarding = false),
      );
    }
    return const AppShell();
  }
}
