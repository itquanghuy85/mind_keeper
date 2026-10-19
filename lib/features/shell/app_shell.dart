import 'package:flutter/material.dart';

import '../../core/services/app_bootstrap.dart';
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

class _AppShellState extends State<AppShell> {
  int _index = 0;

  /// Dữ liệu đổi từ bên ngoài tab (tạo chủ đề, lưu import...) — dùng chung singleton.
  ValueNotifier<int> get _dataVersion => AppBootstrap.instance.dataVersion;

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
