// Live integration test against a real Mealie instance.
//
//   MEALIE_URL=http://127.0.0.1:9000 MEALIE_EMAIL=admin@example.com \
//   MEALIE_PASS=password flutter test test/live_mealie_test.dart
//
// Skipped when MEALIE_URL is unset, so plain `flutter test` stays offline.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mise/mealie.dart';

void main() {
  final env = Platform.environment;
  final url = env['MEALIE_URL'];
  final configured = url != null &&
      env['MEALIE_EMAIL'] != null &&
      env['MEALIE_PASS'] != null;
  final skip = !configured ? 'MEALIE_URL not set' : false;

  group('live mealie', () {
    late MealieApi api;

    setUpAll(() async {
      if (!configured) return;
      api = MealieApi(baseUrl: url);
      await api.login(env['MEALIE_EMAIL']!, env['MEALIE_PASS']!);
    });

    test('the server identifies itself', () async {
      if (!configured) return;
      final about = await api.about();
      expect(about.containsKey('version'), isTrue);
      expect(about['version'].toString(), isNotEmpty);
    }, skip: skip);

    test('recipes parse with times, images and categories', () async {
      if (!configured) return;
      final recipes = await api.recipes();
      expect(recipes, isNotEmpty, reason: 'seed the server first');

      for (final r in recipes) {
        expect(r.id, isNotEmpty);
        expect(r.slug, isNotEmpty);
        expect(r.name, isNotEmpty);
      }
      // At least one recipe must carry a parsed duration; a broken
      // ISO-8601 parse shows up as a grid of "—".
      expect(recipes.any((r) => r.totalMinutes > 0), isTrue);
      expect(recipes.any((r) => r.imageKey != null), isTrue);
    }, skip: skip);

    test('recipe detail carries ingredients and steps', () async {
      if (!configured) return;
      final recipes = await api.recipes();
      final full = await api.recipe(recipes.first.slug);
      expect(full.ingredients, isNotEmpty);
      expect(full.steps, isNotEmpty);
      expect(full.ingredients.first.trim(), isNotEmpty);
    }, skip: skip);

    test('meal plan returns typed entries for the next week', () async {
      if (!configured) return;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final plans = await api.plans(today, today.add(const Duration(days: 7)));
      expect(plans, isNotEmpty, reason: 'seed the meal plan first');
      for (final p in plans) {
        expect(p.date, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
        expect(p.type, isNotEmpty);
        expect(p.recipe, isNotNull);
      }
    }, skip: skip);

    test('shopping item check round-trips through the server', () async {
      if (!configured) return;
      final list = await api.shoppingList();
      expect(list.items, isNotEmpty);
      final item = list.items.first;
      final before = item.checked;

      await api.setChecked(list.id, item, !before);
      final after = await api.shoppingList();
      expect(after.items.firstWhere((i) => i.id == item.id).checked, !before);

      await api.setChecked(list.id, item, before);
      final restored = await api.shoppingList();
      expect(restored.items.firstWhere((i) => i.id == item.id).checked, before);
    }, skip: skip);

    test('adding and deleting an item round-trips', () async {
      if (!configured) return;
      final list = await api.shoppingList();
      final before = list.items.length;
      await api.addItem(list.id, 'test item 8231');
      var after = await api.shoppingList();
      expect(after.items.length, before + 1);

      final created = after.items.firstWhere((i) => i.note == 'test item 8231');
      await api.deleteItem(created);
      after = await api.shoppingList();
      expect(after.items.length, before);
    }, skip: skip);

    test('planning a recipe shows up in the plan', () async {
      if (!configured) return;
      final recipes = await api.recipes();
      final now = DateTime.now();
      final target = now.add(const Duration(days: 9));
      await api.plan(target, 'dinner', recipes.last);

      final plans = await api.plans(target, target.add(const Duration(days: 1)));
      expect(plans.any((p) => p.title == recipes.last.name), isTrue);
    }, skip: skip);
  });
}
