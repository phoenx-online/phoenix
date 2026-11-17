#!/usr/bin/env python3
"""Pure-stdlib PHOENIX static-site release contract. Reads source, makes no changes."""
from html.parser import HTMLParser
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1] / "public-site"
EXPECTED = {"index.html", "styles.css", "site.js", "_headers", "favicon.svg", "robots.txt", "sitemap.xml"}
ACTUAL = {p.name for p in ROOT.iterdir() if p.is_file()}
assert EXPECTED.issubset(ACTUAL), f"Missing public assets: {EXPECTED-ACTUAL}"

class SiteParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.tags = []
        self.ids = set()
        self.targets = []
        self.roles = []
        self.forms = []
        self.local_assets = []
        self.canonical = []
        self.description = []
        self.clickable = []

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        self.tags.append(tag)
        if a.get("id"):
            assert a["id"] not in self.ids, "Duplicate id " + a["id"]
            self.ids.add(a["id"])
        if tag == "form":
            self.forms.append(a)
        if tag == "button":
            self.clickable.append(a)
        if "data-audience" in a:
            self.roles.append(a["data-audience"])
            assert tag == "button"
        if tag == "a":
            href = a.get("href", "")
            if href.startswith("#"):
                self.targets.append(href[1:])
            elif href.startswith(("http:", "https:", "mailto:", "tel:")):
                raise AssertionError("Public site has an external/action link requiring approval: " + href)
        if tag in {"link", "script", "img"}:
            ref = a.get("href") or a.get("src")
            if ref:
                if ref.startswith("https:"):
                    if tag == "link" and a.get("rel") == "canonical":
                        self.canonical.append(ref)
                    else:
                        raise AssertionError("No external executable assets allowed")
                elif ref.startswith("/"):
                    self.local_assets.append(ref[1:])
        if tag == "meta" and a.get("name") == "description":
            self.description.append(a.get("content"))

h = (ROOT / "index.html").read_text()
assert "<!doctype html>" in h.lower()
parser = SiteParser()
parser.feed(h)
assert "html" in parser.tags and "main" in parser.tags and "nav" in parser.tags
assert not parser.forms, "No private data collection or signups on public-only site"
assert parser.description and parser.description[0]
assert parser.canonical == ["https://phoenx.live/"], parser.canonical
assert len(parser.roles) == len(set(parser.roles)) == 8, parser.roles
expected_roles = {"brands","clients","partners","investors","agents","affiliates","staff","operators"}
assert set(parser.roles) == expected_roles, parser.roles
assert set(parser.targets).issubset(parser.ids), f"Dead anchors {set(parser.targets)-parser.ids}"
for asset in parser.local_assets:
    assert (ROOT / asset).exists(), "Missing asset: " + asset
assert all(not x.startswith("on") for x in re.findall(r'\s(onclick|onload|onerror)\s*=', h)), "Inline handlers forbidden"
assert "private" in h.lower() and "not active" in h.lower()
assert len(parser.clickable) >= 9, "Stakeholder buttons/mobile nav absent"

css = (ROOT/"styles.css").read_text()
js = (ROOT/"site.js").read_text()
assert "prefers-reduced-motion" in css
assert "@media(max-width:640px)" in css
assert "aria-pressed" in js and "aria-expanded" in js
assert "textContent" in js and "innerHTML" not in js, "Untrusted HTML insertion not allowed"
assert "fetch(" not in js and "XMLHttpRequest" not in js, "No external network calls"
assert "localStorage" not in js and "document.cookie" not in js, "No client tracking/storage"
assert "new URLSearchParams" in js
assert "password" in h.lower() and "otp" in h.lower(), "Safety notice must be present"
headers = (ROOT/"_headers").read_text()
for requirement in (
    "Content-Security-Policy:", "frame-ancestors 'none'", "default-src 'none'",
    "script-src 'self'", "style-src 'self'", "connect-src 'none'",
    "Strict-Transport-Security:", "X-Content-Type-Options:",
):
    assert requirement in headers, f"Header contract missing: {requirement}"
assert "unsafe-inline" not in headers

tree = ET.fromstring((ROOT / "sitemap.xml").read_text())
ns = {"m": "http://www.sitemaps.org/schemas/sitemap/0.9"}
urls = [v.text for v in tree.findall(".//m:loc", ns)]
assert urls == ["https://phoenx.live/"], urls
ET.fromstring((ROOT/"favicon.svg").read_text())
assert "Sitemap: https://phoenx.live/sitemap.xml" in (ROOT/"robots.txt").read_text()

print("PHOENIX_PUBLIC_SITE_SOURCE_CONTRACT=PASS")
print("PUBLIC_AUDIENCES=8")
print("EXTERNAL_SCRIPTS_OR_NETWORK_CALLS=0")
print("ACCOUNT_FORMS=0")
print("CANONICAL=https://phoenx.live/")
print("NO_PRODUCTION_DEPLOYMENT_OR_DNS_MUTATION=TRUE")
