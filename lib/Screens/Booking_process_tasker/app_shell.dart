import 'package:flutter/material.dart';
import 'package:taskoon/Screens/Booking_process_tasker/tasker_home_screen.dart';
import 'package:taskoon/widgets/bottom_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  BottomTab _tab = BottomTab.home;

  final _keys = {
    BottomTab.home: GlobalKey<NavigatorState>(),
    BottomTab.reports: GlobalKey<NavigatorState>(),
    BottomTab.map: GlobalKey<NavigatorState>(),
    BottomTab.about: GlobalKey<NavigatorState>(),
  //  BottomTab.profile: GlobalKey<NavigatorState>(),
  };

  Future<bool> _onWillPop() async {
    final nav = _keys[_tab]!.currentState!;
    if (nav.canPop()) {
      nav.pop();
      return false;
    }
    if (_tab != BottomTab.home) {
      setState(() => _tab = BottomTab.home);
      return false;
    }
    return true;
  }

  void _setTab(BottomTab t) => setState(() => _tab = t);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: IndexedStack(
          index: _tab.index,
          children: [
            _TabNavigator(key: _keys[BottomTab.home], initial:  TaskerHomeRedesign()),
            _TabNavigator(key: _keys[BottomTab.reports], initial: const TaskerHomeRedesign()),
            _TabNavigator(key: _keys[BottomTab.map], initial: const TaskerHomeRedesign()),
            _TabNavigator(key: _keys[BottomTab.about], initial: const TaskerHomeRedesign()),
      //    _TabNavigator(key: _keys[BottomTab.profile], initial: const ProfilePage()),
          ],
        ),
        bottomNavigationBar: BottomBar(
          active: _tab,
          onChanged: _setTab,
        ),
      ),
    );
  }
}

class _TabNavigator extends StatelessWidget {
  const _TabNavigator({super.key, required this.initial});
  final Widget initial;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => initial,
          settings: settings,
        );
      },
    );
  }
}




