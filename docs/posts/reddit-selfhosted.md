# r/selfhosted

**Do not make a standalone post.** New projects go in the current **weekly New
Project Megathread** (the sub moved to a weekly thread for exactly this), and a
removed post in a 500k+ sub is worse than no post at all. Rule 2 still applies
inside the thread: production-ready, documented, no ads for hosting.

Comment early in a *fresh* thread — a comment on page 20 of a week-old thread is
invisible.

## Comment to paste

> **Mise — a GPL-3.0 mobile client for Mealie (Android APK, iOS from source)**
>
> Self-hosted recipe manager + meal planner. I run Mealie and the web UI is fine
> on a laptop and painful at the stove, so I built a client around that moment:
> cook mode is one step, 26pt type, black screen, whole screen is a tap target so
> a floury knuckle can advance it.
>
> - Tonight / week plan / shopping list, all from your instance
> - "Add this week's ingredients" — every planned recipe's shopping into the list
>   in one action
> - demo mode with six recipes, no server needed to look
> - no account, no telemetry, no server of mine; GPL-3.0, APK on Releases
>
> The field isn't empty (Ghee, Mealie Go, Meshi Plan, Mealient) — the two reasons
> this exists: GPL-3.0 means it can't become a paid app later, and cooking is the
> centre of the design rather than a tab.
>
> Gaps: read-only cookbook, writes need network, one shopping list, ~48h JWT then
> re-auth. Not tested on a physical device yet.
>
> Build notes, since this crowd writes clients too: Mealie's `POST /api/recipes`
> returns 201 and silently stores a stub named "1 Cup Flour" unless you `PUT`
> afterwards, ingredient refs need flat `unitId`/`foodId` or nested `{id, name}`
> (`{id}` alone 500s), and v3's `/api/app/about` has no `appname`. I only found
> those by pointing a real container at it — my mock had passed everything.
>
> https://github.com/TheValkDokk/mise-mealie

## The higher-value play in the same sub

The megathread is where posting is *allowed*, not where it converts. Most of the
value is in comments on existing threads, which the rules do permit when
relevant: "recipe app for the family", "self-hosted meal planning", "what do you
run for groceries", "Mealie vs Tandoor". Answer the actual question first,
mention Mise once, and only where it fits. Never paste the block above into
those.

## Other subs worth a single, tailored post (not a copy-paste)

- **r/homelab** — server-owner audience, but allergic to app launches. Only if
  you have a story beyond the app (e.g. how the API client is tested).
- **r/FlutterDev** — pitch it as the engineering story: live-API tests, the
  silent-write bug, why `cached_network_image` needs bearer headers. Different
  post, same repo.
- **r/androidapps** — see `reddit-androidapps.md`; needs `[Dev]`.
