# Launch kit — Mise

Copy-paste posts for each channel, in the order that actually converts. Written
to be posted by **you**, from your accounts. Nothing here has been posted.

Read this whole page before the first one: the order matters more than the copy.

## The one-sentence position

> A GPL-3.0 Mealie client that cannot be paywalled, built around the twenty
> minutes you spend cooking instead of the ten you spend browsing.

Everything below is a variation on that. If a draft drifts into "Mealie has no
apps" — cut it. It is false and the replies will say so.

## The field, honestly

Checked 30 Oct 2026, before writing a word of copy:

- **Ghee** — free, Flutter, both platforms, cook mode with step checkoff, shopping
  sync, offline downloads, premium tier planned. The strongest competitor and the
  one people will name in your replies.
- **Meshi Plan**, **Kitchen Compass**, **Forked**, **Pocket for Mealie**,
  **Mealie Recipes**, **MealieSwift** — iOS.
- **Mealie Go**, **Mealie** (closed testing), **Mealient** (archived late 2024) — Android.

That list is why the pitch is licence + design, not novelty. "Another client"
gets ignored; "a client that structurally cannot charge you later" gets argued
about, which is better.

## Order of operations

1. **Mealie community first** (`mealie-community.md`) — GitHub Discussions →
   Show and tell, then Discord. Highest intent, no mod risk, and it is where the
   people who will actually file bugs are. Do this the day you ship.
2. **r/Mealie** (`reddit-mealie.md`) — small but the most concentrated audience
   that exists. Post on a weekday morning US time.
3. **Show HN** (`show-hn.md`) — Tue–Thu, 08:00–10:00 ET. Repo in the URL field.
4. **r/selfhosted** (`reddit-selfhosted.md`) — *comment in the current weekly New
   Project Megathread*, never a standalone post.
5. **r/androidapps** (`reddit-androidapps.md`) — needs the `[Dev]` tag and the
   free/no-ads line, or it gets removed.
6. **Blog / dev.to** (`blog-post.md`) — the engineering story, which keeps
   earning traffic long after the launch posts sink.
7. **Mastodon** (`mastodon-thread.md`) — any time; low stakes.

Spacing: one channel per day, not all at once. Each post's comments are the
actual product research, and you cannot answer five threads at once.

## What not to do

- Do not post the same link in two subs on the same day.
- Do not ask for upvotes, stars, or "feedback please" — ask a specific question
  ("is per-recipe *add to list* enough, or do you want the whole week?") and you
  get answers instead of silence.
- Do not claim it is offline-first. It is cached-read, online-write. The moment
  someone with a basement full of servers tests that claim, the thread turns.
- Do not answer "why not Ghee" defensively. The honest answer is in every file:
  Ghee is good and free; Mise is GPL and designed differently. Let people pick.
- Do not post to r/selfhosted as a standalone. Rule: new projects go in the
  weekly megathread, and a removal in a 500k+ sub is worse than no post.

## Assets

- Screenshots: `docs/screenshots/{today,recipes,recipe,list,cook}.png` (720 px).
- Repo: https://github.com/TheValkDokk/mise-mealie
- Release: https://github.com/TheValkDokk/mise-mealie/releases/tag/v1.0.0
- One APK to link in posts, not three: `Mise-1.0.0-arm64-v8a.apk`.

## If it flops

A Show HN that dies at 3 points is not a verdict; it is a timezone. The Mealie
Discussions post and the r/Mealie post are the ones that produce users, because
they reach people who already run the server. Judge those, not the front page.
