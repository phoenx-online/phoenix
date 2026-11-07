// Deterministic public role/navigation interaction checks without network or dependencies.
import { readFileSync } from "node:fs";
import { runInNewContext } from "node:vm";
import assert from "node:assert/strict";

class FakeElement {
  constructor(attrs = {}) {
    this.attrs = { ...attrs };
    this.listeners = new Map();
    this.classes = new Set(attrs.class?.split(" ").filter(Boolean) || []);
    this.classList = {
      contains: (name) => this.classes.has(name),
      add: (name) => this.classes.add(name),
      remove: (name) => this.classes.delete(name),
      toggle: (name, force) => {
        const yes = force === undefined ? !this.classes.has(name) : force;
        if (yes) this.classes.add(name);
        else this.classes.delete(name);
        return yes;
      }
    };
    this.textContent = "";
  }
  setAttribute(name, val) { this.attrs[name] = String(val); }
  getAttribute(name) { return this.attrs[name] ?? null; }
  addEventListener(name, handler) { this.listeners.set(name, handler); }
  fire(name, payload = {}) { const f = this.listeners.get(name); assert(f, "Missing handler: " + name); f(payload); }
  querySelectorAll() { return []; }
}

const identifiers = ["brands","clients","partners","investors","agents","affiliates","staff","operators"];
const buttons = identifiers.map((id) => new FakeElement({"data-audience":id}));
const elements = new Map([
  ["audience-symbol", new FakeElement()],
  ["audience-title", new FakeElement()],
  ["audience-text", new FakeElement()],
  ["audience-next", new FakeElement()],
  ["year", new FakeElement()]
]);
const navToggle = new FakeElement({"aria-expanded":"false"});
const nav = new FakeElement();
const links = [new FakeElement(),new FakeElement()];
nav.querySelectorAll = () => links;
let currentUrl = "https://phoenx.live/?role=investors#audiences";
const history = { replaceState: (_state, _unused, url) => { currentUrl = "https://phoenx.live" + url; } };
const listeners = new Map();
const document = {
  querySelectorAll: (selector) => selector === "[data-audience]" ? buttons : [],
  getElementById: (id) => id === "primary-navigation" ? nav : elements.get(id) || null,
  querySelector: (selector) => selector === ".nav-toggle" ? navToggle : null,
  addEventListener: (name, fn) => listeners.set(name, fn)
};
const window = { location:{href:currentUrl,search:"?role=investors"},history };
const source = readFileSync("public-site/site.js","utf8");
runInNewContext(source,{window,document,URL,URLSearchParams,Date,console});

assert.match(elements.get("audience-title").textContent,/growth chapter/i, "Deep-link investor path must select");
assert.equal(buttons[3].getAttribute("aria-pressed"),"true");
for (const [i, role] of identifiers.entries()) {
  buttons[i].fire("click");
  assert.equal(buttons[i].getAttribute("aria-pressed"),"true","Incorrect current role "+role);
  assert.equal(buttons.filter(b=>b.getAttribute("aria-pressed")==="true").length,1,"Exactly one selected role");
  assert(currentUrl.includes("role="+role),"URL should be shareable for role");
  assert(elements.get("audience-title").textContent.length>=10);
  assert(elements.get("audience-next").textContent.length>=10);
}
navToggle.fire("click");
assert.equal(navToggle.getAttribute("aria-expanded"),"true");
assert(nav.classList.contains("is-open"));
links[0].fire("click");
assert.equal(navToggle.getAttribute("aria-expanded"),"false");
navToggle.fire("click");
listeners.get("keydown")({key:"Escape"});
assert.equal(navToggle.getAttribute("aria-expanded"),"false");
assert.match(elements.get("year").textContent,/^\d{4}$/);
console.log("PHOENIX_STAKEHOLDER_ROLE_INTERACTIONS=PASS");
console.log("ROLE_SELECTORS_TESTED=8");
console.log("MOBILE_NAVIGATION=PASS");
