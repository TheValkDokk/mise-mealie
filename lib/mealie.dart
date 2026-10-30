import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MealieException implements Exception {
  MealieException(this.message, {this.status});
  final String message;
  final int? status;
  @override
  String toString() => 'MealieException($status): $message';
}

int minutesFromIso(Object? v) {
  if (v is! String || v.isEmpty) return 0;
  final m = RegExp(r'P(?:(\d+)D)?T?(?:(\d+)H)?(?:(\d+)M)?').firstMatch(v);
  if (m == null) return 0;
  final d = int.tryParse(m.group(1) ?? '') ?? 0;
  final h = int.tryParse(m.group(2) ?? '') ?? 0;
  final mi = int.tryParse(m.group(3) ?? '') ?? 0;
  return d * 1440 + h * 60 + mi;
}

String humanMinutes(int minutes) {
  if (minutes <= 0) return '—';
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h h' : '$h h $m';
}

class Recipe {
  Recipe({
    required this.id,
    required this.slug,
    required this.name,
    this.description = '',
    this.imageKey,
    this.totalMinutes = 0,
    this.servings = 0,
    this.categories = const [],
    this.tags = const [],
    this.ingredients = const [],
    this.steps = const [],
  });

  final String id;
  final String slug;
  final String name;
  final String description;
  final String? imageKey;
  final int totalMinutes;
  final double servings;
  final List<String> categories;
  final List<String> tags;
  final List<String> ingredients;
  final List<String> steps;

  bool get hasDetail => ingredients.isNotEmpty || steps.isNotEmpty;

  factory Recipe.fromJson(Map<String, dynamic> j) {
    List<String> names(Object? v) => (v is List)
        ? v
            .whereType<Map>()
            .map((e) => (e['name'] ?? '').toString())
            .where((e) => e.isNotEmpty)
            .toList()
        : const [];
    return Recipe(
      id: (j['id'] ?? '').toString(),
      slug: (j['slug'] ?? '').toString(),
      name: (j['name'] ?? 'Untitled').toString(),
      description: (j['description'] ?? '').toString(),
      imageKey: (j['image'] as String?)?.trim().isEmpty == true
          ? null
          : j['image'] as String?,
      totalMinutes: j['totalTimeSeconds'] is num
          ? ((j['totalTimeSeconds'] as num) / 60).round()
          : minutesFromIso(j['totalTime']),
      servings: (j['recipeServings'] as num?)?.toDouble() ?? 0,
      categories: names(j['recipeCategory']),
      tags: names(j['tags']),
    );
  }

