import 'package:flutter/material.dart';
import 'package:mobile_app/services/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettingsController settings;

  const SettingsScreen({super.key, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(title: const Text('Настройки')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Размер текста',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('A', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Slider(
                      value: widget.settings.fontScale,
                      min: 0.85,
                      max: 1.35,
                      divisions: 10,
                      label: '${(widget.settings.fontScale * 100).round()}%',
                      onChanged: (v) {
                        widget.settings.setFontScale(v);
                      },
                    ),
                  ),
                  const Text('A', style: TextStyle(fontSize: 22)),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Уведомления',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Пуш-уведомления о заказах'),
                value: false,
                onChanged: (_) {},
              ),
              const Text(
                'Функция в разработке',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
        );
      },
    );
  }
}
