#!/usr/bin/env python3
"""Fill demo-template.html (next to this script) from a JSON data file.

Usage:  python3 fill_demo.py data.json out.html

data.json:
  "theme":    "salon" | "clinic" | "restaurant"
  "services": ["...", ...]   -> SERVICES_LIST_HTML (<li> items)
  "hours":    ["...", ...]   -> HOURS_HTML (<li> items)
  "BUSINESS_NAME", "TAGLINE", "AREA", "BUSINESS_PHONE", "MAPS_URL", "ADDRESS": strings

Every value is HTML-escaped. AGENCY_NAME, SENDER_NAME and PHONE stay as literal
{{...}} placeholders for the agency to fill later. Fallbacks: empty hours ->
"Call for timings"; empty services -> a "call to ask" line; missing MAPS_URL ->
a Google Maps search link for the business name + area.

Exit codes: 0 written; 1 unfilled placeholders or template check failed (nothing
written); 2 bad arguments or data.
"""
import html
import json
import os
import re
import sys
from urllib.parse import quote_plus, urlparse

MAPS_HOSTS = {"google.com", "www.google.com", "maps.google.com", "maps.app.goo.gl", "goo.gl"}
# bidi overrides/isolates and zero-width characters can visually spoof the preview banner
INVISIBLE = re.compile("[\u200b-\u200f\u202a-\u202e\u2066-\u2069\ufeff]")

HERE = os.path.dirname(os.path.abspath(__file__))
TEMPLATE = os.path.join(HERE, "demo-template.html")

KEEP = ("AGENCY_NAME", "SENDER_NAME", "PHONE")      # agency fills these later
BUILT = ("SERVICES_LIST_HTML", "HOURS_HTML")        # built from the lists
THEMES = ("salon", "clinic", "restaurant")
NO_SERVICES = {"salon": "Call to ask about services",
               "clinic": "Call to ask about services",
               "restaurant": "Call for today's menu"}
NO_HOURS = "Call for timings"
PLACEHOLDER = re.compile(r"(tel:)?\{\{([A-Z0-9_]+)\}\}")
KEPT = re.compile(r"\{\{(?:%s)\}\}" % "|".join(KEEP))
BANNER = "Preview concept by {{AGENCY_NAME}} — not an official website of "


def fail(code, msg):
    print("error: " + msg, file=sys.stderr)
    sys.exit(code)


def esc(value):
    # Braces are escaped too, so a value can never smuggle in a {{PLACEHOLDER}}.
    return (html.escape(INVISIBLE.sub("", value), quote=True)
            .replace("{", "&#123;").replace("}", "&#125;"))


def tel_href(phone):
    first = re.split(r"[/,;|]", phone)[0]           # first number if several
    digits = re.sub(r"[^\d+]", "", first)
    digits = ("+" if digits.startswith("+") else "") + digits.replace("+", "")
    if len(digits.lstrip("+")) < 6:
        fail(2, "BUSINESS_PHONE %r does not look like a phone number" % phone)
    return digits


def as_list(data, key):
    items = data.get(key) or []
    if not isinstance(items, list):
        fail(2, '"%s" must be a list of strings' % key)
    out = []
    for item in items:
        if isinstance(item, (dict, list)):
            fail(2, '"%s" must be a list of strings' % key)
        text = str(item).strip()
        if text:
            out.append(text)
    return out


def li_list(items):
    return "\n".join("<li>%s</li>" % esc(i) for i in items)


