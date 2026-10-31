# Blog post — A 200 OK that changes nothing

For dev.to / your own site. ~1,000 words. The point is the lesson, not the app;
the app is the proof. Post this a day or two after the launch threads, linking
from the comments rather than as a launch.

---

## A 200 OK that changes nothing: building a client for Mealie

I built a mobile client for Mealie, the self-hosted recipe manager. The Flutter
part was the easy half. Most of the time went to discovering that my assumptions
about the API were wrong in ways no error message would tell me.

Here is what that looked like, because it generalises to every client you will
ever write against a service you don't control.

### The mock always agrees with you

I started the way I always start: a small mock server, written from the same
mental model as the client. It was fast, it was convenient, and it was worthless
as a test, because a mock I write from my assumptions can only confirm my
assumptions. Every endpoint returned exactly the shape I expected, because I
wrote both sides.

Then I pointed the app at a real Mealie 3.29 container, and three things broke
within an hour.

### Trap 1: create means "make a shell"

My seed script did what the docs suggest — `POST /api/recipes` with a full
payload: name, ingredients, steps, times. The response was `201 Created`. The
recipe existed. It was called **"1 Cup Flour"**.

Mealie's create endpoint interprets an unstructured payload as a scraped recipe
fragment and derives a title from the first line. Your carefully built body is
accepted and then ignored; the real content has to arrive in a follow-up
`PUT /api/recipes/{slug}`. Nothing in the 201 says so.

The rule I now apply everywhere: **a create is a promise to read it back.** I
seed, then `GET` the slug and assert the field I actually set — the name, the
step count, the ingredient display string. If those don't match, the write
didn't happen, whatever the status code said.

### Trap 2: "id is required" for a field you supplied

Ingredient references in Mealie look like this:

```json
{ "quantity": 200, "unit": { "id": "..." }, "food": { "id": "..." } }
```

That fails with *"Expected 'id' to be provided for unit"* — while the id is
right there. The validator wants either flat `unitId` / `foodId`, or a
nested object carrying `{id, name}`. `{id}` alone is the one shape that fails,
and it's the one a reasonable person writes first.

Related: pass the flat ids and the recipe saves, but every ingredient renders as
a bare number, because the display string is computed from the referenced unit.
Nothing errors. Your recipe just looks broken to the person reading it.

### Trap 3: the handshake field doesn't exist

Kept from a previous client, I checked `/api/app/about` for `appname == "mealie"`
before accepting a server address. Mealie 3 returns:

```json
{ "production": true, "version": "v3.29.0", "demoStatus": false }
```

No `appname`. So my "is this really Mealie?" check rejected a real Mealie server
with *"That server does not look like Mealie."* — the most confidently wrong
error message I've written. The check now accepts the name if present and falls
back to `version`.

### Trap 4 (mine): 201 is not an error

My JSON helper was `if (r.statusCode == 200)`. Mealie answers `201` for creates
and `204` for deletes, so "plan this recipe" and "add this item" both failed with
`MealieException(201): Could not add to the plan (201)` — an error message whose
status code was the definition of success.

### What actually catches these

Not unit tests over the parser. Not a mock. A test suite that runs against a
real container and asserts **server state after the write**:

```dart
await api.setChecked(list.id, item, true);
final after = await api.shoppingList();
expect(after.items.firstWhere((i) => i.id == item.id).checked, isTrue);
```

That's the whole idea. A status code tells you the server accepted a request. It
does not tell you the server did anything. The two are only the same thing in a
mock.

There are seven of these in the repo — identity, recipe shapes, detail, plan,
check round-trip, add/delete round-trip, planning a recipe. They're skipped
unless `MEALIE_URL` is set, so `flutter test` still runs offline. The suite is
twenty minutes of work that has already caught three regressions.

### The app itself, briefly

Mise is a Mealie client for Android and iOS: tonight's dinner, the cookbook, cook
mode, and the shopping list. Cook mode is the part I care about — one step, 26pt
type, black screen, the whole surface a tap target, so you can advance it with a
knuckle when your hands are covered in flour. There's a button that takes every
recipe on the next seven days of the plan and puts its ingredients in the list.

It's GPL-3.0, no account, no analytics, and it talks only to the server you give
it. Android APK on GitHub Releases, iOS built from source. The field is crowded —
Ghee, Mealie Go, Meshi Plan and others exist, and Ghee is free — so the honest
reason to ship a fourth client is that GPL-3.0 makes a paywall structurally
impossible, and cooking is the centre of the design instead of a tab.

Known gaps: read-only cookbook, no offline write queue, one shopping list, and a
~48h JWT that means signing in again.

**Repo:** https://github.com/TheValkDokk/mise-mealie

### The transferable part

If you're writing a client against someone else's service:

1. Run the real thing before you write the UI. A day of container wrangling saves
   a week of debugging a screen that looks fine and lies.
2. After every write, read it back and assert a value you set. Treat 2xx as
   "received", not "done".
3. Validate the shape you'll actually receive, not the shape the docs promise.
   Optional fields are optional until they're the only field you relied on.
4. Write down the traps in the repo — the seed script and the tests are the
   documentation now, because the API will change and the comments will be what
   saves the next person.
