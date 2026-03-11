import 'package:flutter/material.dart';
import 'package:mobile_app/screens/cart.dart';
import 'package:mobile_app/screens/catalog.dart';
import 'package:mobile_app/screens/favorites.dart';
import 'package:mobile_app/screens/feed.dart';
import 'package:mobile_app/screens/profile.dart';
import 'package:mobile_app/services/auth_service.dart';

import 'screens/bottom_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();
  await Future.delayed(const Duration(seconds: 1));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo 123',
      theme: ThemeData(
        colorSchemeSeed: Colors.black,
        useMaterial3: false,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey _favoritesKey = GlobalKey();

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
      appBar: AppBar(title: Text(_titles[_currentIndex])),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          ProductGrid(),
          const CatalogPlaceholderScreen(),
          const CartPlaceholderScreen(),
          FavoritesPlaceholderScreen(key: _favoritesKey),
          const ProfilePlaceholderScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
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














