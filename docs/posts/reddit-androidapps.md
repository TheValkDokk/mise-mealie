# r/androidapps

Rules that get a post removed if missed: the `[Dev]` tag in the title, a
**free / no ads / no IAP** statement in the body, and no Play Store link as the
only source. Link the release, not a redirect.

## Title

```
[Dev] Mise — free, ad-free, open-source client for your self-hosted Mealie server
```

## Body

> Mise is an Android + iOS client for [Mealie](https://mealie.io), the
> self-hosted recipe manager, meal planner and shopping list. **Free, no ads, no
> in-app purchases, no analytics, GPL-3.0.** Not on the Play Store — APKs are on
> GitHub Releases.
>
> You need your own Mealie instance to use it (there's a demo mode to look
> around). It's for people who'd rather own their recipes than rent them from a
> subscription service.
>
> **What's in it**
>
> - Tonight: today's dinner as a full-bleed card, the week under it, list status
> - Cookbook: search + category filters, two-up, photography first
> - **Cook mode**: one step, huge type, black screen, whole screen is a tap
>   target — built for the moment your hands are covered in flour
> - Shopping: unchecked then in-the-basket, swipe to remove, and one button that
>   pulls the week's planned recipes into the list
>
> **Android details**: Android 8+, arm64 + 32-bit APKs, no Play Services
> required, no background services, no wake locks. The only network traffic is to
> the server address you type in.
>
> Caveats I'd rather say up front: the cookbook is read-only, checking items
> needs the network, and the token expires every couple of days so you'll sign in
> again. It hasn't been run on a physical phone yet — only emulator/simulator.
>
> Repo / APKs: https://github.com/TheValkDokk/mise-mealie/releases
> Source: https://github.com/TheValkDokk/mise-mealie

## Reply ammunition

**"Why isn't it on Play?"**
> Two reasons: a client that connects to an arbitrary user-supplied server is
> awkward under Play policy, and I'd rather ship an APK than a store listing I
> have to maintain. F-Droid would be the natural home and it's on the list.

**"What does it do that the website doesn't?"**
> The website is a document you scroll. Cook mode is one instruction at a time at
> 26pt on a black screen, advanced by tapping anywhere. At the stove that's the
> whole difference.

**"Screenshots look nice — is it really free?"**
> GPL-3.0, source is right there. No account, no analytics SDK, no IAP. If I ever
> added a paid tier I'd have to fork my own app to do it.

**Mod risk**: r/androidapps removes posts that don't disclose dev status or that
look like an ad. The `[Dev]` tag plus "free, no ads" line covers it; don't add
promo language.