  factory Recipe.fromDetail(Map<String, dynamic> j) {
    final base = Recipe.fromJson(j);
    final ings = (j['recipeIngredient'] as List? ?? [])
        .whereType<Map>()
        .map((e) {
          final display = (e['display'] ?? '').toString().trim();
          if (display.isNotEmpty) return display;
          final note = (e['note'] ?? '').toString();
          final food = (e['food'] is Map) ? (e['food']['name'] ?? '') : '';
          final unit = (e['unit'] is Map) ? (e['unit']['name'] ?? '') : '';
          final qty = e['quantity'];
          final q = (qty is num && qty > 0)
              ? (qty == qty.roundToDouble() ? qty.toInt().toString() : '$qty')
              : '';
          return [q, unit, food, note]
              .where((s) => s != null && s.toString().trim().isNotEmpty)
              .join(' ')
              .trim();
        })
        .where((e) => e.isNotEmpty)
        .toList();
    final steps = (j['recipeInstructions'] as List? ?? [])
        .whereType<Map>()
        .map((e) => (e['text'] ?? '').toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return Recipe(
      id: base.id,
      slug: base.slug,
      name: base.name,
      description: base.description,
      imageKey: base.imageKey,
      totalMinutes: base.totalMinutes,
      servings: base.servings,
      categories: base.categories,
      tags: base.tags,
      ingredients: ings,
      steps: steps,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'name': name,
        'description': description,
        'image': imageKey,
        'totalTimeSeconds': totalMinutes * 60,
        'recipeServings': servings,
        'recipeCategory': [for (final c in categories) {'name': c}],
        'tags': [for (final t in tags) {'name': t}],
        'recipeIngredient': [for (final i in ingredients) {'display': i}],
        'recipeInstructions': [for (final s in steps) {'text': s}],
      };
}

class MealEntry {
  MealEntry({
    required this.id,
    required this.date,
    required this.type,
    required this.title,
    this.recipeId,
    this.recipe,
  });

  final int id;
  final String date;
  final String type;
  final String title;
  final String? recipeId;
  final Recipe? recipe;

  factory MealEntry.fromJson(Map<String, dynamic> j) => MealEntry(
        id: (j['id'] as num?)?.toInt() ?? 0,
        date: (j['date'] ?? '').toString(),
        type: (j['entryType'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        recipeId: j['recipeId']?.toString(),
        recipe: j['recipe'] is Map
            ? Recipe.fromJson((j['recipe'] as Map).cast<String, dynamic>())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'entryType': type,
        'title': title,
        'recipeId': recipeId,
        'recipe': recipe?.toJson(),
      };
}

class ShoppingItem {
  ShoppingItem({
    required this.id,
    required this.note,
    required this.checked,
    this.quantity = 1,
    this.display = '',
  });

  final String id;
  final String note;
  bool checked;
  final num quantity;
  final String display;

  String get label => display.isNotEmpty ? display : note;

  factory ShoppingItem.fromJson(Map<String, dynamic> j) => ShoppingItem(
        id: (j['id'] ?? '').toString(),
        note: (j['note'] ?? '').toString(),
        checked: j['checked'] == true,
        quantity: (j['quantity'] as num?) ?? 1,
        display: (j['display'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'note': note,
        'checked': checked,
        'quantity': quantity,
        'display': display,
      };
}

class MealieApi {
  MealieApi({required String baseUrl, this.token})
      : base = _clean(baseUrl);

  final String base;
  String? token;

  static String _clean(String url) {
    var u = url.trim();
    if (!u.startsWith('http')) u = 'https://$u';
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  Map<String, String> get _auth => token == null
      ? {'Accept': 'application/json'}
      : {'Accept': 'application/json', 'Authorization': 'Bearer $token'};

  Uri _u(String path, [Map<String, String>? query]) =>
      Uri.parse('$base$path').replace(queryParameters: query);

  Future<Map<String, dynamic>> _json(http.Response r, {String what = ''}) async {
    // Mealie answers 201 for creates and 204 for deletes.
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final body = jsonDecode(utf8.decode(r.bodyBytes));
      if (body is Map<String, dynamic>) return body;
      if (body is List) return {'items': body};
      return {};
    }
    if (r.statusCode == 401 || r.statusCode == 403) {
      throw MealieException('Your session expired. Sign in again.',
          status: r.statusCode);
    }
    var message = 'Could not $what (${r.statusCode}).';
    try {
      final body = jsonDecode(utf8.decode(r.bodyBytes));
      if (body is Map && body['detail'] is String) message = body['detail'];
      if (body is Map && body['detail'] is Map) {
        message = (body['detail']['message'] ?? message).toString();
      }
    } catch (_) {}
    throw MealieException(message, status: r.statusCode);
  }

  Future<void> login(String email, String password) async {
    final r = await http
        .post(
          _u('/api/auth/token'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'username': email,
            'password': password,
            'grant_type': 'password',
            'remember_me': 'true',
          },
        )
        .timeout(const Duration(seconds: 20));
    final body = await _json(r, what: 'sign in');
    token = body['access_token']?.toString();
    if (token == null) throw MealieException('No token in the response.');
  }

  Future<Map<String, dynamic>> about() async {
    final r = await http.get(_u('/api/app/about')).timeout(const Duration(seconds: 15));
    return _json(r, what: 'reach the server');
  }

  Future<List<Recipe>> recipes({String search = '', int perPage = 100}) async {
    final r = await http
        .get(_u('/api/recipes', {
          'search': search,
          'page': '1',
          'perPage': '$perPage',
          'orderBy': 'name',
          'orderDirection': 'asc',
        }), headers: _auth)
        .timeout(const Duration(seconds: 30));
    final body = await _json(r, what: 'load recipes');
    return (body['items'] as List? ?? [])
        .whereType<Map>()
        .map((m) => Recipe.fromJson(m.cast<String, dynamic>()))
        .toList();
  }

  Future<Recipe> recipe(String slug) async {
    final r = await http
        .get(_u('/api/recipes/$slug'), headers: _auth)
        .timeout(const Duration(seconds: 30));
    return Recipe.fromDetail(await _json(r, what: 'open the recipe'));
  }

  Future<List<MealEntry>> plans(DateTime from, DateTime to) async {
    String d(DateTime x) =>
        '${x.year.toString().padLeft(4, '0')}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
    final r = await http
        .get(_u('/api/households/mealplans', {
          'start_date': d(from),
          'end_date': d(to),
          'page': '1',
          'perPage': '60',
        }), headers: _auth)
        .timeout(const Duration(seconds: 30));
    final body = await _json(r, what: 'load the meal plan');
    return (body['items'] as List? ?? [])
        .whereType<Map>()
        .map((m) => MealEntry.fromJson(m.cast<String, dynamic>()))
        .toList();
  }

  Future<({String id, String name, List<ShoppingItem> items})> shoppingList() async {
    final r = await http
        .get(_u('/api/households/shopping/lists', {'page': '1', 'perPage': '5'}),
            headers: _auth)
        .timeout(const Duration(seconds: 20));
    final body = await _json(r, what: 'load the shopping list');
    final lists = (body['items'] as List? ?? []).whereType<Map>().toList();
    if (lists.isEmpty) throw MealieException('No shopping list on this household.');
    final id = lists.first['id'].toString();
    final d = await http
        .get(_u('/api/households/shopping/lists/$id'), headers: _auth)
        .timeout(const Duration(seconds: 20));
    final detail = await _json(d, what: 'load the shopping list');
    final items = (detail['listItems'] as List? ?? [])
        .whereType<Map>()
        .map((m) => ShoppingItem.fromJson(m.cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => a.checked == b.checked ? 0 : (a.checked ? 1 : -1));
    return (
      id: id,
      name: (lists.first['name'] ?? 'Shopping').toString(),
      items: items
    );
  }

  Future<void> setChecked(String listId, ShoppingItem item, bool checked) async {
    final r = await http
        .put(
          _u('/api/households/shopping/items/${item.id}'),
          headers: {..._auth, 'Content-Type': 'application/json'},
          body: jsonEncode({
            'id': item.id,
            'shoppingListId': listId,
            'note': item.note,
            'quantity': item.quantity,
            'checked': checked,
          }),
        )
        .timeout(const Duration(seconds: 20));
    await _json(r, what: 'update the item');
  }

  Future<void> addItem(String listId, String note) async {
    final r = await http
        .post(
          _u('/api/households/shopping/items'),
          headers: {..._auth, 'Content-Type': 'application/json'},
          body: jsonEncode({
            'shoppingListId': listId,
            'note': note,
            'quantity': 1,
            'isFood': false,
          }),
        )
        .timeout(const Duration(seconds: 20));
    await _json(r, what: 'add the item');
  }

  Future<void> deleteItem(ShoppingItem item) async {
    final r = await http
        .delete(_u('/api/households/shopping/items/${item.id}'), headers: _auth)
        .timeout(const Duration(seconds: 20));
    await _json(r, what: 'remove the item');
  }

  Future<int> addRecipeToList(String listId, Recipe recipe) async {
    final r = await http
        .post(
          _u('/api/households/shopping/lists/$listId/recipe/${recipe.id}'),
          headers: {..._auth, 'Content-Type': 'application/json'},
          body: jsonEncode({'recipeId': recipe.id}),
        )
        .timeout(const Duration(seconds: 30));
    final body = await _json(r, what: 'add the recipe');
    return (body['listItems'] as List?)?.length ?? 0;
  }

  Future<void> plan(DateTime date, String type, Recipe recipe) async {
    String d(DateTime x) =>
        '${x.year.toString().padLeft(4, '0')}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
    final r = await http
        .post(
          _u('/api/households/mealplans'),
          headers: {..._auth, 'Content-Type': 'application/json'},
          body: jsonEncode({
            'date': d(date),
            'entryType': type,
            'recipeId': recipe.id,
            'title': recipe.name,
            'text': '',
          }),
        )
        .timeout(const Duration(seconds: 20));
    await _json(r, what: 'add to the plan');
  }

  String? imageUrl(Recipe r) => r.imageKey == null
      ? null
      : '$base/api/media/recipes/${r.id}/images/original.webp';

  Map<String, String> get imageHeaders =>
      token == null ? const {} : {'Authorization': 'Bearer $token'};
}

enum SyncPhase { idle, syncing, error }

class AppStore extends ChangeNotifier {
  AppStore._();

  static const _configKey = 'mise.config.v1';
  static const _cacheKey = 'mise.cache.v1';

  String baseUrl = '';
  String email = '';
  String? token;
  DateTime? expiresAt;
  bool demo = false;
  bool onboarded = false;
  bool dark = false;

  final List<Recipe> recipes = [];
  final List<MealEntry> plans = [];
  final List<ShoppingItem> items = [];
  String listId = '';
  String listName = 'Shopping';

  SyncPhase phase = SyncPhase.idle;
  String? error;
  DateTime? lastSync;

  MealieApi? _api;
  SharedPreferences? _prefs;
  Timer? _cacheTimer;

  bool get connected => demo || (baseUrl.isNotEmpty && token != null);
  bool get needsAuth => error != null && (error!.toLowerCase().contains('sign in') ||
      error!.toLowerCase().contains('expired'));

  static Future<AppStore> load() async {
    final store = AppStore._();
    store._prefs = await SharedPreferences.getInstance();
    final raw = store._prefs!.getString(_configKey);
    if (raw != null) {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      store.baseUrl = (m['baseUrl'] ?? '').toString();
      store.email = (m['email'] ?? '').toString();
      store.token = m['token']?.toString();
      store.expiresAt = m['expiresAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch((m['expiresAt'] as num).toInt());
      store.demo = m['demo'] == true;
      store.onboarded = m['onboarded'] == true;
      store.dark = m['dark'] == true;
    }
    final cached = store._prefs!.getString(_cacheKey);
    if (cached != null) {
      try {
        final m = jsonDecode(cached) as Map<String, dynamic>;
        store.recipes
          ..clear()
          ..addAll((m['recipes'] as List? ?? [])
              .whereType<Map>()
              .map((e) => Recipe.fromJson(e.cast<String, dynamic>())));
        store.plans
          ..clear()
          ..addAll((m['plans'] as List? ?? [])
              .whereType<Map>()
              .map((e) => MealEntry.fromJson(e.cast<String, dynamic>())));
        store.items
          ..clear()
          ..addAll((m['items'] as List? ?? [])
              .whereType<Map>()
              .map((e) => ShoppingItem.fromJson(e.cast<String, dynamic>())));
        store.listId = (m['listId'] ?? '').toString();
        store.listName = (m['listName'] ?? 'Shopping').toString();
        store.lastSync = m['savedAt'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch((m['savedAt'] as num).toInt());
      } catch (_) {}
    }
    if (store.demo && store.recipes.isEmpty) {
      store._seedDemo();
    }
    if (store.connected && !store.demo) {
      store._api = MealieApi(baseUrl: store.baseUrl, token: store.token);
    }
    return store;
  }

  MealieApi get api {
    final existing = _api;
    if (existing != null) return existing;
    final created = MealieApi(baseUrl: baseUrl, token: token);
    _api = created;
    return created;
  }

  // ---- connect -------------------------------------------------------------

  Future<void> connect({
    required String server,
    required String email,
    required String password,
  }) async {
    final api = MealieApi(baseUrl: server);
    final about = await api.about();
    // v3's /api/app/about has no appname; older builds do. Accept either.
    final named = (about['appname'] ?? '').toString().toLowerCase() == 'mealie';
    if (!named && !about.containsKey('version')) {
      throw MealieException('That server does not look like Mealie.');
    }
    await api.login(email.trim(), password);
    baseUrl = api.base;
    this.email = email.trim();
    token = api.token;
    expiresAt = DateTime.now().add(const Duration(hours: 47));
    demo = false;
    onboarded = true;
    error = null;
    _api = api;
    final me = await _self(api);
    if (me != null) this.email = (me['email'] ?? this.email).toString();
    await _saveConfig();
    notifyListeners();
    await sync();
  }

  Future<Map<String, dynamic>?> _self(MealieApi api) async {
    try {
      final r = await http.get(Uri.parse('${api.base}/api/users/self'),
          headers: {'Authorization': 'Bearer ${api.token}'});
      if (r.statusCode != 200) return null;
      return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> startDemo() async {
    demo = true;
    onboarded = true;
    baseUrl = 'demo';
    _seedDemo();
    await _saveConfig();
    _saveCache();
    notifyListeners();
  }

  Future<void> disconnect() async {
    demo = false;
    onboarded = false;
    baseUrl = '';
    email = '';
    token = null;
    expiresAt = null;
    _api = null;
    recipes.clear();
    plans.clear();
    items.clear();
    listId = '';
    lastSync = null;
    error = null;
    await _saveConfig();
    await _prefs?.remove(_cacheKey);
    notifyListeners();
  }

  Future<void> setDark(bool value) async {
    dark = value;
    await _saveConfig();
    notifyListeners();
  }

  // ---- sync ----------------------------------------------------------------

  Future<void> sync({bool full = false}) async {
    if (demo) {
      lastSync = DateTime.now();
      notifyListeners();
      return;
    }
    if (phase == SyncPhase.syncing) return;
    phase = SyncPhase.syncing;
    error = null;
    notifyListeners();
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final fresh = await api.recipes();
      final plan = await api.plans(today, today.add(const Duration(days: 13)));
      final list = await api.shoppingList();

      recipes
        ..clear()
        ..addAll(fresh);
      plans
        ..clear()
        ..addAll(plan..sort((a, b) => a.date.compareTo(b.date)));
      items
        ..clear()
        ..addAll(list.items);
      listId = list.id;
      listName = list.name;
      lastSync = now;
      phase = SyncPhase.idle;
      _saveCache();
    } on MealieException catch (e) {
      phase = SyncPhase.error;
      error = e.message;
    } catch (e) {
      phase = SyncPhase.error;
      error = 'Could not reach $baseUrl.';
    }
    notifyListeners();
  }

  Future<Recipe> open(Recipe r) async {
    if (r.hasDetail || demo) return r;
    final full = await api.recipe(r.slug);
    final i = recipes.indexWhere((x) => x.id == r.id);
    if (i >= 0) recipes[i] = full;
    _saveCache();
    notifyListeners();
    return full;
  }

  Future<void> toggleItem(ShoppingItem item) async {
    final next = !item.checked;
    item.checked = next;
    notifyListeners();
    if (demo) {
      _saveCache();
      return;
    }
    try {
      await api.setChecked(listId, item, next);
    } catch (_) {
      item.checked = !next;
      notifyListeners();
    }
    _saveCache();
  }

  Future<void> addItem(String note) async {
    final text = note.trim();
    if (text.isEmpty) return;
    if (demo) {
      items.add(ShoppingItem(id: 'demo-${DateTime.now().microsecondsSinceEpoch}',
          note: text, checked: false, display: text));
      _saveCache();
      notifyListeners();
      return;
    }
    await api.addItem(listId, text);
    await sync();
  }

  Future<void> removeItem(ShoppingItem item) async {
    items.removeWhere((e) => e.id == item.id);
    notifyListeners();
    if (!demo) {
      try {
        await api.deleteItem(item);
      } catch (_) {}
    }
    _saveCache();
  }

  Future<int> addRecipeToShopping(Recipe r) async {
    if (demo) return 0;
    final before = items.length;
    final count = await api.addRecipeToList(listId, r);
    await sync();
    return items.length - before > 0 ? items.length - before : count;
  }

  Future<void> planRecipe(Recipe r, DateTime date, String type) async {
    if (demo) {
      plans.add(MealEntry(
        id: DateTime.now().microsecondsSinceEpoch ~/ 1000,
        date: _dateString(date),
        type: type,
        title: r.name,
        recipeId: r.id,
        recipe: r,
      ));
      plans.sort((a, b) => a.date.compareTo(b.date));
      _saveCache();
      notifyListeners();
      return;
    }
    await api.plan(date, type, r);
    await sync();
  }

  // ---- storage -------------------------------------------------------------

  Future<void> _saveConfig() async {
    await _prefs?.setString(
      _configKey,
      jsonEncode({
        'baseUrl': baseUrl,
        'email': email,
        'token': token,
        'expiresAt': expiresAt?.millisecondsSinceEpoch,
        'demo': demo,
        'onboarded': onboarded,
        'dark': dark,
      }),
    );
  }

  void _saveCache() {
    _cacheTimer?.cancel();
    _cacheTimer = Timer(const Duration(milliseconds: 500), () {
      _prefs?.setString(
        _cacheKey,
        jsonEncode({
          'recipes': [for (final r in recipes) r.toJson()],
          'plans': [for (final p in plans) p.toJson()],
          'items': [for (final i in items) i.toJson()],
          'listId': listId,
          'listName': listName,
          'savedAt': (lastSync ?? DateTime.now()).millisecondsSinceEpoch,
        }),
      );
    });
  }

  @override
  void dispose() {
    _cacheTimer?.cancel();
    super.dispose();
  }

  // ---- demo fixtures -------------------------------------------------------

  void _seedDemo() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const pastaId = 'demo-pasta';
    final demoRecipes = <Recipe>[
      Recipe(
        id: pastaId,
        slug: 'garlic-butter-pasta',
        name: 'Garlic Butter Pasta',
        description: 'The one you make when the fridge is empty and it is already 8pm.',
        imageKey: 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=1200&q=80',
        totalMinutes: 20,
        servings: 2,
        categories: const ['Dinner'],
        tags: const ['weeknight', 'pasta'],
        ingredients: const [
          '200 g spaghetti', '4 clove garlic', '60 g butter',
          '30 g parmesan', '1 bunch parsley', '1 tsp chili flakes',
        ],
        steps: const [
          'Boil the pasta in well-salted water until just shy of al dente. Keep a mug of the water.',
          'Melt the butter with sliced garlic and chili flakes over low heat until fragrant, not brown.',
          'Add the pasta and a splash of the cooking water; toss hard until the sauce clings.',
          'Off the heat, stir in parmesan and chopped parsley. Season and serve immediately.',
        ],
      ),
      Recipe(
        id: 'demo-chicken',
        slug: 'sheet-pan-chicken',
        name: 'Sheet-Pan Chicken with Lemon Potatoes',
        description: 'One tray, no babysitting, and the potatoes cook in the schmaltz.',
        imageKey: 'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=1200&q=80',
        totalMinutes: 60,
        servings: 4,
        categories: const ['Dinner'],
        tags: const ['weeknight', 'one-pan'],
        ingredients: const [
          '8 piece chicken thighs', '800 g potatoes', '2 piece lemon',
          '4 clove garlic', '3 tbsp olive oil', '1 tbsp oregano',
        ],
        steps: const [
          'Heat the oven to 220C. Cut the potatoes into wedges and toss with oil, oregano and salt.',
          'Season the chicken generously and sit it skin-side up on the potatoes.',
          'Tuck in lemon halves and smashed garlic. Roast 40 to 45 minutes without touching it.',
          'Rest five minutes, then squeeze the roasted lemon over everything.',
        ],
      ),
      Recipe(
        id: 'demo-shakshuka',
        slug: 'shakshuka',
        name: 'Shakshuka',
        description: 'Eggs poached in a slow-cooked pepper and tomato sauce.',
        imageKey: 'https://images.unsplash.com/photo-1590412200988-a436970781fa?w=1200&q=80',
        totalMinutes: 35,
        servings: 2,
        categories: const ['Breakfast'],
        tags: const ['breakfast', 'vegetarian'],
        ingredients: const [
          '1 piece onion', '1 piece red pepper', '2 clove garlic',
          '400 g chopped tomatoes', '4 piece eggs', '1 tsp cumin',
          '1 tsp smoked paprika', '1 handful coriander',
        ],
        steps: const [
          'Soften onion and pepper in olive oil for 10 minutes; do not rush this part.',
          'Add garlic, cumin and paprika, then the tomatoes. Simmer 10 minutes until thick.',
          'Make four wells, crack in the eggs, cover and cook until the whites set.',
          'Scatter coriander and serve straight from the pan with bread.',
        ],
      ),
      Recipe(
        id: 'demo-miso',
        slug: 'miso-mushroom-rice-bowl',
        name: 'Miso Mushroom Rice Bowl',
        description: 'Deep savoury, twenty-five minutes, and better the next day.',
        imageKey: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=1200&q=80',
        totalMinutes: 25,
        servings: 2,
        categories: const ['Dinner'],
        tags: const ['vegetarian', 'rice'],
        ingredients: const [
          '300 g mixed mushrooms', '200 g rice', '2 tbsp white miso',
          '1 tbsp soy sauce', '1 tsp sesame oil', '2 piece spring onions',
        ],
        steps: const [
          'Cook the rice. While it steams, sear the mushrooms hard in a dry pan, then add oil.',
          'Whisk miso, soy and sesame with a little hot water into a loose dressing.',
          'Fold most of the dressing through the mushrooms off the heat.',
          'Serve over rice with spring onion and the rest of the dressing.',
        ],
      ),
      Recipe(
        id: 'demo-ragu',
        slug: 'slow-braised-beef-ragu',
        name: 'Slow-Braised Beef Ragu',
        description: 'Three hours of doing nothing, for a sauce that tastes like you did a lot.',
        imageKey: 'https://images.unsplash.com/photo-1551183053-bf91a1d81141?w=1200&q=80',
        totalMinutes: 185,
        servings: 6,
        categories: const ['Dinner'],
        tags: const ['weekend', 'batch'],
        ingredients: const [
          '1000 g beef shin', '2 piece onion', '2 piece carrot', '2 piece celery',
          '2 tbsp tomato paste', '400 g chopped tomatoes', '250 ml red wine', '1 piece bay leaf',
        ],
        steps: const [
          'Brown the beef in batches until properly dark. Remove it and lower the heat.',
          'Cook the soffritto in the same pan for 15 minutes until sweet and soft.',
          'Add tomato paste, then wine, and scrape the pan. Return the beef with tomatoes and bay.',
          'Cover and braise at 150C for 2.5 hours, or on the lowest hob flame, until it shreds.',
          'Break up the meat, reduce the sauce if loose, and season hard.',
        ],
      ),
      Recipe(
        id: 'demo-salad',
        slug: 'green-goddess-salad',
        name: 'Green Goddess Salad',
        description: 'Crunch, herbs, and a dressing that justifies owning a blender.',
        imageKey: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=1200&q=80',
        totalMinutes: 15,
        servings: 4,
        categories: const ['Lunch'],
        tags: const ['salad', 'quick'],
        ingredients: const [
          '1 piece iceberg lettuce', '1 piece cucumber', '1 bunch basil',
          '1 bunch parsley', '100 g yoghurt', '1 piece lemon', '2 tbsp olive oil',
        ],
        steps: const [
          'Blitz herbs, yoghurt, lemon juice and oil with salt until vivid green.',
          'Tear the lettuce and slice the cucumber thin.',
          'Dress at the last moment so it stays crisp.',
        ],
      ),
    ];

    recipes
      ..clear()
      ..addAll(demoRecipes);

    final byId = {for (final r in demoRecipes) r.id: r};
    plans
      ..clear()
      ..addAll([
        MealEntry(id: 1, date: _dateString(today), type: 'dinner',
            title: 'Garlic Butter Pasta', recipeId: pastaId, recipe: byId[pastaId]),
        MealEntry(id: 2, date: _dateString(today.add(const Duration(days: 1))),
            type: 'dinner', title: 'Sheet-Pan Chicken with Lemon Potatoes',
            recipeId: 'demo-chicken', recipe: byId['demo-chicken']),
        MealEntry(id: 3, date: _dateString(today.add(const Duration(days: 2))),
            type: 'breakfast', title: 'Shakshuka',
            recipeId: 'demo-shakshuka', recipe: byId['demo-shakshuka']),
        MealEntry(id: 4, date: _dateString(today.add(const Duration(days: 2))),
            type: 'dinner', title: 'Miso Mushroom Rice Bowl',
            recipeId: 'demo-miso', recipe: byId['demo-miso']),
        MealEntry(id: 5, date: _dateString(today.add(const Duration(days: 3))),
            type: 'dinner', title: 'Slow-Braised Beef Ragu',
            recipeId: 'demo-ragu', recipe: byId['demo-ragu']),
      ]);

    items
      ..clear()
      ..addAll([
        ShoppingItem(id: 'd1', note: 'garlic', checked: false, quantity: 2, display: '2 garlic'),
        ShoppingItem(id: 'd2', note: 'parmesan', checked: false, quantity: 150, display: '150 g parmesan'),
        ShoppingItem(id: 'd3', note: 'chicken thighs', checked: false, quantity: 8, display: '8 chicken thighs'),
        ShoppingItem(id: 'd4', note: 'potatoes', checked: true, quantity: 1, display: '1 kg potatoes'),
        ShoppingItem(id: 'd5', note: 'coriander', checked: false, quantity: 1, display: '1 bunch coriander'),
        ShoppingItem(id: 'd6', note: 'olive oil', checked: true, quantity: 1, display: '1 l olive oil'),
      ]);
    listName = 'This week';
    listId = 'demo';
    lastSync = DateTime.now();
  }

  static String _dateString(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
