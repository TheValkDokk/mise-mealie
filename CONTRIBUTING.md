# Contributing to Mise

A small client for a big app. Mise is not trying to be Mealie in a WebView — it
does five things a phone is good at, and nothing else.

## Run it

```bash
flutter pub get
flutter analyze
flutter run
```

No Mealie instance? The app has a demo mode (six recipes, a plan, a list), and
`tool/seed_mealie.py` fills a real server in one command:

```bash
docker run -d --name mealie -p 9000:9000 -e ALLOW_SIGNUP=true \
  -v mealie_data:/app/data ghcr.io/mealie-recipes/mealie:latest
python3 tool/seed_mealie.py http://127.0.0.1:9000 changeme@example.com MyPassword
flutter run --dart-define=CONNECT_URL=http://127.0.0.1:9000 \
  --dart-define=CONNECT_EMAIL=changeme@example.com \
  --dart-define=CONNECT_PASS=MyPassword
```

## Testing

`flutter test` runs offline. Anything that touches `lib/mealie.dart` should also
be checked against a live server:

```bash
MEALIE_URL=http://127.0.0.1:9000 MEALIE_EMAIL=... MEALIE_PASS=... \
flutter test test/live_mealie_test.dart
```

The important habit: assert the **state after the write**, never the status code.
Mealie (like most APIs) will happily answer 200 to a request it ignored.

## The demo recording

`integration_test/demo_tour_test.dart` drives a scripted tour (connect → cookbook
→ recipe → cook mode → list) so the README video can be re-recorded after a UI
change:

```bash
xcrun simctl io booted recordVideo --codec h264 --force /tmp/tour.mp4 &
flutter test integration_test/demo_tour_test.dart -d <simulator-udid>
kill -INT %1
ffmpeg -ss 25.5 -i /tmp/tour.mp4 -t 29.5 \
  -vf "fps=30,scale=720:-2" -c:v libx264 -crf 24 -movflags +faststart -an docs/demo.mp4
```

The trim offset is where the app first appears on screen; it moves when the
build gets faster or slower, so check a frame before publishing.

## Rules of the house

- **No telemetry, no analytics, no third-party SDKs.** The only network traffic
  is to the user's Mealie instance.
- **Cooking first.** Any screen that appears while someone is holding a hot pan
  must survive a wet thumb, a 26pt font, and one-hand reach.
- Keep the design language: warm paper, charcoal, one ember accent, photography
  doing the decoration. No gradients on chrome, no confetti.
- `dart format` before committing; don't reformat files you didn't touch.
- Mealie's API quirks are documented inline where they bit us (see
  `tool/seed_mealie.py` and `MealieApi.patch`-style comments). Add to those
  rather than working around them silently.

## Good first issues

- Multi-list support (household lists, not just the first)
- Offline write queue for shopping items and plan changes
- "Cook this" from a calendar entry without opening the recipe first
- Scale a recipe's ingredients when the household size changes
- Pull-to-refresh on the recipe page
- Translations (strings live in the widgets that use them)

## License

By contributing you agree your work is released under GPL-3.0.
