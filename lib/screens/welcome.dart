import 'package:flutter/material.dart';

import '../mealie.dart';
import '../theme.dart';
import '../widgets.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.store});

  final AppStore store;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _server = TextEditingController(text: 'http://');
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _server.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.store.connect(
        server: _server.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is MealieException
            ? e.message
            : 'Could not reach that server.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: c.ember, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('MISE', style: context.label.copyWith(letterSpacing: 2.4, color: c.ink)),
              ],
            ),
            const SizedBox(height: 40),
            Text('Dinner,\ndecided.', style: context.display.copyWith(fontSize: 46, height: 0.98)),
            const SizedBox(height: 16),
            Text(
              'A calm client for your own Mealie server. Recipes, the week’s plan and '
              'the shopping list — offline, on your phone, no account of ours.',
              style: context.body.copyWith(color: c.muted, height: 1.6),
            ),
            const SizedBox(height: 34),
            Text('YOUR SERVER', style: context.label),
            const SizedBox(height: 12),
            MiseField(
              label: 'Address',
              controller: _server,
              hint: 'https://mealie.example.com',
              keyboard: TextInputType.url,
            ),
            const SizedBox(height: 14),
            MiseField(
              label: 'Email',
              controller: _email,
              hint: 'you@example.com',
              keyboard: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            MiseField(
              label: 'Password',
              controller: _password,
              hint: '••••••••',
              obscure: true,
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: context.small.copyWith(color: c.danger)),
            ],
            const SizedBox(height: 22),
            EmberButton(
              label: 'Connect',
              busy: _busy,
              onPressed: _connect,
            ),
            const SizedBox(height: 10),
            EmberButton(
              label: 'Look around first',
              ghost: true,
              onPressed: () => widget.store.startDemo(),
            ),
            const SizedBox(height: 26),
            Text(
              'Mise talks only to the Mealie instance you enter. The password is used '
              'once to get a token and never stored; the token stays in this phone’s '
              'keychain-backed storage.',
              style: context.small.copyWith(fontSize: 11.5, height: 1.6, color: c.faint),
            ),
          ],
        ),
      ),
    );
  }
}
