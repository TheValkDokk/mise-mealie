#!/usr/bin/env python3
"""Seed a fresh Mealie v3 instance with realistic data for Mise development.

    python3 tool/seed_mealie.py http://127.0.0.1:9000 admin@example.com 'password'

Creates six recipes with ingredients, steps and photos, a week of meal-plan
entries and a shopping list. Re-runnable: it removes and recreates its own
recipes by name, and skips plan/shopping rows that already exist.

Mealie's API has a two-step write: POST /api/recipes creates an empty shell and
returns its slug, then PUT /api/recipes/{slug} fills it in. Sending a full
payload to POST alone silently produces a stub ("1 Cup Flour").
"""
import datetime
import json
import ssl
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid

BASE = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:9000"
USER = sys.argv[2] if len(sys.argv) > 2 else "changeme@example.com"
PASS = sys.argv[3] if len(sys.argv) > 3 else "MyPassword"

RECIPES = [
    {
        "name": "Garlic Butter Pasta",
        "description": "The one you make when the fridge is empty and it is already 8pm.",
        "prep": 5, "cook": 15, "servings": 2,
        "tags": ["weeknight", "pasta"], "category": "Dinner",
        "ingredients": [
            (200, "g", "spaghetti"), (4, "clove", "garlic"), (60, "g", "butter"),
            (30, "g", "parmesan"), (1, "bunch", "parsley"), (1, "tsp", "chili flakes"),
        ],
        "steps": [
            "Boil the pasta in well-salted water until just shy of al dente. Keep a mug of the water.",
            "Melt the butter with sliced garlic and chili flakes over low heat until fragrant, not brown.",
            "Add the pasta and a splash of the cooking water; toss hard until the sauce clings.",
            "Off the heat, stir in parmesan and chopped parsley. Season and serve immediately.",
        ],
        "image": "https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=1200&q=80",
    },
    {
        "name": "Sheet-Pan Chicken with Lemon Potatoes",
        "description": "One tray, no babysitting, and the potatoes cook in the schmaltz.",
        "prep": 15, "cook": 45, "servings": 4,
        "tags": ["weeknight", "one-pan"], "category": "Dinner",
        "ingredients": [
            (8, "piece", "chicken thighs"), (800, "g", "potatoes"), (2, "piece", "lemon"),
            (4, "clove", "garlic"), (3, "tbsp", "olive oil"), (1, "tbsp", "oregano"),
        ],
        "steps": [
            "Heat the oven to 220C. Cut the potatoes into wedges and toss with oil, oregano and salt.",
            "Season the chicken generously and sit it skin-side up on the potatoes.",
            "Tuck in lemon halves and smashed garlic. Roast 40 to 45 minutes without touching it.",
            "Rest five minutes, then squeeze the roasted lemon over everything.",
        ],
        "image": "https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=1200&q=80",
    },
    {
        "name": "Shakshuka",
        "description": "Eggs poached in a slow-cooked pepper and tomato sauce. Breakfast that eats like dinner.",
        "prep": 10, "cook": 25, "servings": 2,
        "tags": ["breakfast", "vegetarian"], "category": "Breakfast",
        "ingredients": [
            (1, "piece", "onion"), (1, "piece", "red pepper"), (2, "clove", "garlic"),
            (400, "g", "chopped tomatoes"), (4, "piece", "eggs"), (1, "tsp", "cumin"),
            (1, "tsp", "smoked paprika"), (1, "handful", "coriander"),
        ],
        "steps": [
            "Soften onion and pepper in olive oil for 10 minutes; do not rush this part.",
            "Add garlic, cumin and paprika, then the tomatoes. Simmer 10 minutes until thick.",
            "Make four wells, crack in the eggs, cover and cook until the whites set.",
            "Scatter coriander and serve straight from the pan with bread.",
        ],
        "image": "https://images.unsplash.com/photo-1590412200988-a436970781fa?w=1200&q=80",
    },
    {
        "name": "Miso Mushroom Rice Bowl",
        "description": "Deep savoury, twenty-five minutes, and better the next day.",
        "prep": 10, "cook": 15, "servings": 2,
        "tags": ["vegetarian", "rice"], "category": "Dinner",
        "ingredients": [
            (300, "g", "mixed mushrooms"), (200, "g", "rice"), (2, "tbsp", "white miso"),
            (1, "tbsp", "soy sauce"), (1, "tsp", "sesame oil"), (2, "piece", "spring onions"),
        ],
        "steps": [
            "Cook the rice. While it steams, sear the mushrooms hard in a dry pan, then add oil.",
            "Whisk miso, soy and sesame with a little hot water into a loose dressing.",
            "Fold most of the dressing through the mushrooms off the heat.",
            "Serve over rice with spring onion and the rest of the dressing.",
        ],
        "image": "https://images.unsplash.com/photo-1512058564366-18510be2db19?w=1200&q=80",
    },
    {
        "name": "Slow-Braised Beef Ragu",
        "description": "Three hours of doing nothing, for a sauce that tastes like you did a lot.",
        "prep": 20, "cook": 165, "servings": 6,
        "tags": ["weekend", "batch"], "category": "Dinner",
        "ingredients": [
            (1000, "g", "beef shin"), (2, "piece", "onion"), (2, "piece", "carrot"),
            (2, "piece", "celery"), (2, "tbsp", "tomato paste"), (400, "g", "chopped tomatoes"),
            (250, "ml", "red wine"), (1, "piece", "bay leaf"),
        ],
        "steps": [
            "Brown the beef in batches until properly dark. Remove it and lower the heat.",
            "Cook the soffritto in the same pan for 15 minutes until sweet and soft.",
            "Add tomato paste, then wine, and scrape the pan. Return the beef with tomatoes and bay.",
            "Cover and braise at 150C for 2.5 hours, or on the lowest hob flame, until it shreds.",
            "Break up the meat, reduce the sauce if loose, and season hard.",
        ],
        "image": "https://images.unsplash.com/photo-1551183053-bf91a1d81141?w=1200&q=80",
    },
    {
        "name": "Green Goddess Salad",
        "description": "Crunch, herbs, and a dressing that justifies owning a blender.",
        "prep": 15, "cook": 0, "servings": 4,
        "tags": ["salad", "quick"], "category": "Lunch",
        "ingredients": [
            (1, "piece", "iceberg lettuce"), (1, "piece", "cucumber"), (1, "bunch", "basil"),
            (1, "bunch", "parsley"), (100, "g", "yoghurt"), (1, "piece", "lemon"),
            (2, "tbsp", "olive oil"),
        ],
        "steps": [
            "Blitz herbs, yoghurt, lemon juice and oil with salt until vivid green.",
            "Tear the lettuce and slice the cucumber thin.",
            "Dress at the last moment so it stays crisp.",
        ],
        "image": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=1200&q=80",
    },
]


