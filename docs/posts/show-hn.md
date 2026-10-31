# Show HN

**Submit**: Tue–Thu, 08:00–10:00 US Eastern. URL field = the repo, not the
release. Post the first comment yourself, immediately after submitting.

## Title

```
Show HN: Mise – a GPL-3.0 Mealie client that cannot be paywalled
```

Plainer alternative, sometimes scores better:

```
Show HN: A cooking-first mobile client for my self-hosted recipe server
```

## URL

```
https://github.com/TheValkDokk/mise-mealie
```

## First comment

> I run Mealie (self-hosted recipes + meal plan + shopping list) and kept using
> the web UI on my phone, which is fine right up until your hands are covered in
> flour. There are third-party clients already — Ghee is free and good — so the
> reason to build another one was narrower: I wanted one that structurally can't
> become a paid app later, and that is built around cooking rather than browsing.
>
> So: GPL-3.0, Android APK on Releases, iOS from source, no account, no
> analytics, talks only to your instance.
>
> What it does: tonight's dinner as a full-bleed card; cookbook search + filters;
> and cook mode — one step, 26pt type, black screen, the entire surface is a tap
> target so you can advance with a knuckle. Shopping has a "add this week's
> ingredients" button that pulls every recipe on the next seven days of the plan
> into the list in one request per recipe.
>
> The part worth reading: I wrote it against a mock server first, which only
> proves the client agrees with itself. Against a real Mealie 3.29 container,
> three things fell out that a mock would never have caught:
>
> - `POST /api/recipes` returns 201 with a full payload and stores a stub recipe
>   literally named "1 Cup Flour". You have to PUT the slug afterwards.
> - Ingredient refs want flat `unitId`/`foodId`, or nested `{id, name}`; `{id}`
>   alone 500s with "Expected 'id' to be provided for unit".
> - v3's `/api/app/about` has no `appname` field, so my "is this really Mealie?"
>   check rejected the real server.
>
> There are now seven live integration tests that assert server state *after*
> each write rather than the status code, because a 200 that changes nothing is
> the failure mode that makes an app look fine and be broken.
>
> Known gaps, plainly: read-only cookbook (no recipe editing), writes need the
> network with no offline queue, one shopping list, JWT lapses after ~48h and
> asks you to sign in again, and it hasn't been on a physical device yet.
>
> Happy to talk about any of it — especially the write-verification approach,
> which I think is the only transferable lesson here.

## Reply ammunition

**"Why not Ghee / Meshi Plan / Mealie Go?"**
> Ghee is good and free, genuinely. I wanted a client under a licence that makes
> a paywall impossible, and I wanted cook mode to be the centre of the app rather
> than a screen inside it. Different priorities, not a better app.

**"Mealie has a PWA, why bother?"**
> I used it for a year. It is a browser tab with a home-screen icon, and the
> problem at the stove is not "installability" — it's that a recipe page is a
> document and what you need mid-sauté is one instruction, huge.

**"Self-hosted apps shouldn't need an app store."**
> Agreed, which is why the Android build is an APK on GitHub Releases and iOS is
> built from source. No store account, no gatekeeper, no fee.

**"Another Flutter app."**
> Yes — one codebase, and the interesting work wasn't Flutter. It was finding out
> which of my own API assumptions were wrong. That's what the tests in the repo
> are for.

**"Read-only? That's half an app."**
> It is, deliberately. Mealie's recipe editor is a five-field form with image
> uploads and bulk ingredient parsing; rebuilding that on a phone would make the
> browsing worse. I'd rather do five things well.

**"How do you handle the JWT expiring?"**
> Badly, currently: the request fails, an error banner appears, you sign in
> again. A silent refresh with a stored refresh token is the next thing I build —
> Mealie's token endpoint returns `expires_in` but not a refresh token, so it
> needs a background re-auth with the credentials, which means deciding whether
> to keep them in the keychain. That's a security decision, not a coding one.

**"Self-promo."**
> Fair. I built it for my own kitchen and I'm posting it where people run Mealie
> because that's how the gaps get found.

## Rules that matter

- Answer every comment for the first six hours. Stars follow replies, not posts.
- Concede the competitor point immediately and specifically. "You're right, Ghee
  does that better" costs nothing and buys the rest of the thread.
- If someone reports a bug, fix it the same day and reply with the commit.
- Never edit the title to chase votes.
