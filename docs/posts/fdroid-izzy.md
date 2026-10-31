# Getting Mise into F-Droid and IzzyOnDroid

Both repos read the `fastlane/` tree that is now committed, so the listing copy,
icon, banner and screenshots are under your control and update with each release.
Nothing here needs an account except the two submissions at the end.

## What is already in the repo

```
fastlane/metadata/android/en-US/
├── title.txt                 28/30 chars
├── short_description.txt     75/80 chars, no trailing dot
├── full_description.txt      1,909/3,700 chars (safe margin under the 4,000 limit)
├── changelogs/1.txt          416/500 bytes, ASCII — the versionCode 1 changelog
└── images/
    ├── icon.png              512×512
    ├── featureGraphic.png    1024×500
    └── phoneScreenshots/     1..5.png, each padded to exactly 2:1
```

Regenerate and re-validate any time with:

```bash
python3 tool/make_store_metadata.py
```

It fails the build rather than shipping a file that a store will reject: title
over 30 chars, a short description with a trailing dot, a changelog over 500
bytes or with non-ASCII, an icon outside 48–512 px, a banner that isn't
1024×500/512×250, or a screenshot taller than 2:1.

Screenshots are **padded, not cropped** — the 1206×2622 simulator frames are
2.17:1, and the store rule is 2:1, so each gets a matching-colour margin rather
than losing the bottom of the UI. That is why they are 783×1565, not 720-wide.

## IzzyOnDroid first (days, not weeks)

Izzy's repo serves the APK you already publish — no source build, no recipe.
It is where the self-hosted Android crowd actually installs from, and it gets
Mise in front of them while F-Droid is still reviewing.

**Where**: an "App inclusion" issue on https://codeberg.org/IzzyOnDroid/repodata/issues
(Codeberg account required; their docs point at that tracker).

**Request body**

> App: Mise — Mealie recipe planner
> Repo: https://github.com/TheValkDokk/mise-mealie
> Latest release: https://github.com/TheValkDokk/mise-mealie/releases/tag/v1.0.0
> License: GPL-3.0
>
> A client for Mealie, the self-hosted recipe manager and meal planner. Tonight's
> plan, cookbook, cook mode and the shopping list. No account, no analytics, no
> third-party SDK; the only traffic is to the server the user enters.
>
> Fastlane metadata is in the repo at `fastlane/metadata/android/en-US/`
> (title, short and full description, icon, feature graphic, five phone
> screenshots, changelog for versionCode 1).
>
> APK: arm64 18.7 MB, armeabi-v7a 16.1 MB — both under your 30 MB limit.
> Tags match versionName (`v1.0.0`).

The checks their reviewers will run, and where Mise stands:

- **FOSS licence** — GPL-3.0, `LICENSE` in the repo root. ✅
- **Fastlane present and correct** — validated by `tool/make_store_metadata.py`. ✅
- **Releases tagged, tag matches versionName** — `v1.0.0`, `version: 1.0.0+1`. ✅
- **APK attached and under 30 MB** — yes, both ABIs. ✅
- **No unexpected network calls** — the only host is the one typed into the
  connect screen; worth saying so in the issue, because reviewers watch for
  connections to Google/Firebase. ✅
- **On-device test** — they may ask for one; it has only been on a simulator so
  far, which is worth stating rather than being caught by.

## F-Droid (weeks — needs a recipe and a source build)

F-Droid builds from source on their own infrastructure, so it needs a recipe in
[fdroiddata](https://gitlab.com/fdroid/fdroiddata). Their Flutter template is
`templates/build-flutter.yml`; the recipe below is that template with Mise's
real values. Submit it as a merge request adding
`metadata/com.valk.mise.yml`.

```yaml
Categories:
  - Recipe Manager
  - Shopping List
License: GPL-3.0-only
WebSite: https://github.com/TheValkDokk/mise-mealie
SourceCode: https://github.com/TheValkDokk/mise-mealie
IssueTracker: https://github.com/TheValkDokk/mise-mealie/issues
RepoType: git
Repo: https://github.com/TheValkDokk/mise-mealie.git

Builds:
  - versionName: 1.0.0
    versionCode: 1
    commit: v1.0.0
    srclibs:
      - flutter@stable
    rm:
      - ios
      - linux
      - macos
      - web
      - windows
    prebuild:
      # The Flutter pin lives in CI so there is one source of truth.
      - flutterVersion=$(sed -n -E "s/.*flutter-version: '(.*)'/\1/p" .github/workflows/ci.yml | head -1)
      - '[[ $flutterVersion ]]'
      - git -C $$flutter$$ checkout -f $flutterVersion
      - export PUB_CACHE=$(pwd)/.pub-cache
      - $$flutter$$/bin/flutter config --no-analytics
      - $$flutter$$/bin/flutter pub get --enforce-lockfile
    scanignore:
      - .flutter/bin/cache
    scandelete:
      - .flutter
      - .pub-cache
    build:
      - export PUB_CACHE=$(pwd)/.pub-cache
      - $$flutter$$/bin/flutter build apk --release --target-platform android-arm64

AutoUpdateMode: Version
UpdateCheckMode: Tags
UpdateCheckData: pubspec.yaml|version:\s.+?\+(\d+)|.|version:\s(.+)\+
CurrentVersion: 1.0.0
CurrentVersionCode: 1
```

Why each non-obvious line:

- `srclibs: flutter@stable` + checking out the pinned version, instead of a git
  submodule, keeps the upstream repo clean. F-Droid's template supports both;
  only use one. If the template's `.flutter/bin/flutter` paths get copied in
  alongside `$$flutter$$`, the build fails — pick srclib **or** submodule.
- `rm:` the non-Android platforms so the scan doesn't walk iOS pods and macOS
  build files.
- `scanignore`/`scandelete` the Flutter SDK and pub cache: they contain binaries
  and downloaded Dart tooling that would otherwise trip the scanner.
- `--enforce-lockfile` makes the build fail if `pubspec.lock` and
  `pubspec.yaml` disagree, which is what you want in a reproducible build.
- `UpdateCheckData` reads `version: 1.0.0+1` from pubspec; `%c` is the number
  after the `+`, so no `VercodeOperation` scaling is needed (the template uses
  `*10` only because it splits per ABI into three APKs; Mise builds one).

**Expect the first build to fail.** Flutter on F-Droid's buildserver is the hard
part: the SDK checkout, engine artifact download, and Gradle's network access
all have to survive their sandbox. A reviewer will usually help iterate — the
realistic timeline is two to six weeks and at least one round of fixes. Izzy is
the release valve meanwhile.

## Order

1. **Today**: open the Izzy inclusion issue (APK already exists).
2. **Same day**: comment in the Mealie community threads that an F-Droid/Izzy
   listing is pending — people ask for exactly that.
3. **This week**: open the fdroiddata MR with the recipe above, and say in it
   that you are the upstream author and will fix build issues on request.
4. **When both are live**: add the badges to the README and mention the store in
   the next release notes. Do not resubmit for every release — F-Droid
   auto-updates from tags (`AutoUpdateMode: Version`).

## What would make this smoother

- A device test before submission. The APKs have only run on a simulator; a
  reviewer finding a launch crash is the slowest possible feedback loop.
- A 60-second screen recording of cook mode, which is easier to accept than a
  description of it.
- If F-Droid's build fails on the Flutter pin, the fallback is a `.flutter` git
  submodule in this repo and `submodules: true` in the recipe — uglier upstream,
  but it is the path their template documents first.