def main(argv):
    if len(argv) != 3:
        fail(2, "usage: python3 fill_demo.py data.json out.html")
    data_path, out_path = argv[1], argv[2]
    try:
        with open(data_path, encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, ValueError) as e:
        fail(2, "cannot read %s: %s" % (data_path, e))
    if not isinstance(data, dict):
        fail(2, "data.json must be a JSON object")

    theme = str(data.get("theme", "")).strip().lower()
    if theme not in THEMES:
        fail(2, '"theme" must be one of %s (got %r)' % (", ".join(THEMES), theme))

    notes, values = [], {}
    for key, val in data.items():
        if key in ("theme", "services", "hours") or val is None:
            continue
        if key in KEEP:
            notes.append("ignored %s: left as a placeholder for the agency" % key)
            continue
        if key in BUILT:
            notes.append("ignored %s: built from services/hours" % key)
            continue
        if isinstance(val, (dict, list)):
            fail(2, '"%s" must be a string' % key)
        text = str(val).strip()
        if text:
            values[key] = text

    services, hours = as_list(data, "services"), as_list(data, "hours")
    if not services:
        notes.append("no services given: using %r" % NO_SERVICES[theme])
    if not hours:
        notes.append("no hours given: using %r" % NO_HOURS)
    raw = {"SERVICES_LIST_HTML": li_list(services or [NO_SERVICES[theme]]),
           "HOURS_HTML": li_list(hours or [NO_HOURS])}

    if "MAPS_URL" in values:
        u = urlparse(values["MAPS_URL"])
        if u.scheme != "https" or u.username or u.password or (u.hostname or "").lower() not in MAPS_HOSTS:
            notes.append("MAPS_URL %r is not an https Google Maps link: replaced with a search link" % values["MAPS_URL"])
            del values["MAPS_URL"]
    if "MAPS_URL" not in values and "BUSINESS_NAME" in values:
        query = ", ".join(INVISIBLE.sub("", v) for v in (values["BUSINESS_NAME"], values.get("AREA"),
                                      "Hyderabad") if v)
        values["MAPS_URL"] = ("https://www.google.com/maps/search/?api=1&query="
                              + quote_plus(query))
        notes.append("no MAPS_URL given: using a Google Maps search link")

    try:
        with open(TEMPLATE, encoding="utf-8") as f:
            template = f.read()
    except OSError as e:
        fail(2, "cannot read template %s: %s" % (TEMPLATE, e))

    template, n = re.subn(r'(<body\b[^>]*\bclass="[^"]*?)\btheme-[a-z]+',
                          r"\g<1>theme-" + theme, template, count=1)
    if n != 1:
        fail(1, "template <body> has no theme-* class")

    known = {m.group(2) for m in PLACEHOLDER.finditer(template)}
    known |= {"theme", "services", "hours"}
    for key in sorted(set(data) - known):
        notes.append("unknown key %r (not a template placeholder): ignored" % key)

    def fill(m):
        is_tel, name = m.group(1), m.group(2)
        if name in KEEP:
            return m.group(0)
        if name in raw:   # indent each <li> like the slot it replaces
            line_start = template.rfind("\n", 0, m.start()) + 1
            indent = template[line_start:m.start()]
            return raw[name].replace("\n", "\n" + (indent if not indent.strip() else ""))
        if name in values:
            if is_tel:
                return "tel:" + tel_href(values[name])
            if name == "ADDRESS":
                return "<br>".join(esc(line.strip())
                                   for line in values[name].splitlines() if line.strip())
            return esc(values[name])
        return m.group(0)

    out = PLACEHOLDER.sub(fill, template)    # single pass: values are never re-scanned

    for note in notes:
        print("note: " + note, file=sys.stderr)

    leftover = sorted(set(re.findall(r"\{\{[^{}]*\}\}|\{\{", KEPT.sub("", out))))
    if leftover:
        fail(1, "unfilled placeholders: %s (nothing written)" % ", ".join(leftover))
    if 'name="viewport"' not in out:
        fail(1, "viewport meta tag missing from template (nothing written)")
    if BANNER + esc(values.get("BUSINESS_NAME", "")) not in out:
        fail(1, "preview banner missing or altered in template (nothing written)")

    out_dir = os.path.dirname(os.path.abspath(out_path))
    os.makedirs(out_dir, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(out)
    print("wrote %s (theme-%s); left for the agency: %s"
          % (out_path, theme, ", ".join(KEEP)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
