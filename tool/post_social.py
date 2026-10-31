#!/usr/bin/env python3
"""Post the Mise launch thread to Mastodon and Bluesky.

Dry run by default: prints every post, its length against the network's limit,
the image it would attach and the alt text, and sends nothing.

    python3 tool/post_social.py                  # dry run both networks
    python3 tool/post_social.py --only mastodon  # dry run one

To actually post, supply credentials — nothing is stored in the repo:

    MASTODON_INSTANCE=https://mastodon.social \
    MASTODON_TOKEN=...                       \
    python3 tool/post_social.py --post

    BSKY_HANDLE=you.bsky.social              \
    BSKY_APP_PASSWORD=xxxx-xxxx-xxxx-xxxx    \
    python3 tool/post_social.py --only bluesky --post

Mastodon token: Preferences -> Development -> New application, scopes
`write:statuses write:media`. Bluesky: Settings -> App Passwords (never the
account password). Both are read from the environment only.

Threads post in order; a failure stops the run and reports which post landed, so
`--start N` resumes without duplicating.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
THREAD = ROOT / "docs/posts/thread.json"

MASTODON_LIMIT = 500
BLUESKY_LIMIT = 300
URL_RE = re.compile(r"https?://[^\s]+|(?<![\w/])(?:[a-z0-9-]+\.)+[a-z]{2,}(?:/[^\s]*)?")


# ---------------------------------------------------------------- utilities

def graphemes(s: str) -> int:
    """Close enough to Bluesky's counter: code points, minus combining marks."""
    import unicodedata
    return sum(1 for ch in s if not unicodedata.combining(ch))


def byte_range(text: str, start: int, end: int) -> tuple[int, int]:
    return (len(text[:start].encode()), len(text[:end].encode()))


def request(url: str, method="GET", data=None, headers=None, raw=False):
    req = urllib.request.Request(url, data=data, method=method, headers=headers or {})
    try:
        with urllib.request.urlopen(req, timeout=90) as r:
            body = r.read()
            return r.status, (body if raw else json.loads(body or b"{}"))
    except urllib.error.HTTPError as e:
        detail = e.read().decode("utf-8", "replace")[:600]
        raise SystemExit(f"{method} {url} -> {e.code}\n{detail}") from None


def multipart(fields: dict[str, str], files: dict[str, tuple[str, bytes, str]]):
    boundary = "----mise" + os.urandom(8).hex()
    out = b""
    for name, value in fields.items():
        out += (f"--{boundary}\r\nContent-Disposition: form-data; name=\"{name}\"\r\n\r\n"
                f"{value}\r\n").encode()
    for name, (filename, blob, ctype) in files.items():
        out += (f"--{boundary}\r\nContent-Disposition: form-data; name=\"{name}\"; "
                f"filename=\"{filename}\"\r\nContent-Type: {ctype}\r\n\r\n").encode()
        out += blob + b"\r\n"
    out += f"--{boundary}--\r\n".encode()
    return out, f"multipart/form-data; boundary={boundary}"


# ---------------------------------------------------------------- validation

def validate(posts: list[dict]) -> list[str]:
    problems = []
    for i, p in enumerate(posts, start=1):
        m, b = p.get("mastodon", ""), p.get("bluesky", "")
        if len(m) > MASTODON_LIMIT:
            problems.append(f"post {i}: mastodon {len(m)} chars > {MASTODON_LIMIT}")
        if graphemes(b) > BLUESKY_LIMIT:
            problems.append(f"post {i}: bluesky {graphemes(b)} > {BLUESKY_LIMIT}")
        if b and p.get("image") and not p.get("alt"):
            problems.append(f"post {i}: image without alt text")
        if p.get("image") and not (ROOT / p["image"]).exists():
            problems.append(f"post {i}: missing image {p['image']}")
    return problems


def plan(posts: list[dict], only: str) -> None:
    networks = ["mastodon", "bluesky"] if only == "all" else [only]
    for i, p in enumerate(posts, start=1):
        print(f"\n── post {i} " + "─" * 60)
        for net in networks:
            text = p.get(net, "")
            limit = MASTODON_LIMIT if net == "mastodon" else BLUESKY_LIMIT
            size = len(text) if net == "mastodon" else graphemes(text)
            flag = "OK " if size <= limit else "OVER"
            print(f"[{net}] {flag} {size}/{limit}")
            print(text)
            if net == "mastodon":
                if p.get("image"):
                    print(f"  ↳ image: {p['image']}")
                    print(f"  ↳ alt:   {p.get('alt', '')}")
            else:
                links = [m.group(0) for m in URL_RE.finditer(text)]
                if links:
                    print(f"  ↳ facets: {len(links)} link(s) => {', '.join(links)}")
                if p.get("image"):
                    print(f"  ↳ image: {p['image']} (alt: {p.get('alt','')[:48]}…)")


# ---------------------------------------------------------------- mastodon

