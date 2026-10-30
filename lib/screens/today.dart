import 'package:flutter/material.dart';

import '../mealie.dart';
import '../theme.dart';
import '../widgets.dart';
import 'recipe_detail.dart';
import 'shell.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({
    super.key,
    required this.store,
    required this.onShop,
    required this.onBrowse,
  });

  final AppStore store;
  final VoidCallback onShop;
  final VoidCallback onBrowse;

  String _d(DateTime x) =>
      '${x.year.toString().padLeft(4, '0')}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final now = DateTime.now();
    final today = _d(now);

    final todays = store.plans.where((p) => p.date == today).toList()
      ..sort((a, b) => a.type.compareTo(b.type));
    final tonight = todays.where((p) => p.type == 'dinner').firstOrNull ??
        todays.firstOrNull;
    final later = store.plans
        .where((p) => p.date.compareTo(today) > 0)
        .take(4)
        .toList();

    final open = store.items.where((i) => !i.checked).length;
    final total = store.items.length;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: c.ember,
        onRefresh: () => store.sync(full: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(longDate(now).toUpperCase(),
                          style: context.label.copyWith(letterSpacing: 1.8)),
                      const SizedBox(height: 6),
                      Text(
                        store.demo ? 'Demo kitchen' : 'Your kitchen',
                        style: context.display.copyWith(fontSize: 30),
                      ),
                    ],
                  ),
                ),
                SettingsButton(store: store),
              ],
            ),
            if (store.error != null) ...[
              const SizedBox(height: 14),
              _errorBanner(context, store),
            ],
            const SizedBox(height: 20),
            if (tonight != null && tonight.recipe != null)
              _TonightCard(store: store, entry: tonight)
            else
              _NothingPlanned(onBrowse: onBrowse),
            const SizedBox(height: 26),
            SectionLabel('Next up'),
            const SizedBox(height: 10),
            if (later.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('The rest of the week is open.',
                    style: context.small),
              )
            else
              ...later.map((e) => _PlanRow(store: store, entry: e)),
            const SizedBox(height: 22),
            _ShopStrip(
              open: open,
              total: total,
              listName: store.listName,
              onTap: onShop,
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorBanner(BuildContext context, AppStore store) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: c.ember.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.ember.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 16, color: c.ember),
          const SizedBox(width: 10),
          Expanded(
            child: Text(store.error!, style: context.small.copyWith(color: c.ember)),
          ),
          GestureDetector(
            onTap: () => store.sync(full: true),
            child: Text('Retry',
                style: context.small.copyWith(
                    color: c.ember, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _TonightCard extends StatelessWidget {
  const _TonightCard({required this.store, required this.entry});

  final AppStore store;
  final MealEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final recipe = entry.recipe!;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(store: store, recipe: recipe),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 0.86,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RecipePhoto(store: store, recipe: recipe, dark: true),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      c.scrim.withValues(alpha: 0.10),
                      c.scrim.withValues(alpha: 0.15),
                      c.scrim.withValues(alpha: 0.86),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                top: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.ember,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'TONIGHT · ${mealTypeLabel(entry.type).toUpperCase()}',
                    style: context.label.copyWith(
                        color: c.emberInk, fontSize: 9.5, letterSpacing: 1.2),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: context.display.copyWith(
                        color: Colors.white,
                        fontSize: 29,
                        height: 1.02,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _meta(Icons.schedule_rounded, humanMinutes(recipe.totalMinutes)),
                        const SizedBox(width: 14),
                        _meta(Icons.people_outline_rounded,
                            recipe.servings > 0 ? '${recipe.servings.toInt()} servings' : 'serves 2'),
                        const SizedBox(width: 14),
                        if (recipe.categories.isNotEmpty)
                          _meta(Icons.local_fire_department_outlined,
                              recipe.categories.first),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.white70),
        const SizedBox(width: 5),
        Text(text,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 11.5,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _NothingPlanned extends StatelessWidget {
  const _NothingPlanned({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nothing planned tonight', style: context.headline.copyWith(fontSize: 20)),
          const SizedBox(height: 6),
          Text('Pick something from your recipes and it lands here.',
              style: context.small),
          const SizedBox(height: 16),
          EmberButton(label: 'Browse recipes', height: 46, onPressed: onBrowse),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.store, required this.entry});

  final AppStore store;
  final MealEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final recipe = entry.recipe;
    return GestureDetector(
      onTap: recipe == null
          ? null
          : () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    RecipeDetailScreen(store: store, recipe: recipe),
              )),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 56,
                height: 56,
                child: recipe == null
                    ? Container(color: c.surfaceAlt)
                    : RecipePhoto(store: store, recipe: recipe),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${dayLabel(entry.date, DateTime.now()).toUpperCase()} · ${mealTypeLabel(entry.type).toUpperCase()}',
                    style: context.label.copyWith(fontSize: 9.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.title.isEmpty ? (recipe?.name ?? 'Meal') : entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.title.copyWith(fontSize: 15),
                  ),
                ],
              ),
            ),
            if (recipe != null && recipe.totalMinutes > 0)
              Text(humanMinutes(recipe.totalMinutes),
                  style: context.small.copyWith(fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}

class _ShopStrip extends StatelessWidget {
  const _ShopStrip({
    required this.open,
    required this.total,
    required this.listName,
    required this.onTap,
  });

  final int open;
  final int total;
  final String listName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final done = total == 0 ? 0.0 : (total - open) / total;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_basket_outlined, size: 16, color: c.muted),
                const SizedBox(width: 8),
                Text(listName, style: context.title.copyWith(fontSize: 14)),
                const Spacer(),
                Text(
                  total == 0 ? 'empty' : '$open left',
                  style: context.small.copyWith(fontSize: 11.5),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 17, color: c.faint),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: done,
                minHeight: 5,
                backgroundColor: c.surfaceAlt,
                valueColor: AlwaysStoppedAnimation(c.sage),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              total == 0
                  ? 'Nothing on the list yet.'
                  : '${total - open} of $total in the basket',
              style: context.small.copyWith(fontSize: 11.5, color: c.faint),
            ),
          ],
        ),
      ),
    );
  }
}
