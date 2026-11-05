---
name: website-outreach
description: Check whether a local Hyderabad business already has a working, mobile-friendly website, build a truthful one-page demo website for it from demo-template.html, and draft the outreach email from email-guide.md. Use when preparing website outreach leads.
---

# Website outreach

Files in this skill folder: `demo-template.html` (the one-page template, CSS only, three themes), `fill_demo.py` (fills it safely) and `email-guide.md` (the outreach email rules, templates and gap sentences). Work in three steps per business: **gap check**, then, only if there is a gap, **build the demo**, then **draft the email** (only for a publicly listed business email) by following `email-guide.md` exactly.

## 1. Website gap check

1. Search `"<business name>" <area> Hyderabad`. Add the phone number to the query if the first search is ambiguous.
2. Sort what you find into three groups:
   - **Own site**: a domain the business controls. Confirm it is the same business (name plus area or phone match). A listing's "website" field that points to Instagram, Facebook or an aggregator is **not** an own site.
   - **Social**: instagram.com, facebook.com pages run by the business.
   - **Aggregator**: zomato.com, swiggy.com, justdial.com, practo.com, sulekha.com. A Google Maps / Business Profile pin on its own does not count as a web presence.
3. If you found an own site, fetch the raw HTML with bash (web_fetch returns cleaned text and can drop `<meta>` tags). Retry once before calling it broken:
   ```bash
   curl -sSL -m 20 -A "Mozilla/5.0" -o page.html -w '%{http_code} %{url_effective}\n' "<url>"
   grep -io '<meta[^>]*viewport[^>]*>' page.html    # look for width=device-width
   ```
4. Give exactly one label, the first that matches, top to bottom:

| Label | Concrete check | Next step |
|---|---|---|
| `broken` | Own site found, but the fetch fails (DNS error, timeout, TLS error, connection refused), the final HTTP status is 400 or higher, or the page is a parked, expired or "coming soon" placeholder | Build demo |
| `not_mobile_friendly` | Own site returns HTTP 200 but has no `<meta name="viewport">` containing `width=device-width` | Build demo |
| `has_good_site` | Own site returns HTTP 200, shows the business name, and has a `width=device-width` viewport meta tag | **Skip.** No demo, no outreach |
| `social_only` | No own site; the only web presence is Instagram and/or Facebook (aggregator listings may also exist) | Build demo |
| `aggregator_only` | No own site and no social page; only Zomato / Swiggy / Justdial / Practo / Sulekha listings | Build demo |
| `no_website` | No own site, no social page, no aggregator listing found (a maps pin at most) | Build demo |

5. Record evidence for **every** check: the search query, and for each URL you looked at, the URL, what you checked and the result. No label without a source URL.
   ```json
   {"business": "...", "area": "...", "label": "not_mobile_friendly",
    "evidence": [{"url": "https://example.in/", "check": "fetch", "result": "HTTP 200, final URL https://example.in/"},
                 {"url": "https://example.in/", "check": "viewport meta", "result": "absent"}]}
   ```

## 2. Build the demo

Only for leads labelled `broken`, `not_mobile_friendly`, `social_only`, `aggregator_only` or `no_website`.

1. **Collect facts** only from pages the business publishes itself (its site, its own Instagram/Facebook) or its public listing (Google Maps, Justdial, Practo, Zomato, Swiggy, Sulekha). Note the source URL for each fact. Never fill a gap with a guess.
2. **Pick the theme** by category:

| Category | `theme` | Body class |
|---|---|---|
| Salons & spas | `salon` | `theme-salon` |
| Clinics & dentists | `clinic` | `theme-clinic` |
| Restaurants & cafes | `restaurant` | `theme-restaurant` |

3. **Fill it with the script** (preferred: it escapes, sets the theme and checks the result):
   ```bash
   python3 <this-skill-folder>/fill_demo.py data.json out/<business-slug>.html
   ```
   ```json
   {"theme": "clinic", "BUSINESS_NAME": "...", "TAGLINE": "...", "AREA": "Kondapur",
    "BUSINESS_PHONE": "+91 ...", "MAPS_URL": "https://maps.app.goo.gl/...",
    "ADDRESS": "...", "services": ["...", "..."], "hours": ["Mon–Sat: ...", "Sun: Closed"]}
   ```
   Exit 0 means the file was written. Exit 1 lists unfilled placeholders; nothing is written. Exit 2 means bad data. Notes on stderr say which fallbacks were used.
4. **If filling by hand**: copy `demo-template.html`, change `theme-salon` on `<body>` to the category's class, and replace each placeholder by plain string replacement. HTML-escape every value (`&` `<` `>` `"` `'`). `{{SERVICES_LIST_HTML}}` and `{{HOURS_HTML}}` take `<li>…</li>` items only (the `<ul>` is already in the template). In `href="tel:{{BUSINESS_PHONE}}"` use digits and a leading `+` only; the visible text keeps the published format.
5. **When a fact is not published**, write a neutral line instead of inventing one:

| Placeholder | If not published |
|---|---|
| `TAGLINE` | Plain category line from the listing, e.g. "Dental clinic" or "Unisex salon & spa". No superlatives |
| `HOURS_HTML` | `<li>Call for timings</li>` |
| `SERVICES_LIST_HTML` | `<li>Call to ask about services</li>` (restaurants: `<li>Call for today's menu</li>`) |
| `MAPS_URL` | Google Maps search link for name + area (`https://www.google.com/maps/search/?api=1&query=...`) |
| `BUSINESS_PHONE`, `ADDRESS` | Don't build. Mark the lead incomplete |

6. **Leave `{{AGENCY_NAME}}`, `{{SENDER_NAME}}` and `{{PHONE}}` exactly as they are.** The agency fills them later.
7. **Final check** before handing over. This must print exactly those three, and the banner line must be present:
   ```bash
   grep -o '{{[^}]*}}' out/<business-slug>.html | sort -u
   grep -c 'Preview concept by {{AGENCY_NAME}} — not an official website of' out/<business-slug>.html
   ```

## 3. Never

- Never copy logos, photos or any other images or brand assets. The template uses CSS shapes and a CSS initial only.
- Never invent reviews, ratings, star counts, prices, awards, certifications, years in business, doctor qualifications or "best in Hyderabad" claims. Never add review, rating, pricing or testimonial sections.
- For clinics: never add treatment outcomes or medical claims beyond the published service names.
- Never remove, hide, shorten or reword the preview banner ("Preview concept by … — not an official website of …"), and never present the demo as the business's official site.
- Never fill the three agency placeholders yourself.
