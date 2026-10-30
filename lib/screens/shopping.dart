import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../mealie.dart';
import '../theme.dart';
import '../widgets.dart';
import 'shell.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key, required this.store});

  final AppStore store;

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final _entry = TextEditingController();
  bool _addingWeek = false;

  AppStore get store => widget.store;

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _entry.text;
    if (text.trim().isEmpty) return;
    _entry.clear();
    HapticFeedback.selectionClick();
    try {
      await store.addItem(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is MealieException ? e.message : 'Could not add that.'),
        ));
      }
    }
  }

  Future<void> _addWeek() async {
    final today = DateTime.now();
    final cutoff = today.add(const Duration(days: 7));
    final ids = <String>{};
    final week = <Recipe>[];
    for (final p in store.plans) {
      final d = DateTime.tryParse(p.date);
      final r = p.recipe;
      if (d == null || r == null) continue;
      if (d.isBefore(DateTime(today.year, today.month, today.day))) continue;
      if (d.isAfter(cutoff)) continue;
      if (ids.add(r.id)) week.add(r);
    }
    if (week.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing planned in the next week.')),
      );
      return;
    }
    setState(() => _addingWeek = true);
    var added = 0;
    for (final r in week) {
      try {
        added += await store.addRecipeToShopping(r);
      } catch (_) {}
    }
    if (mounted) {
      setState(() => _addingWeek = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(added > 0
            ? 'Added $added items from ${week.length} recipes'
            : 'Those ingredients are already on the list'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final open = store.items.where((i) => !i.checked).toList();
    final done = store.items.where((i) => i.checked).toList();

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
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
                          Text(store.listName.toUpperCase(),
                              style: context.label.copyWith(letterSpacing: 1.8)),
                          const SizedBox(height: 6),
                          Text('The list',
                              style: context.display.copyWith(fontSize: 30)),
                        ],
                      ),
                    ),
                    SettingsButton(store: store),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.only(left: 12, right: 4),
                        decoration: BoxDecoration(
                          color: c.surface,
                          border: Border.all(color: c.line),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add_rounded, size: 18, color: c.faint),
                            const SizedBox(width: 6),
                            Expanded(
                              child: TextField(
                                controller: _entry,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _add(),
                                style: context.body.copyWith(fontSize: 14.5),
                                cursorColor: c.ember,
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: 'Add an item',
                                  hintStyle: context.body
                                      .copyWith(color: c.faint, fontSize: 14.5),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _add,
                              child: Container(
                                width: 34,
                                height: 34,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: c.ember,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.arrow_forward_rounded,
                                    size: 16, color: c.emberInk),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _addingWeek ? null : _addWeek,
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.surfaceAlt,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: _addingWeek
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: c.sage),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.playlist_add_rounded,
                                  size: 17, color: c.sage),
                              const SizedBox(width: 8),
                              Text(
                                'Add this week’s ingredients',
                                style: context.title.copyWith(
                                    fontSize: 13.5, color: c.sage),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
          Expanded(
            child: store.items.isEmpty
                ? const EmptyState(
                    title: 'Empty basket',
                    body: 'Add items above, or pull in everything the week needs.',
                    icon: Icons.shopping_basket_outlined,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                    children: [
                      for (var i = 0; i < open.length; i++)
                        _ItemRow(store: store, item: open[i]),
                      if (done.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        SectionLabel('In the basket',
                            trailing: Text('${done.length}',
                                style: context.mono
                                    .copyWith(fontSize: 11, color: c.faint))),
                        const SizedBox(height: 4),
                        for (final item in done) _ItemRow(store: store, item: item),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.store, required this.item});

  final AppStore store;
  final ShoppingItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 8),
        child: Icon(Icons.delete_outline_rounded, size: 19, color: c.danger),
      ),
      onDismissed: (_) => store.removeItem(item),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          store.toggleItem(item);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 21,
                height: 21,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: item.checked ? c.sage : Colors.transparent,
                  border: Border.all(
                      color: item.checked ? c.sage : c.line, width: 1.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: item.checked
                    ? Icon(Icons.check_rounded, size: 14, color: c.bg)
                    : null,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  item.label,
                  style: context.body.copyWith(
                    fontSize: 15,
                    color: item.checked ? c.faint : c.ink,
                    decoration: item.checked ? TextDecoration.lineThrough : null,
                    decorationColor: c.faint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
