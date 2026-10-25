import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/app_bootstrap.dart';
import '../../core/services/notification_router.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_icon_badge.dart';
import '../../features/home/today_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/stats/stats_screen.dart';
import '../../features/topics/create_topic_screen.dart';
import '../../features/topics/topics_screen.dart';
import '../../data/models/topic.dart';
import '../../core/theme/app_palette.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static const Key todayKey = Key('tab-today');
  static const Key topicsKey = Key('tab-topics');
  static const Key statsKey = Key('tab-stats');
  static const Key profileKey = Key('tab-profile');

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _index = 0;

  /// Dữ liệu đổi từ bên ngoài tab (tạo chủ đề, lưu import...) — dùng chung singleton.
  ValueNotifier<int> get _dataVersion => AppBootstrap.instance.dataVersion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Đăng ký handler điều hướng trực tiếp khi người dùng chạm thông báo
    // (foreground / warm start) — không chờ resume hay TodayScreen.
    AppBootstrap.instance.onNotificationOpened = _handleNotificationOpened;
    // Xử lý payload cold-start sau frame đầu tiên (navigator đã sẵn sàng).
    WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingPayload());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (AppBootstrap.instance.onNotificationOpened == _handleNotificationOpened) {
      AppBootstrap.instance.onNotificationOpened = null;
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Mở lại app → đối soát kế hoạch học và xử lý payload thông báo nếu có.
    if (AppBootstrap.instance.isReady) {
      unawaited(AppBootstrap.instance.refreshStudyPlan());
      if (AppBootstrap.instance.services.prefs.notificationsEnabled) {
        unawaited(AppBootstrap.instance.refreshReminderSchedule());
      }
    }
    _handlePendingPayload();
  }

  /// Xử lý payload thông báo chờ (cold start hoặc warm start resume).
  /// Đảm bảo chỉ xử lý một lần cho mỗi payload.
  Future<void> _handlePendingPayload() async {
    final payload = AppBootstrap.instance.pendingNotificationPayload;
    if (payload == null || !mounted) return;
    AppBootstrap.instance.pendingNotificationPayload = null;
    final services = AppBootstrap.instance.services;
    await NotificationRouter.handle(
      context: context,
      services: services,
      payload: payload,
      isColdStart: false,
    );
  }

  /// Handler trực tiếp cho chạm thông báo khi app đang foreground/warm.
  void _handleNotificationOpened(NotificationPayload payload) {
    if (!mounted) return;
    AppBootstrap.instance.pendingNotificationPayload = null;
    final services = AppBootstrap.instance.services;
    unawaited(
      NotificationRouter.handle(
        context: context,
        services: services,
        payload: payload,
        isColdStart: false,
      ),
    );
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  Future<void> _createTopic() async {
    final Topic? created = await Navigator.of(context).push<Topic>(
      MaterialPageRoute<Topic>(builder: (_) => const CreateTopicScreen()),
    );
    if (created != null) {
      AppBootstrap.instance.bumpDataVersion();
      setState(() => _index = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = <Widget>[
      TodayScreen(
        key: AppShell.todayKey,
        onCreateTopic: _createTopic,
        reloadListenable: _dataVersion,
      ),
      TopicsScreen(key: AppShell.topicsKey, reloadListenable: _dataVersion),
      StatsScreen(key: AppShell.statsKey),
      ProfileScreen(key: AppShell.profileKey),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: context.appColors.border, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Trang chủ',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Chủ đề',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_rounded),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Thống kê',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Hồ sơ',
            ),
          ],
        ),
      ),
    );
  }
}

class TabPlaceholder extends StatelessWidget {
  const TabPlaceholder({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppIconBadge(
              icon: icon,
              tone: AppIconTone.primary,
              size: 56,
              radius: AppRadius.xl,
              iconSize: 32,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
