# r/Mealie

The best audience that exists for this — people who already run the server, and
who are vocal about clients. Expect 15–30 comments and at least one person who
knows the API better than you.

Post from your own account, disclose authorship in the first line, and answer
everyone for the first day.

**Timing**: weekday, 08:00–10:00 US Eastern (21:00–23:00 your time). The sub is
small enough that a single good thread stays visible for two days.

## Title

```
Mise — a GPL-3.0 Mealie client built around cook mode (Android APK, iOS from source)
```

## Body

> **Disclosure: I made this.** Free, no ads, no account, GPL-3.0.
>
> I've been running Mealie for a while and the thing that kept failing for me
> wasn't browsing recipes — it was the twenty minutes at the stove. So I built
> Mise around that: cook mode is one step at a time, 26pt type, black screen, and
> the whole surface is a tap target, so you can advance with the back of a
> knuckle instead of aiming at a button with a wet thumb.
>
> The rest:
>
> - **Tonight** — today's plan as a full-bleed card, the week under it, and the
>   state of the list.
> - **Cookbook** — search + category filters, two-up, photography first.
> - **Shopping** — unchecked, then in-the-basket. There's an "add this week's
>   ingredients" button that takes every recipe on the next seven days of the
>   plan and puts their shopping in the list: one request per recipe, duplicates
>   skipped.
> - Demo mode with six recipes, so you can look before pointing it at your server.
>
> No telemetry, no server of mine; it only talks to your instance. Android 8+,
> iOS 16+, APK on GitHub Releases (no Play Store), iOS from source.
>
> I know the field isn't empty — Ghee, Mealie Go, Meshi Plan, Mealient. The two
> reasons this exists anyway: GPL-3.0 means it can't turn into a paid app later,
> and I wanted a client where cooking was the point rather than a feature on a
> list.
>
> Honest about what isn't there: read-only (no recipe creation/editing), writes
> need the network, one shopping list, and the token lapses after ~48h and asks
> you to sign in again. Multi-list and an offline write queue are next.
>
> https://github.com/TheValkDokk/mise-mealie
>
> If you try it: what's the one thing you'd need before it replaces the web UI on
> your phone?

## Reply ammunition

**"Why another client? Ghee already does this."**
> Ghee's good — and free, which is more than most of the iOS options. I wanted a
> licence that prevents a paywall later, and cook mode at the centre. If Ghee
> fits you better, use it; I'd rather have that conversation than pretend the gap
> was empty.

**"Does it do X?"** (offline, scaling, timers, tags, imports)
> Answer with the truth and a decision, not a maybe. Today: read-only, no scaling,
> no timers, no import. "Timers in steps" is the single most requested thing on
> every client's thread, so it's a fair bet for the next version — but don't
> promise it in the post.

**"Is it on the Play Store / App Store?"**
> No. APK on Releases, iOS from source. Store review for a client that talks to
> an arbitrary user-supplied server is a fight I'd lose slowly.

**"Mealie's API always breaks my client — how did you handle it?"**
> Point them at `test/live_mealie_test.dart`. The useful bit for anyone writing
> one: `POST /api/recipes` returns 201 and stores a stub called "1 Cup Flour" —
> you must PUT afterwards. Ingredient refs need flat `unitId`/`foodId` or nested
> `{id, name}`; `{id}` alone 500s. And `/api/app/about` in v3 has no `appname`,
> which broke my handshake check.

**"Can you add recipe import from URL?"**
> Mealie's own `/api/recipes/create/url` returned `BAD_RECIPE_DATA` on a normal
> recipe blog when I tested it, so an importer in the app would be a thin wrapper
> around something that doesn't reliably work yet. It belongs server-side first.

**Mod risk**: r/Mealie allows dev posts from regulars; a brand-new account
posting a link reads as spam. If your account has no history here, comment in a
few threads first — genuinely, not with "great post!" — then post.
