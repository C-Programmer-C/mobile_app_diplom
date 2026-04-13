import 'package:flutter/material.dart';
import 'package:mobile_app/screens/about_screen.dart';
import 'package:mobile_app/screens/help_screen.dart';
import 'package:mobile_app/screens/login.dart';
import 'package:mobile_app/screens/my_orders.dart';
import 'package:mobile_app/screens/personal_info_screen.dart';
import 'package:mobile_app/screens/settings_screen.dart';
import 'package:mobile_app/screens/store_addresses_screen.dart';
import 'package:mobile_app/services/app_settings.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/cart_sync.dart';

class ProfilePlaceholderScreen extends StatefulWidget {
  final AppSettingsController appSettings;

  const ProfilePlaceholderScreen({super.key, required this.appSettings});

  @override
  State<ProfilePlaceholderScreen> createState() =>
      _ProfilePlaceholderScreenState();
}

class _ProfilePlaceholderScreenState extends State<ProfilePlaceholderScreen> {
  @override
  Widget build(BuildContext context) {
    final userName = AuthService.currentUserName;
    final isLoggedIn = userName != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLoggedIn)
            _WelcomeCard(
              userName: userName,
            )
          else
            _LoginCard(
              onLoginSuccess: () {
                setState(() {});
              },
            ),
          const SizedBox(height: 16),
          _ProfileMenu(
            appSettings: widget.appSettings,
            onLogout: () {
              setState(() {});
            },
            onUserDataChanged: () {
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  final VoidCallback? onLoginSuccess;

  const _LoginCard({this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Войдите в профиль',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Получайте бонусы за покупки и персональные предложения',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                  if (result == true) {
                    onLoginSuccess?.call();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 219, 9, 9),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Войти или зарегистрироваться',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String userName;

  const _WelcomeCard({
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.person, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Добро пожаловать, $userName',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Рады видеть вас снова',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  final VoidCallback? onLogout;
  final VoidCallback? onUserDataChanged;
  final AppSettingsController appSettings;

  const _ProfileMenu({
    this.onLogout,
    this.onUserDataChanged,
    required this.appSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthService.currentUserName != null;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 1,
      child: Column(
        children: [
          const Divider(height: 1),
          _MenuItem(
            icon: Icons.store_mall_directory,
            title: 'Адреса магазинов',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StoreAddressesScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _MenuItem(
            icon: Icons.help_outline,
            title: 'Помощь',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              );
            },
          ),
          const Divider(height: 1),
          _MenuItem(
            icon: Icons.info_outline,
            title: 'О приложении',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
          if (isLoggedIn) const Divider(height: 1),
          if (isLoggedIn)
            _MenuItem(
              icon: Icons.badge_outlined,
              title: 'Личная информация',
              onTap: () async {
                final saved = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const PersonalInfoScreen(),
                  ),
                );
                if (!context.mounted) return;
                if (saved == true) {
                  onUserDataChanged?.call();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Сохранено')),
                  );
                }
              },
            ),
          if (isLoggedIn) const Divider(height: 1),
          if (isLoggedIn)
            _MenuItem(
              icon: Icons.shopping_bag_outlined,
              title: 'Заказы',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MyOrdersScreen(),
                  ),
                );
              },
            ),
          const Divider(height: 1),
          _MenuItem(
            icon: Icons.settings,
            title: 'Настройки',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(settings: appSettings),
                ),
              );
            },
          ),
          if (isLoggedIn) const Divider(height: 1),
          if (isLoggedIn)
            _MenuItem(
              icon: Icons.exit_to_app,
              title: 'Выйти',
              isDestructive: true,
              onTap: () async {
                await AuthService.clearTokens();
                CartSync.notifyChanged();
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Вы вышли из профиля')),
                );
                onLogout?.call();
              },
            ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Colors.white,
      leading: Icon(icon),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: isDestructive ? Colors.red : Colors.black,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
