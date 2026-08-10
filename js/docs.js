import { marked } from "https://cdn.jsdelivr.net/npm/marked/lib/marked.esm.js";

const documentation = document.getElementById("documentation");
const loading = document.getElementById("loading");
const error = document.getElementById("error");
const sidebar = document.getElementById("sidebar");
const mobileMenuButton = document.getElementById("mobile-menu-button");

const documents = {
    home: "README.md",
    server: "docs/server.md",
    desktop: "docs/desktop.md",
    esp: "docs/esp.md",
    "release-1.0.0": "releases/1.0.0/README.md"
};

marked.setOptions({ gfm: true, breaks: false });

function getRoute() {
    const hash = window.location.hash || "#/";
    if (!hash.startsWith("#/")) return "home";

    const path = hash.slice(2).replace(/\/+$/, "");
    if (path === "") return "home";
    if (path === "server") return "server";
    if (path === "desktop") return "desktop";
    if (path === "esp") return "esp";
    if (path === "releases/1.0.0") return "release-1.0.0";
    return null;
}

function setActiveNavigation(route) {
    document.querySelectorAll("[data-route]").forEach((link) => {
        const active = link.dataset.route === route;
        link.classList.toggle("active", active);
        if (active) link.setAttribute("aria-current", "page");
        else link.removeAttribute("aria-current");
    });
}

function closeMobileNavigation() {
    sidebar.classList.remove("open");
    mobileMenuButton.setAttribute("aria-expanded", "false");
}

function configureMarkdownLinks() {
    documentation.querySelectorAll("a[href]").forEach((link) => {
        const href = link.getAttribute("href");
        if (!href || href.startsWith("#")) return;
        if (href.startsWith("http://") || href.startsWith("https://") || href.startsWith("mailto:")) {
            link.target = "_blank";
            link.rel = "noopener noreferrer";
        }
    });
}

async function loadDocument(route) {
    const path = documents[route];
    if (!path) throw new Error("Documentation page not found.");

    loading.hidden = false;
    error.hidden = true;
    documentation.innerHTML = "";

    try {
        const response = await fetch(path, { cache: "no-cache" });
        if (!response.ok) throw new Error(`Unable to load documentation: ${response.status} ${response.statusText}`);

        const markdown = await response.text();
        documentation.innerHTML = marked.parse(markdown);
        configureMarkdownLinks();
        document.title = getPageTitle(route);
        setActiveNavigation(route);
    } finally {
        loading.hidden = true;
    }
}

function getPageTitle(route) {
    return {
        home: "InternetCafe System Documentation",
        server: "Server — InternetCafe System",
        desktop: "Desktop — InternetCafe System",
        esp: "ESP — InternetCafe System",
        "release-1.0.0": "Release 1.0.0 — InternetCafe System"
    }[route] || "InternetCafe System Documentation";
}

async function render() {
    const route = getRoute();
    if (!route) {
        window.location.hash = "#/";
        return;
    }

    try {
        await loadDocument(route);
    } catch (exception) {
        loading.hidden = true;
        documentation.innerHTML = "";
        error.hidden = false;
        error.textContent = `Unable to load this documentation page. ${exception.message}`;
        setActiveNavigation(route);
    }
}

mobileMenuButton.addEventListener("click", () => {
    const isOpen = sidebar.classList.toggle("open");
    mobileMenuButton.setAttribute("aria-expanded", String(isOpen));
});

sidebar.addEventListener("click", (event) => {
    if (event.target.closest("a")) closeMobileNavigation();
});

window.addEventListener("hashchange", render);
render();
