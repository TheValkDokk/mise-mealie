# Mealie community

The highest-intent audience anywhere: people who already run the server, will
find the bugs, and are the ones who answer "is there an app for this?" in every
other thread. Post here first, the day you ship.

## 1. GitHub Discussions → **Show and tell**

https://github.com/mealie-recipes/mealie/discussions/categories/show-and-tell

**Title**

```
Mise — a GPL-3.0 mobile client (Android APK + iOS source), built around cook mode
```

**Body**

> I've been running Mealie for a while and built a mobile client for my own
> kitchen; posting it here because this is where the people who'd find its bugs
> are.
>
> **What it is:** a Flutter client for Android 8+ and iOS 16+ that talks to the
> public v3 API — no account, no telemetry, no server of mine. GPL-3.0, APK on
> GitHub Releases, iOS from source.
>
> - Tonight's plan as a full-bleed card, the week beneath it, shopping status
> - Cookbook search + category filters, photography-first grid
> - **Cook mode**: one step at a time, 26pt type, black screen, the whole surface
>   is a tap target
> - Shopping list with "add this week's ingredients" — every recipe on the next
>   seven days of the plan, one request per recipe, duplicates skipped
> - Demo mode with six seeded recipes so it's reviewable without a server
>
> **API notes for anyone else writing a client** (all found by running against
> 3.29.0, none of which my mock server caught):
>
> - `POST /api/recipes` with a full payload returns 201 and creates a stub recipe
>   named `1 Cup Flour`. The real data needs a `PUT /api/recipes/{slug}`.
> - Ingredient refs accept flat `unitId`/`foodId`, or nested `{id, name}` objects.
>   `{id}` alone 500s with "Expected 'id' to be provided for unit".
> - `/api/app/about` in v3 has no `appname` field — a handshake check against it
>   rejects a real server.
> - `/api/auth/token` is form-encoded only; a JSON body returns `Unauthorized`.
> - Images live at `/api/media/recipes/{id}/images/original.webp` and need the
>   bearer token.
>
> **Honest gaps:** read-only cookbook (no recipe editing), writes need the
> network, one shopping list, no refresh token so the ~48h JWT means re-signing
> in, and it hasn't been on a physical device yet.
>
> Repo: https://github.com/TheValkDokk/mise-mealie — issues welcome, and I'd
> especially like to know which of multi-list / offline queue / step timers
> matters most.
>
> Not affiliated with the project; happy to move or remove this if it belongs
> elsewhere.

## 2. Discord → #showcase (or the closest channel)

Short version, one message, screenshot attached, no link-dump:

> Built a mobile client for my own kitchen over the last while — GPL-3.0, Android
> APK + iOS from source, talks to the v3 API only. Cook mode is the part I care
> about: one step, 26pt, tap anywhere to advance. Shopping has a "whole week's
> ingredients" button. Demo mode if you want to look without pointing it at your
> server.
>
> Repo: https://github.com/TheValkDokk/mise-mealie
>
> Two API things that cost me a day, in case anyone else is writing a client:
> `POST /api/recipes` creates a stub named "1 Cup Flour" unless you PUT after,
> and ingredient refs need `{id, name}` not `{id}`.

## 3. The threads that keep coming back

Search the repo and Discussions for these, and answer as a person, not a bot:

- "Android app?" / "iOS app?" / "is there a mobile client" — the recurring
  question. Answer with what exists **including the competitors**, then Mise as
  the GPL option. Naming Ghee first is what makes the mention credible.
- "PWA vs app" — say what the PWA does well before saying what cook mode adds.
- "client for iOS that isn't paid" — the exact query Mise answers.

## Etiquette

- One post, one Discord message. Do not bump.
- If a maintainer says third-party clients belong elsewhere, move without
  arguing — the thread itself is worth more than the venue.
- Reply to every bug report with a commit hash, not "noted".