def call(path, method="GET", body=None, token=None, form=False, timeout=90):
    headers = {}
    data = None
    if body is not None:
        if form:
            data = urllib.parse.urlencode(body).encode()
            headers["Content-Type"] = "application/x-www-form-urlencoded"
        else:
            data = json.dumps(body).encode()
            headers["Content-Type"] = "application/json"
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(BASE + path, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read()
            if not raw:
                return resp.status, None
            try:
                return resp.status, json.loads(raw)
            except json.JSONDecodeError:
                return resp.status, raw.decode(errors="replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode(errors="replace")[:300]


def upload_image(slug, url, token):
    ctx = ssl._create_unverified_context()
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=60, context=ctx) as r:
            img = r.read()
    except Exception as e:
        print("  image download failed", e)
        return
    boundary = "----mise" + uuid.uuid4().hex
    parts = [
        f'--{boundary}\r\nContent-Disposition: form-data; name="extension"\r\n\r\njpg\r\n'.encode(),
        (f'--{boundary}\r\nContent-Disposition: form-data; name="image"; filename="photo.jpg"\r\n'
         f'Content-Type: image/jpeg\r\n\r\n').encode() + img + b"\r\n",
        f"--{boundary}--\r\n".encode(),
    ]
    payload = b"".join(parts)
    req = urllib.request.Request(
        f"{BASE}/api/recipes/{slug}/image",
        data=payload,
        method="PUT",
        headers={
            "Content-Type": f"multipart/form-data; boundary={boundary}",
            "Authorization": f"Bearer {token}",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=90) as r:
            print("  image", r.status)
    except urllib.error.HTTPError as e:
        print("  image failed", e.code, e.read().decode()[:150])


_UNIT_CACHE = {}
_FOOD_CACHE = {}


def ensure_unit(name, token):
    if name in _UNIT_CACHE:
        return _UNIT_CACHE[name]
    _, found = call(f"/api/units?search={urllib.parse.quote(name)}&perPage=10", token=token)
    for u in (found or {}).get("items", []):
        if u["name"].lower() == name.lower():
            _UNIT_CACHE[name] = u["id"]
            return u["id"]
    status, created = call("/api/units", "POST",
                           {"name": name, "abbreviation": name, "useAbbreviation": False},
                           token=token)
    uid = (created or {}).get("id")
    if not uid:
        print("  unit create failed", name, status, created)
    _UNIT_CACHE[name] = uid
    return uid


def ensure_food(name, token):
    if name in _FOOD_CACHE:
        return _FOOD_CACHE[name]
    _, found = call(f"/api/foods?search={urllib.parse.quote(name)}&perPage=10", token=token)
    for f in (found or {}).get("items", []):
        if f["name"].lower() == name.lower():
            _FOOD_CACHE[name] = f["id"]
            return f["id"]
    status, created = call("/api/foods", "POST", {"name": name}, token=token)
    fid = (created or {}).get("id")
    if not fid:
        print("  food create failed", name, status, created)
    _FOOD_CACHE[name] = fid
    return fid


def iso(minutes):
    h, m = divmod(int(minutes), 60)
    out = "PT"
    if h:
        out += f"{h}H"
    if m or not h:
        out += f"{m}M"
    return out


def main():
    status, tok = call("/api/auth/token", "POST",
                       {"username": USER, "password": PASS}, form=True)
    if status != 200:
        print("login failed", status, tok)
        return
    token = tok["access_token"]
    print("logged in as", USER)

    status, existing = call("/api/recipes?page=1&perPage=100", token=token)
    for old in existing["items"]:
        call(f'/api/recipes/{old["slug"]}', "DELETE", token=token)
        print("removed", old["slug"])

    for r in RECIPES:
        status, created = call("/api/recipes", "POST", {"name": r["name"]}, token=token)
        slug = created if isinstance(created, str) else (created or {}).get("slug")
        if not slug:
            print("create failed", r["name"], status, created)
            continue
        ingredients = []
        for q, u, f in r["ingredients"]:
            # Mealie v3 wants flat foreign keys here, not nested objects.
            ingredients.append({
                "quantity": q,
                "unit": {"id": ensure_unit(u, token), "name": u},
                "food": {"id": ensure_food(f, token), "name": f},
                "note": "",
            })

        payload = {
            "name": r["name"],
            "slug": slug,
            "description": r["description"],
            "recipeServings": r["servings"],
            "recipeYield": f'{r["servings"]} servings',
            "recipeYieldQuantity": r["servings"],
            "prepTime": iso(r["prep"]),
            "cookTime": iso(r["cook"]),
            "totalTime": iso(r["prep"] + r["cook"]),
            "prepTimeSeconds": r["prep"] * 60,
            "cookTimeSeconds": r["cook"] * 60,
            "totalTimeSeconds": (r["prep"] + r["cook"]) * 60,
            "recipeIngredient": ingredients,
            "recipeInstructions": [{"text": s} for s in r["steps"]],
            "tags": [{"name": t} for t in r["tags"]],
            "recipeCategory": [{"name": r["category"]}],
        }
        status, _ = call(f"/api/recipes/{slug}", "PUT", payload, token=token)
        print("created", slug, status)
        upload_image(slug, r["image"], token)

    # ---- meal plan -------------------------------------------------------
    today = datetime.date.today()
    status, all_recipes = call("/api/recipes?page=1&perPage=100", token=token)
    recipes = {r["name"]: r for r in all_recipes["items"]}
    status, plans = call("/api/households/mealplans?page=1&perPage=50", token=token)
    have = {(p["date"], p["entryType"]) for p in plans["items"]}
    plan = [
        (0, "dinner", "Garlic Butter Pasta"),
        (1, "dinner", "Sheet-Pan Chicken with Lemon Potatoes"),
        (2, "breakfast", "Shakshuka"),
        (2, "dinner", "Miso Mushroom Rice Bowl"),
        (3, "dinner", "Slow-Braised Beef Ragu"),
        (4, "lunch", "Green Goddess Salad"),
    ]
    for offset, kind, name in plan:
        day = (today + datetime.timedelta(days=offset)).isoformat()
        if (day, kind) in have or name not in recipes:
            continue
        status, _ = call("/api/households/mealplans", "POST", {
            "date": day, "entryType": kind, "recipeId": recipes[name]["id"],
            "title": name, "text": "",
        }, token=token)
        print("plan", day, kind, name, status)

    # ---- shopping list ---------------------------------------------------
    status, lists = call("/api/households/shopping/lists?page=1&perPage=10", token=token)
    for old_list in lists["items"]:
        call(f'/api/households/shopping/lists/{old_list["id"]}', "DELETE", token=token)
        print("removed list", old_list["name"])
    if True:
        status, lst = call("/api/households/shopping/lists", "POST",
                           {"name": "This week"}, token=token)
        list_id = lst["id"]
        items = [
            ("garlic", 2, "clove", False), ("parmesan", 150, "g", False),
            ("chicken thighs", 8, "piece", False), ("potatoes", 1, "kg", True),
            ("coriander", 1, "bunch", False), ("olive oil", 1, "l", True),
            ("miso paste", 1, "jar", False), ("red wine", 1, "bottle", False),
        ]
        for name, qty, unit, checked in items:
            call("/api/households/shopping/items", "POST", {
                "shoppingListId": list_id, "note": name, "quantity": qty,
                "unitId": ensure_unit(unit, token),
                "checked": checked, "isFood": False,
            }, token=token)
        print("shopping list seeded:", len(items), "items")

    print("done")


if __name__ == "__main__":
    main()
