import 'package:flutter/material.dart';

import '../mealie.dart';
import '../theme.dart';
import 'cook.dart';
import 'recipe_detail.dart';
import 'settings.dart';
import 'shopping.dart';
import 'today.dart';
import 'recipes.dart';

class Shell extends StatefulWidget {
  const Shell({super.key, required this.store});

  final AppStore store;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = const int.fromEnvironment('START_TAB');

  @override
  void initState() {
    super.initState();
    // Screenshot harness: open a recipe without a tap.
    const cookFirst = bool.fromEnvironment('OPEN_COOK');
    if (cookFirst && widget.store.recipes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final full = await widget.store.open(widget.store.recipes.first);
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CookScreen(recipe: full),
        ));
      });
    }
    const slug = String.fromEnvironment('OPEN_RECIPE');
    if (slug.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final match =
            widget.store.recipes.where((r) => r.slug == slug).firstOrNull;
        if (match == null || !mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(store: widget.store, recipe: match),
        ));
      });
    }
  }

  void _open(int index) => setState(() => _tab = index);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          TodayScreen(store: widget.store, onShop: () => _open(2), onBrowse: () => _open(1)),
          RecipesScreen(store: widget.store),
          ShoppingScreen(store: widget.store),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.bg,
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 58,
            child: Row(
              children: [
                _tabButton(0, Icons.nightlight_outlined, Icons.nightlight_round, 'Tonight'),
                _tabButton(1, Icons.menu_book_outlined, Icons.menu_book, 'Recipes'),
                _tabButton(2, Icons.shopping_basket_outlined, Icons.shopping_basket, 'List'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabButton(int index, IconData icon, IconData activeIcon, String label) {
    final c = context.c;
    final active = _tab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _open(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? activeIcon : icon,
                size: 21, color: active ? c.ember : c.faint),
            const SizedBox(height: 3),
            Text(
              label,
              style: context.label.copyWith(
                fontSize: 9.5,
                letterSpacing: 0.8,
                color: active ? c.ember : c.faint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SettingsScreen(store: store)),
      ),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: c.line),
          shape: BoxShape.circle,
          color: c.surface,
        ),
        child: Text(
          store.email.isEmpty ? 'M' : store.email.characters.first.toUpperCase(),
          style: context.title.copyWith(fontSize: 14, color: c.ink),
        ),
      ),
    );
  }
}