def mastodon_post(instance: str, token: str, posts: list[dict], start: int) -> None:
    base = instance.rstrip("/")
    auth = {"Authorization": f"Bearer {token}"}
    reply_to = None

    for i, p in enumerate(posts, start=1):
        if i < start:
            continue
        text = p.get("mastodon", "")
        media_ids = []
        if p.get("image"):
            path = ROOT / p["image"]
            body, ctype = multipart(
                {"description": p.get("alt", "")},
                {"file": (path.name, path.read_bytes(), "image/png")},
            )
            status, media = request(f"{base}/api/v2/media", "POST", body,
                                    {**auth, "Content-Type": ctype})
            mid = media["id"]
            # 202 means processed later; poll until it is playable
            for _ in range(30):
                if status == 200:
                    break
                time.sleep(2)
                status, media = request(f"{base}/api/v1/media/{mid}", headers=auth)
            media_ids.append(mid)

        form = [("status", text), ("visibility", "public")]
        for mid in media_ids:
            form.append(("media_ids[]", mid))
        if reply_to:
            form.append(("in_reply_to_id", reply_to))

        _, status_obj = request(
            f"{base}/api/v1/statuses", "POST",
            urllib.parse.urlencode(form).encode(),
            {**auth, "Content-Type": "application/x-www-form-urlencoded"},
        )
        reply_to = status_obj["id"]
        print(f"mastodon {i}/{len(posts)}: {status_obj['url']}")


# ---------------------------------------------------------------- bluesky

def bsky_session(pds: str, handle: str, password: str) -> tuple[str, str]:
    body = json.dumps({"identifier": handle, "password": password}).encode()
    _, data = request(f"{pds}/xrpc/com.atproto.server.createSession", "POST", body,
                      {"Content-Type": "application/json"})
    return data["accessJwt"], data["did"]


def bsky_facets(text: str) -> list[dict]:
    facets = []
    for m in URL_RE.finditer(text):
        url = m.group(0)
        href = url if url.startswith("http") else f"https://{url}"
        start, end = byte_range(text, m.start(), m.end())
        facets.append({
            "index": {"byteStart": start, "byteEnd": end},
            "features": [{"$type": "app.bsky.richtext.facet#link", "uri": href}],
        })
    return facets


def bsky_post(pds: str, jwt: str, did: str, posts: list[dict], start: int) -> None:
    auth = {"Authorization": f"Bearer {jwt}"}
    root = None
    parent = None

    for i, p in enumerate(posts, start=1):
        if i < start:
            continue
        text = p.get("bluesky", "")
        record = {
            "$type": "app.bsky.feed.post",
            "text": text,
            "langs": ["en"],
            "createdAt": time.strftime("%Y-%m-%dT%H:%M:%S.000Z", time.gmtime()),
        }
        facets = bsky_facets(text)
        if facets:
            record["facets"] = facets

        if p.get("image"):
            path = ROOT / p["image"]
            _, up = request(f"{pds}/xrpc/com.atproto.repo.uploadBlob", "POST",
                            path.read_bytes(),
                            {**auth, "Content-Type": "image/png"})
            record["embed"] = {
                "$type": "app.bsky.embed.images",
                "images": [{"alt": p.get("alt", ""), "image": up["blob"]}],
            }

        if parent:
            record["reply"] = {"root": root, "parent": parent}

        body = json.dumps({"repo": did, "collection": "app.bsky.feed.post",
                           "record": record}).encode()
        _, out = request(f"{pds}/xrpc/com.atproto.repo.createRecord", "POST", body,
                         {**auth, "Content-Type": "application/json"})
        ref = {"uri": out["uri"], "cid": out["cid"]}
        root = root or ref
        parent = ref
        rkey = out["uri"].rsplit("/", 1)[-1]
        print(f"bluesky {i}/{len(posts)}: https://bsky.app/profile/{did}/post/{rkey}")


# ---------------------------------------------------------------- main

def main() -> int:
    ap = argparse.ArgumentParser(description="Post the Mise launch thread")
    ap.add_argument("--post", action="store_true", help="actually send (default: dry run)")
    ap.add_argument("--only", choices=["mastodon", "bluesky", "all"], default="all")
    ap.add_argument("--start", type=int, default=1, help="resume from post N")
    args = ap.parse_args()

    posts = json.loads(THREAD.read_text())
    problems = validate(posts)
    if problems:
        print("cannot post, fix these first:")
        for p in problems:
            print(" -", p)
        return 1

    plan(posts, args.only)
    if not args.post:
        print("\ndry run — nothing sent. add --post with credentials in the env to send.")
        return 0

    if args.only in ("mastodon", "all"):
        instance = os.environ.get("MASTODON_INSTANCE")
        token = os.environ.get("MASTODON_TOKEN")
        if not (instance and token):
            print("MASTODON_INSTANCE / MASTODON_TOKEN not set — skipping mastodon")
        else:
            mastodon_post(instance, token, posts, args.start)

    if args.only in ("bluesky", "all"):
        handle = os.environ.get("BSKY_HANDLE")
        password = os.environ.get("BSKY_APP_PASSWORD")
        pds = os.environ.get("BSKY_PDS", "https://bsky.social")
        if not (handle and password):
            print("BSKY_HANDLE / BSKY_APP_PASSWORD not set — skipping bluesky")
        else:
            jwt, did = bsky_session(pds, handle, password)
            bsky_post(pds, jwt, did, posts, args.start)

    return 0


if __name__ == "__main__":
    sys.exit(main())
