import 'package:flutter/material.dart';
import 'package:mobile_app/screens/cart.dart';
import 'package:mobile_app/screens/catalog.dart';
import 'package:mobile_app/screens/favorites.dart';
import 'package:mobile_app/screens/feed.dart';
import 'package:mobile_app/screens/profile.dart';
import 'package:mobile_app/services/app_settings.dart';
import 'package:mobile_app/services/auth_service.dart';

import 'screens/bottom_nav_bar.dart';
import 'services/bottom_nav_sync.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appSettings = AppSettingsController();
  await AuthService.init();
  await appSettings.load();
  await Future.delayed(const Duration(seconds: 1));
  runApp(MyApp(appSettings: appSettings));
}

class MyApp extends StatelessWidget {
  final AppSettingsController appSettings;

  const MyApp({super.key, required this.appSettings});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Mobile Shop',
          theme: ThemeData(
            colorSchemeSeed: Colors.black,
            useMaterial3: false,
            scaffoldBackgroundColor: Colors.white,
            canvasColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 1,
            ),
          ),
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(appSettings.fontScale),
              ),
              child: child!,
            );
          },
          home: MainScreen(appSettings: appSettings),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final AppSettingsController appSettings;

  const MainScreen({super.key, required this.appSettings});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey _favoritesKey = GlobalKey();
  late final List<GlobalKey<NavigatorState>> _navigatorKeys;
  late final List<_TabNavigatorObserver> _navigatorObservers;
  bool _showRootAppBar = true;
  late final VoidCallback _authSessionListener;

  @override
  void initState() {
    super.initState();
    _navigatorKeys =
        List<GlobalKey<NavigatorState>>.generate(5, (_) => GlobalKey());
    _navigatorObservers = List<_TabNavigatorObserver>.generate(
      5,
      (_) => _TabNavigatorObserver(_syncAppBarVisibility),
    );
    BottomNavSync.listenable.addListener(_onNavSyncChanged);
    _authSessionListener = () {
      if (mounted) setState(() {});
    };
    AuthService.sessionEpoch.addListener(_authSessionListener);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAppBarVisibility());
  }

  void _onNavSyncChanged() {
    final next = BottomNavSync.currentIndex;
    if (!mounted) return;
    if (next == _currentIndex) return;
    setState(() {
      _currentIndex = next;
    });
    _syncAppBarVisibility();
  }

  void _syncAppBarVisibility() {
    if (!mounted) return;
    final canPop = _navigatorKeys[_currentIndex].currentState?.canPop() ?? false;
    final nextShow = !canPop;
    if (_showRootAppBar == nextShow) return;
    setState(() {
      _showRootAppBar = nextShow;
    });
  }

  @override
  void dispose() {
    AuthService.sessionEpoch.removeListener(_authSessionListener);
    BottomNavSync.listenable.removeListener(_onNavSyncChanged);
    super.dispose();
  }

  static const List<String> _titles = [
    'Лента',
    'Каталог',
    'Корзина',
    'Избранное',
    'Профиль',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _showRootAppBar ? AppBar(title: Text(_titles[_currentIndex])) : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          Navigator(
            key: _navigatorKeys[0],
            observers: [_navigatorObservers[0]],
            initialRoute: '/',
            onGenerateRoute: (RouteSettings settings) {
              return MaterialPageRoute<void>(
                builder: (_) => const FeedScreen(),
                settings: settings,
              );
            },
          ),
          Navigator(
            key: _navigatorKeys[1],
            observers: [_navigatorObservers[1]],
            initialRoute: '/',
            onGenerateRoute: (RouteSettings settings) {
              return MaterialPageRoute<void>(
                builder: (_) => const CatalogScreen(),
                settings: settings,
              );
            },
          ),
          Navigator(
            key: _navigatorKeys[2],
            observers: [_navigatorObservers[2]],
            initialRoute: '/',
            onGenerateRoute: (RouteSettings settings) {
              return MaterialPageRoute<void>(
                builder: (_) => const CartScreen(),
                settings: settings,
              );
            },
          ),
          Navigator(
            key: _navigatorKeys[3],
            observers: [_navigatorObservers[3]],
            initialRoute: '/',
            onGenerateRoute: (RouteSettings settings) {
              return MaterialPageRoute<void>(
                builder: (_) =>
                    FavoritesPlaceholderScreen(key: _favoritesKey),
                settings: settings,
              );
            },
          ),
          Navigator(
            key: _navigatorKeys[4],
            observers: [_navigatorObservers[4]],
            initialRoute: '/',
            onGenerateRoute: (RouteSettings settings) {
              return MaterialPageRoute<void>(
                builder: (_) => ProfilePlaceholderScreen(
                      appSettings: widget.appSettings,
                    ),
                settings: settings,
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) {
            _navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
          }
          setState(() {
            _currentIndex = index;
          });
          _syncAppBarVisibility();
          BottomNavSync.setIndex(index);
          if (index == 3) {
            final state = _favoritesKey.currentState;
            if (state != null) {
              // ignore: avoid_dynamic_calls
              (state as dynamic).reload();
            }
          }
        },
      ),
    );
  }
}

class _TabNavigatorObserver extends NavigatorObserver {
  final VoidCallback onChanged;

  _TabNavigatorObserver(this.onChanged);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onChanged();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onChanged();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onChanged();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    onChanged();
  }
}
