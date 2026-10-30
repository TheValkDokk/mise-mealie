import 'package:flutter/material.dart';

import '../mealie.dart';
import '../theme.dart';
import '../widgets.dart';
import 'recipe_detail.dart';
import 'shell.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key, required this.store});

  final AppStore store;

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final _search = TextEditingController();
  String _query = '';
  String _category = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = widget.store;
    final categories = <String>{'All'};
    for (final r in store.recipes) {
      categories.addAll(r.categories);
    }
    final list = store.recipes.where((r) {
      final q = _query.toLowerCase().trim();
      final matchesQuery = q.isEmpty ||
          r.name.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q) ||
          r.tags.any((t) => t.toLowerCase().contains(q));
      final matchesCat = _category == 'All' || r.categories.contains(_category);
      return matchesQuery && matchesCat;
    }).toList();

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: c.ember,
        onRefresh: () => store.sync(full: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('YOUR COOKBOOK', style: context.label.copyWith(letterSpacing: 1.8)),
                              const SizedBox(height: 6),
                              Text('Recipes', style: context.display.copyWith(fontSize: 30)),
                            ],
                          ),
                        ),
                        SettingsButton(store: store),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: c.surface,
                        border: Border.all(color: c.line),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, size: 18, color: c.faint),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _search,
                              onChanged: (v) => setState(() => _query = v),
                              style: context.body.copyWith(fontSize: 14.5),
                              cursorColor: c.ember,
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Search ${store.recipes.length} recipes',
                                hintStyle: context.body.copyWith(color: c.faint, fontSize: 14.5),
                              ),
                            ),
                          ),
                          if (_query.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                              child: Icon(Icons.close_rounded, size: 16, color: c.faint),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final cat in categories.toList()..sort())
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _chip(cat, _category == cat, () {
                                setState(() => _category = cat);
                              }),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              sliver: list.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: EmptyState(
                          title: _query.isEmpty ? 'No recipes yet' : 'Nothing matches',
                          body: _query.isEmpty
                              ? 'Add recipes in Mealie and they show up here, with images.'
                              : 'Try a shorter word, or clear the filter.',
                          icon: Icons.menu_book_outlined,
                        ),
                      ),
                    )
                  : SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.68,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _RecipeCard(store: store, recipe: list[i]),
                        childCount: list.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: active ? c.ink : Colors.transparent,
          border: Border.all(color: active ? c.ink : c.line),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: active ? c.bg : c.muted,
          ),
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.store, required this.recipe});

  final AppStore store;
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(store: store, recipe: recipe),
      )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: RecipePhoto(store: store, recipe: recipe),
            ),
          ),
          const SizedBox(height: 9),
          // Reserve two lines so a long name cannot push the meta row out of
          // line with the card beside it.
          SizedBox(
            height: 35,
            child: Text(
              recipe.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.title.copyWith(fontSize: 14, height: 1.2),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (recipe.totalMinutes > 0) humanMinutes(recipe.totalMinutes),
              if (recipe.categories.isNotEmpty) recipe.categories.first.toLowerCase(),
            ].join(' · '),
            style: context.small.copyWith(fontSize: 11.5, color: c.faint),
          ),
        ],
      ),
    );
  }
}
