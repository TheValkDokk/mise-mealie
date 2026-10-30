import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mealie.dart';
import 'screens/shell.dart';
import 'screens/welcome.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await AppStore.load();

  // Development hook: sign in against a live server without tapping the form.
  const url = String.fromEnvironment('CONNECT_URL');
  if (url.isNotEmpty) {
    try {
      if (store.connected) await store.disconnect();
      await store.connect(
        server: url,
        email: const String.fromEnvironment('CONNECT_EMAIL'),
        password: const String.fromEnvironment('CONNECT_PASS'),
      );
      debugPrint('CONNECT ok: recipes=${store.recipes.length} '
          'plans=${store.plans.length} items=${store.items.length} '
          'error=${store.error}');
    } catch (e) {
      debugPrint('CONNECT failed: $e');
    }
  }

  runApp(MiseApp(store: store));
}

class MiseApp extends StatelessWidget {
  const MiseApp({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final dark = store.dark;
        return MaterialApp(
          title: 'Mise',
          debugShowCheckedModeBanner: false,
          theme: miseTheme(Brightness.light),
          darkTheme: miseTheme(Brightness.dark),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) {
            final c = context.c;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness:
                    dark ? Brightness.light : Brightness.dark,
                statusBarBrightness:
                    dark ? Brightness.dark : Brightness.light,
                systemNavigationBarColor: c.bg,
                systemNavigationBarIconBrightness:
                    dark ? Brightness.light : Brightness.dark,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: store.connected
              ? Shell(store: store)
              : WelcomeScreen(store: store),
        );
      },
    );
  }
}
