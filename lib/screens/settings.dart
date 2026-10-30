import 'package:flutter/material.dart';

import '../mealie.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 40),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: c.line),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back_rounded, size: 17, color: c.ink),
                  ),
                ),
                const Spacer(),
                Text('SETTINGS', style: context.label),
                const Spacer(),
                const SizedBox(width: 36),
              ],
            ),
            const SizedBox(height: 24),
            Text('Kitchen', style: context.display.copyWith(fontSize: 30)),
            const SizedBox(height: 18),
            _panel(context, [
              _row(context, 'Server', store.demo ? 'Sample kitchen' : store.baseUrl),
              _divider(c),
              _row(context, 'Signed in as', store.demo ? 'demo' : store.email),
              _divider(c),
              _row(context, 'Recipes cached', '${store.recipes.length}'),
              _divider(c),
              _row(
                context,
                'Last sync',
                store.lastSync == null ? 'never' : _ago(store.lastSync!),
              ),
            ]),
            const SizedBox(height: 12),
            if (!store.demo) ...[
              _ghost(context, 'Sync now', Icons.sync_rounded, () => store.sync(full: true)),
              const SizedBox(height: 8),
              _ghost(context, 'Sign out', Icons.logout_rounded, () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: c.bg,
                    title: Text('Sign out?', style: ctx.headline),
                    content: Text(
                      'The token and the cached recipes on this phone are removed. '
                      'Nothing on your Mealie server changes.',
                      style: ctx.body,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text('Cancel', style: TextStyle(color: c.muted)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text('Sign out', style: TextStyle(color: c.danger)),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await store.disconnect();
                  if (context.mounted) Navigator.of(context).pop();
                }
              }, danger: true),
            ] else
              _ghost(context, 'Connect a server', Icons.link_rounded, () async {
                await store.disconnect();
                if (context.mounted) Navigator.of(context).pop();
              }),
            const SizedBox(height: 26),
            Text('Reading the kitchen', style: context.headline.copyWith(fontSize: 19)),
            const SizedBox(height: 10),
            _panel(context, [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 10, 6),
                child: Row(
                  children: [
                    Icon(Icons.dark_mode_outlined, size: 18, color: c.muted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dark kitchen', style: context.body),
                          Text('For cooking after dark.',
                              style: context.small.copyWith(fontSize: 11.5)),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 0.82,
                      child: Switch(
                        value: store.dark,
                        activeThumbColor: c.emberInk,
                        activeTrackColor: c.ember,
                        inactiveThumbColor: c.faint,
                        inactiveTrackColor: c.surfaceAlt,
                        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                        onChanged: store.setDark,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 26),
            Text('About', style: context.headline.copyWith(fontSize: 19)),
            const SizedBox(height: 10),
            _panel(context, [
              _row(context, 'Mise', '1.0.0'),
              _divider(c),
              _row(context, 'Speaks', 'Mealie API v3'),
            ]),
            const SizedBox(height: 14),
            Text(
              'Mise has no servers of its own. Your recipes, plan and list live on '
              'your Mealie instance and in this phone’s storage. There is no account, '
              'no analytics, and nothing to shut down that would take your kitchen '
              'with it.',
              style: context.small.copyWith(fontSize: 11.5, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }

  Widget _panel(BuildContext context, List<Widget> children) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(MiseColors c) => Divider(height: 1, color: c.line);

  Widget _row(BuildContext context, String label, String value) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Text(label, style: context.small.copyWith(fontSize: 13, color: c.muted)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: context.small.copyWith(fontSize: 13, color: c.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ghost(BuildContext context, String label, IconData icon,
      VoidCallback onTap, {bool danger = false}) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: danger ? c.danger.withValues(alpha: 0.4) : c.line),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: danger ? c.danger : c.ink),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: danger ? c.danger : c.ink,
                )),
          ],
        ),
      ),
    );
  }
}
