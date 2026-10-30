import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../mealie.dart';
import '../theme.dart';
import '../widgets.dart';
import 'cook.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({
    super.key,
    required this.store,
    required this.recipe,
  });

  final AppStore store;
  final Recipe recipe;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Recipe _recipe = widget.recipe;
  final Set<int> _checked = {};
  bool _loading = false;
  String? _error;

  AppStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    if (!_recipe.hasDetail) _loadFull();
  }

  Future<void> _loadFull() async {
    setState(() => _loading = true);
    try {
      final full = await store.open(_recipe);
      if (mounted) setState(() => _recipe = full);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            e is MealieException ? e.message : 'Could not load the recipe.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _addToList() async {
    HapticFeedback.selectionClick();
    try {
      final n = await store.addRecipeToShopping(_recipe);
      _toast(n > 0 ? 'Added $n items to ${store.listName}' : 'Added to ${store.listName}');
    } catch (e) {
      _toast(e is MealieException ? e.message : 'Could not add to the list.');
    }
  }

  Future<void> _planSheet() async {
    final c = context.c;
    final now = DateTime.now();
    final choice = await showModalBottomSheet<({DateTime date, String type})>(
      context: context,
      backgroundColor: c.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.only(top: 16), child: MiseSheetGrip()),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: [
                  Text('Plan it', style: ctx.headline.copyWith(fontSize: 20)),
                  const Spacer(),
                  Text('DINNER', style: ctx.label),
                ],
              ),
            ),
            for (var i = 0; i < 5; i++)
              ListTile(
                title: Text(
                  i == 0 ? 'Tonight' : i == 1 ? 'Tomorrow' : longDate(now.add(Duration(days: i))),
                  style: ctx.body,
                ),
                trailing: Icon(Icons.chevron_right_rounded, size: 18, color: ctx.c.faint),
                onTap: () => Navigator.of(ctx).pop((
                  date: now.add(Duration(days: i)),
                  type: 'dinner',
                )),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null) return;
    try {
      await store.planRecipe(_recipe, choice.date, choice.type);
      _toast('Planned for ${longDate(choice.date)}');
    } catch (e) {
      _toast(e is MealieException ? e.message : 'Could not plan it.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final servings = _recipe.servings > 0 ? _recipe.servings.toInt() : 2;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 330,
            backgroundColor: c.bg,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _circleButton(Icons.arrow_back_rounded,
                  () => Navigator.of(context).maybePop()),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  RecipePhoto(store: store, recipe: _recipe, dark: true),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          c.scrim.withValues(alpha: 0.35),
                          Colors.transparent,
                          c.bg,
                        ],
                        stops: const [0, 0.55, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_recipe.categories.isNotEmpty || _recipe.tags.isNotEmpty)
                    Text(
                      [
                        ..._recipe.categories.map((e) => e.toUpperCase()),
                        ..._recipe.tags.take(2).map((e) => e.toUpperCase()),
                      ].join('  ·  '),
                      style: context.label.copyWith(color: c.ember),
                    ),
                  const SizedBox(height: 8),
                  Text(_recipe.name,
                      style: context.display.copyWith(fontSize: 32, height: 1.02)),
                  if (_recipe.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(_recipe.description,
                        style: context.body.copyWith(color: c.muted, height: 1.55)),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _stat('TIME', humanMinutes(_recipe.totalMinutes)),
                      const SizedBox(width: 26),
                      _stat('SERVES', '$servings'),
                      const SizedBox(width: 26),
                      _stat('STEPS', _recipe.steps.isEmpty ? '—' : '${_recipe.steps.length}'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!,
                          style: context.small.copyWith(color: c.danger)),
                    ),
                  EmberButton(
                    label: _recipe.steps.isEmpty ? 'No steps yet' : 'Start cooking',
                    icon: Icons.play_arrow_rounded,
                    height: 54,
                    onPressed: _recipe.steps.isEmpty
                        ? null
                        : () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => CookScreen(recipe: _recipe),
                            )),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: EmberButton(
                          label: 'Add to list',
                          ghost: true,
                          height: 48,
                          icon: Icons.shopping_basket_outlined,
                          onPressed: _addToList,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: EmberButton(
                          label: 'Plan it',
                          ghost: true,
                          height: 48,
                          icon: Icons.calendar_today_outlined,
                          onPressed: _planSheet,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SectionLabel('Ingredients',
                      trailing: Text('${_recipe.ingredients.length}',
                          style: context.mono.copyWith(fontSize: 11, color: c.faint))),
                  const SizedBox(height: 8),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else
                    ..._recipe.ingredients.asMap().entries.map((e) {
                      final checked = _checked.contains(e.key);
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            checked ? _checked.remove(e.key) : _checked.add(e.key);
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                width: 19,
                                height: 19,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: checked ? c.sage : Colors.transparent,
                                  border: Border.all(
                                    color: checked ? c.sage : c.line,
                                    width: 1.4,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: checked
                                    ? Icon(Icons.check_rounded,
                                        size: 13, color: c.bg)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: context.body.copyWith(
                                    fontSize: 14.5,
                                    color: checked ? c.faint : c.ink,
                                    decoration:
                                        checked ? TextDecoration.lineThrough : null,
                                    decorationColor: c.faint,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 26),
                  SectionLabel('Method'),
                  const SizedBox(height: 12),
                  ..._recipe.steps.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 26,
                              child: Text('${e.key + 1}',
                                  style: context.mono.copyWith(
                                      fontSize: 12, color: c.ember)),
                            ),
                            Expanded(
                              child: Text(e.value,
                                  style: context.body.copyWith(
                                      fontSize: 15, height: 1.6)),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.label.copyWith(fontSize: 9)),
        const SizedBox(height: 4),
        Text(value, style: context.title.copyWith(fontSize: 15)),
      ],
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}
