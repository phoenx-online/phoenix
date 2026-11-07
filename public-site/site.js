"use strict";
/* Public information only. No cookies, analytics, account creation, form submission or external requests. */
(function () {
  const roles = Object.freeze({
    brands: {
      symbol: "B",
      title: "Grow your brand in live commerce.",
      description: "Explore marketplace operations, content production, talent coordination and live-selling support tailored to an agreed brand scope.",
      next: "Discuss your products, channels, inventory ownership, approvals and growth goals with the PHOENIX team."
    },
    clients: {
      symbol: "C",
      title: "Build a clearer commerce operation.",
      description: "Discover service-assisted account handling, live production, campaign execution and source-backed reporting. Delivery depends on a written scope.",
      next: "Review the services and responsibilities with your current PHOENIX contact. Private brand account onboarding is not yet live."
    },
    partners: {
      symbol: "P",
      title: "Build partnerships that deliver.",
      description: "Explore opportunities in studios, technology, production, commerce, distribution, creative services and commercial development.",
      next: "Discuss collaboration objectives, responsibilities, commercial boundaries and written partnership terms with PHOENIX."
    },
    investors: {
      symbol: "I",
      title: "Explore the next growth chapter.",
      description: "Learn about PHOENIX’s live-commerce services, operating model and technology direction. Forecasts are illustrative until validated by real operations.",
      next: "Request a management introduction through an existing PHOENIX representative. Private investor materials are not publicly hosted."
    },
    agents: {
      symbol: "A",
      title: "Connect opportunities to execution.",
      description: "Explore referral and business-development collaboration for brands and live-commerce services. Commission programs require separate approval.",
      next: "Discuss lead ownership, eligibility, referral tracking and written terms before referring clients under the PHOENIX name."
    },
    affiliates: {
      symbol: "F",
      title: "Create content. Build connections.",
      description: "Discover creator partnerships, affiliate campaign coordination, product content and responsible promotion of properly approved brands.",
      next: "Contact your existing PHOENIX coordinator for verified campaigns and eligibility. No self-serve enrollment or payouts are available on this site."
    },
    staff: {
      symbol: "S",
      title: "Make live commerce a team sport.",
      description: "Discover PHOENIX’s work across hosting, moderation, production, content, editing, operations and client coordination.",
      next: "Use current verified hiring or coordinator channels for openings and interviews. Do not upload CVs or personal documents to this site."
    },
    operators: {
      symbol: "O",
      title: "Operations built on accountability.",
      description: "A future role-based workspace will support production workflows, account handling, approvals, reporting and audited access to assigned brands.",
      next: "Continue using verified internal channels. Staff and admin dashboards are not active; MFA and permission testing are required before launch."
    }
  });

  const roleButtons = Array.from(document.querySelectorAll("[data-audience]"));
  const symbol = document.getElementById("audience-symbol");
  const title = document.getElementById("audience-title");
  const description = document.getElementById("audience-text");
  const next = document.getElementById("audience-next");

  function selectRole(role, updateUrl) {
    if (!Object.prototype.hasOwnProperty.call(roles, role)) return;
    const data = roles[role];
    if (!symbol || !title || !description || !next) return;
    symbol.textContent = data.symbol;
    title.textContent = data.title;
    description.textContent = data.description;
    next.textContent = data.next;
    roleButtons.forEach(function (button) {
      const selected = button.getAttribute("data-audience") === role;
      button.classList.toggle("is-selected", selected);
      button.setAttribute("aria-pressed", selected ? "true" : "false");
    });
    if (updateUrl && window.history && window.history.replaceState) {
      const url = new URL(window.location.href);
      url.searchParams.set("role", role);
      window.history.replaceState(null, "", url.pathname + url.search + url.hash);
    }
  }

  roleButtons.forEach(function (button) {
    button.addEventListener("click", function () {
      selectRole(button.getAttribute("data-audience"), true);
    });
  });

  const requestedRole = new URLSearchParams(window.location.search).get("role");
  if (requestedRole && Object.prototype.hasOwnProperty.call(roles, requestedRole)) {
    selectRole(requestedRole, false);
  }

  const navButton = document.querySelector(".nav-toggle");
  const nav = document.getElementById("primary-navigation");
  if (navButton && nav) {
    function closeNavigation() {
      nav.classList.remove("is-open");
      navButton.setAttribute("aria-expanded", "false");
      navButton.setAttribute("aria-label", "Open navigation");
    }
    navButton.addEventListener("click", function () {
      const shouldOpen = !nav.classList.contains("is-open");
      nav.classList.toggle("is-open", shouldOpen);
      navButton.setAttribute("aria-expanded", shouldOpen ? "true" : "false");
      navButton.setAttribute("aria-label", shouldOpen ? "Close navigation" : "Open navigation");
    });
    nav.querySelectorAll("a").forEach(function (link) {
      link.addEventListener("click", closeNavigation);
    });
    document.addEventListener("keydown", function (event) {
      if (event.key === "Escape") closeNavigation();
    });
  }

  const year = document.getElementById("year");
  if (year) year.textContent = String(new Date().getFullYear());
}());
