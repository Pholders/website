// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';

import '../../../../shared/widgets/settings_shell.dart';

class PreferencesSettings extends StatelessWidget {
  const PreferencesSettings({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return SettingsContentCard(
      title: 'Notifications',
      children: const [
        _Section(
          title: 'Channels',
          children: [
            _SwitchLine('Push Notifications'),
            _SwitchLine('Email Notifications'),
            _SwitchLine('SMS Notifications'),
          ],
        ),
        _DividerGap(),
        _Section(
          title: 'Quiet Hours',
          children: [
            _CheckLine('Enable Quiet Hours', switchAtEnd: true),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.only(left: 26),
              child: Row(
                children: [
                  Expanded(
                      child: Text('Start:10:00 PM',
                          style: TextStyle(fontSize: 13))),
                  Expanded(
                      child: Text('End: 07:00 AM',
                          style: TextStyle(fontSize: 13))),
                ],
              ),
            ),
          ],
        ),
        _DividerGap(),
        Padding(
          padding: EdgeInsets.fromLTRB(18, 0, 20, 0),
          child: Row(
            children: [
              Expanded(
                  child: Text('Frequency', style: TextStyle(fontSize: 13))),
              SettingsInput(
                text: 'Instant',
                width: 92,
                height: 22,
                trailing: Icon(Icons.keyboard_arrow_down,
                    size: 16, color: Color(0xFF748486)),
              ),
            ],
          ),
        ),
        _DividerGap(),
        _Section(
          title: 'Advanced',
          children: [
            _CheckLine('Urgent alert override quiet hours'),
            SizedBox(height: 12),
            _CheckLine('Hide sensitive content'),
          ],
        ),
        SizedBox(height: 18),
        _Section(
          title: 'Advanced',
          children: [
            _SwitchLine('Urgent alert override quiet hours'),
            _SwitchLine('Hide sensitive content'),
          ],
        ),
        SizedBox(height: 6),
        SettingsFullWidthAction('Save Changes'),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSectionTitle(title),
          const SizedBox(height: 9),
          ...children,
        ],
      ),
    );
  }
}

class _SwitchLine extends StatelessWidget {
  const _SwitchLine(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          const TinySwitch(),
        ],
      ),
    );
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine(this.label, {this.switchAtEnd = false});

  final String label;
  final bool switchAtEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SmallCheck(),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        if (switchAtEnd) const TinySwitch(),
      ],
    );
  }
}

class _DividerGap extends StatelessWidget {
  const _DividerGap();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(color: SettingsShell.divider, thickness: 2, height: 2),
    );
  }
}
