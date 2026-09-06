# Quiploy.com Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the BootstrapMade "Knight" Hugo theme with a custom, hand-authored Hugo theme and rewritten Portuguese content for the quiploy.com single-page landing site.

**Architecture:** Hugo stays as the generator and Netlify build. The `themes/Knight/` directory is deleted and replaced by root-level `layouts/`, `assets/`, and `data/`. One hand-written stylesheet (CSS custom properties, flв/grid — no framework), one ~15-line vanilla JS file for the mobile nav only, content for services and cases in `data/*.yaml`. Contact via Netlify Forms. No analytics.

**Tech Stack:** Hugo (extended) ≥ 0.128, plain CSS, vanilla JS, Netlify Forms, Netlify hosting, YAML data files.

**Spec:** `docs/superpowers/specs/2026-09-06-quiploy-rebuild-design.md` (read it alongside this plan).

## Verification model

This is a static marketing site. There is **no unit-test framework and none is added** (spec §6). The per-task "test cycle" is:

1. Make the change.
2. Run `hugo --gc --minify` — must exit 0 with **no `ERROR` or `WARN` lines**.
3. Run the task's `grep`/file-existence assertions against `public/` — must match the stated expected output.
4. Commit.

Where a step below says "Write the failing check", it means: run the assertion *before* implementing and confirm it fails (proves the check is real), then implement, then confirm it passes.

`hugo server -D` can be used for visual/manual checks; those are called out explicitly and are not blockers for commit except in Task 11–12.

## Global Constraints

Every task's requirements implicitly include all of these. Values are copied verbatim from the spec.

- **Language:** `languageCode = "pt-br"`; every HTML document root is `<html lang="pt-br">`. All copy is Portuguese (pt-BR).
- **No legacy JS:** nothing in `public/` may reference jQuery, Bootstrap, WOW.js, Isotope, classie, scrolltofixed, jquery-easing, respond, html5shiv, or Font Awesome.
- **Client names:** the only client names permitted anywhere in built output are exactly **`Tríade Patologia Veterinária`**, **`Clínica Marcela Monnerat`**, **`Hidrocenter`**, **`Donna Laser`**. No other client or repo name (`Sanploy`, `MISV`, `BPS4`, `LEC`, `ultraimagem`, `donnalaser`, `beatriz`) may appear.
- **No analytics:** no Google Tag Manager, no `gtag`, no `googletagmanager.com`, no `UA-118263902-1`, no replacement analytics.
- **Contact form:** Netlify Forms only — `data-netlify="true"`, a hidden `<input name="form-name" value="contato">`, and a `bot-field` honeypot. No reCAPTCHA. No cross-origin POST. No `send_contact_form.js`.
- **Build:** `hugo --gc --minify`; publish directory `public/`; Hugo ≥ 0.128.
- **Assets:** CSS and JS served through the Hugo asset pipeline — minified and fingerprinted, with SRI (`integrity`) attributes.
- **JS-optional:** the page is fully readable and the form is submittable with JavaScript disabled.
- **Logo:** reuse the existing `logo.png` bitmap as-is; do not redraw.
- **Accessibility:** semantic landmarks (`header`/`nav`/`main`/`footer`), visible `:focus-visible` styles, AA contrast, `prefers-reduced-motion: reduce` disables all motion, every form control has an associated `<label for>`.
- **Fonts:** two Google Fonts families — **Fraunces** (display) and **Inter** (text) — loaded with `preconnect` and `display=swap`, with a system fallback stack.
- **Content separation:** service and case copy live in `data/*.yaml`; partials render from data, not hardcoded lists. (The "Sobre" prose is the one exception — it lives in its partial.)

---

## File Structure

Created / modified across the plan:

| Path | Responsibility | Task |
|---|---|---|
| `config.toml` | site params, main menu, minify options; theme reference removed | 1, 10 |
| `netlify.toml` | build command, Hugo version pin, response headers | 10 |
| `static/img/*` | favicons + `logo.png` + `small-logo.png` + `footer-logo.png` (moved out of the theme) | 1 |
| `static/robots.txt` | crawl rules (moved out of the theme) | 1 |
| `layouts/index.html` | composition root for `/` — `<head>` + section partials | 2–9 |
| `layouts/_default/single.html` | layout for the `/obrigado/` page | 8 |
| `layouts/404.html` | styled not-found page | 9 |
| `layouts/partials/head.html` | document head, meta, favicons, fonts, CSS/JS pipeline | 2 |
| `layouts/partials/nav.html` | sticky header + mobile toggle target | 3 |
| `layouts/partials/hero.html` | name, positioning line, primary CTA | 4 |
| `layouts/partials/servicos.html` | service cards from `data/servicos.yaml` | 5 |
| `layouts/partials/sobre.html` | company description, approach, CNPJ line | 6 |
| `layouts/partials/cases.html` | four named case cards + anonymized list | 7 |
| `layouts/partials/contato.html` | Netlify form + phone/email/social | 8 |
| `layouts/partials/footer.html` | copyright + CNPJ + email | 9 |
| `assets/css/main.css` | the entire stylesheet | 2 (skeleton), 11 (full design) |
| `assets/js/site.js` | mobile nav toggle only | 3 |
| `data/servicos.yaml` | service card content | 5 |
| `data/cases.yaml` | case content (`destaque` + `outros`) | 7 |
| `content/obrigado.md` | thank-you page body | 8 |
| `themes/Knight/` | **deleted** | 1 |

---

## Task 1: Scaffold — install Hugo, rewrite config, keep favicons, delete the theme

**Files:**
- Modify: `config.toml`
- Create: `static/img/` (populated by moving files), `static/robots.txt`
- Delete: `themes/Knight/`

**Interfaces:**
- Consumes: nothing.
- Produces: a buildable Hugo site with no theme; `.Site.Params` keys `description`, `email`, `phone`, `phoneHref`, `cnpj`, `social.twitter`, `social.instagram`; `.Site.Menus.main` with four entries (Serviços/Cases/Sobre/Contato); favicons at `/img/favicon-32x32.png` etc. and `/img/logo.png`.

- [ ] **Step 1: Ensure Hugo ≥ 0.128 (extended) is available**

```bash
hugo version || {
  mkdir -p "$HOME/.local/bin"
  curl -sSL -o /tmp/hugo.tar.gz \
    https://github.com/gohugoio/hugo/releases/download/v0.128.0/hugo_extended_0.128.0_linux-amd64.tar.gz
  tar -xzf /tmp/hugo.tar.gz -C "$HOME/.local/bin" hugo
  export PATH="$HOME/.local/bin:$PATH"
}
hugo version
```

Expected: prints `hugo v0.128.0` (or newer) and `extended`. If `$HOME/.local/bin` is not already on `PATH`, add `export PATH="$HOME/.local/bin:$PATH"` to the shell profile so later tasks find it.

- [ ] **Step 2: Write the failing check**

```bash
hugo --gc --minify 2>&1 | tee /tmp/build.log; echo "exit=$?"
```

Expected right now: FAIL — build errors referencing the `Knight` theme / missing layouts, or a non-zero exit. This confirms we are actually replacing something.

- [ ] **Step 3: Move the assets worth keeping out of the theme**

```bash
mkdir -p static/img
git mv themes/Knight/static/robots.txt static/robots.txt
for f in favicon.ico favicon-16x16.png favicon-32x32.png favicon-96x96.png \
         apple-icon-57x57.png apple-icon-60x60.png apple-icon-72x72.png apple-icon-76x76.png \
         apple-icon-114x114.png apple-icon-120x120.png apple-icon-144x144.png \
         apple-icon-152x152.png apple-icon-180x180.png apple-icon.png apple-icon-precomposed.png \
         android-icon-36x36.png android-icon-48x48.png android-icon-72x72.png \
         android-icon-96x96.png android-icon-144x144.png android-icon-192x192.png \
         ms-icon-70x70.png ms-icon-144x144.png ms-icon-150x150.png ms-icon-310x310.png \
         logo.png small-logo.png footer-logo.png; do
  git mv "themes/Knight/static/img/$f" "static/img/$f"
done
```

Expected: no errors; `ls static/img` shows the favicon set plus the three logo files.

- [ ] **Step 4: Delete the theme**

```bash
git rm -r themes/Knight
```

Expected: the whole `themes/` tree is staged for deletion.

- [ ] **Step 5: Replace `config.toml`**

Overwrite `config.toml` with exactly:

```toml
baseURL = "https://www.quiploy.com/"
languageCode = "pt-br"
title = "Quiploy"
enableRobotsTXT = true

[params]
  description = "Software sob medida e automação de processos para operações brasileiras."
  email = "contato@quiploy.com"
  phone = "+55 21 99909-5870"
  phoneHref = "+5521999095870"
  cnpj = "23.612.194/0001-81"

  [params.social]
    twitter = "https://twitter.com/quiploy"
    instagram = "https://www.instagram.com/quiployhq"

[[menus.main]]
  name = "Serviços"
  url = "#servicos"
  weight = 10

[[menus.main]]
  name = "Cases"
  url = "#cases"
  weight = 20

[[menus.main]]
  name = "Sobre"
  url = "#sobre"
  weight = 30

[[menus.main]]
  name = "Contato"
  url = "#contato"
  weight = 40
```

- [ ] **Step 6: Add a minimal home layout so the site builds**

Create `layouts/index.html` with exactly:

```go-html-template
<!doctype html>
<html lang="{{ .Site.LanguageCode }}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{ .Site.Title }}</title>
</head>
<body>
  <main></main>
</body>
</html>
```

(This is replaced in Task 2. It exists only so Task 1 produces a green build.)

- [ ] **Step 7: Run the check — build is green**

```bash
rm -rf public && hugo --gc --minify 2>&1 | tee /tmp/build.log; echo "exit=$?"
grep -Eq '^(ERROR|WARN)' /tmp/build.log && echo "HAS WARNINGS/ERRORS" || echo "clean"
test -f public/index.html && echo "index ok"
grep -q '<html lang="pt-br"' public/index.html && echo "lang ok"
test -f public/img/favicon-32x32.png && echo "favicon ok"
test -f public/robots.txt && echo "robots ok"
! grep -riE 'jquery|bootstrap|wow\.js|isotope|googletagmanager' public && echo "no legacy assets"
```

Expected: `exit=0`, `clean`, `index ok`, `lang ok`, `favicon ok`, `robots ok`, `no legacy assets`.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "Scaffold rebuild: drop Knight theme, new config, keep favicons"
```

---

## Task 2: Base layout, head partial, CSS/JS pipeline, fonts

**Files:**
- Create: `layouts/partials/head.html`
- Create: `assets/css/main.css`
- Create: `assets/js/site.js`
- Modify: `layouts/index.html`

**Interfaces:**
- Consumes: `.Site.Params.description`, `.Site.Title`, `.Site.LanguageCode`.
- Produces: partial `head.html` (usable by every layout); fingerprinted `main.css` and `site.js` links with SRI; CSS custom properties `--bg`, `--fg`, `--muted`, `--accent`, `--maxw`, `--space` defined on `:root`; `.container` and `.visually-hidden` utility classes; body uses `<main>` landmark. `index.html` becomes the composition root that later tasks add partial calls to.

- [ ] **Step 1: Create `assets/js/site.js`**

```js
(function () {
  "use strict";

  var toggle = document.querySelector(".nav-toggle");
  var menu = document.getElementById("menu");
  if (!toggle || !menu) { return; }

  toggle.addEventListener("click", function () {
    var open = menu.classList.toggle("is-open");
    toggle.setAttribute("aria-expanded", open ? "true" : "false");
  });

  menu.addEventListener("click", function (evt) {
    if (evt.target.tagName === "A") {
      menu.classList.remove("is-open");
      toggle.setAttribute("aria-expanded", "false");
    }
  });
}());
```

- [ ] **Step 2: Create `assets/css/main.css` (skeleton only — full design is Task 11)**

```css
:root {
  --bg: #ffffff;
  --fg: #14161a;
  --muted: #5c636e;
  --accent: #1f6feb;
  --border: #e6e8ec;
  --maxw: 1100px;
  --space: clamp(3rem, 6vw, 5rem);
  --font-display: "Fraunces", Georgia, "Times New Roman", serif;
  --font-text: "Inter", system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
}

* { box-sizing: border-box; }

html {
  scroll-behavior: smooth;
}
@media (prefers-reduced-motion: reduce) {
  html { scroll-behavior: auto; }
}

body {
  margin: 0;
  background: var(--bg);
  color: var(--fg);
  font-family: var(--font-text);
  font-size: 1rem;
  line-height: 1.6;
  -webkit-font-smoothing: antialiased;
}

h1, h2, h3 { font-family: var(--font-display); line-height: 1.15; font-weight: 600; }

a { color: var(--accent); }

img { max-width: 100%; height: auto; display: block; }

.container {
  width: 100%;
  max-width: var(--maxw);
  margin-inline: auto;
  padding-inline: clamp(1.25rem, 4vw, 2.5rem);
}

.visually-hidden {
  position: absolute !important;
  width: 1px; height: 1px;
  padding: 0; margin: -1px;
  overflow: hidden; clip: rect(0 0 0 0);
  white-space: nowrap; border: 0;
}

:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}
```

- [ ] **Step 3: Create `layouts/partials/head.html`**

```go-html-template
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{ if .IsHome }}{{ .Site.Title }} — Desenvolvimento de software e automação de processos{{ else }}{{ .Title }} — {{ .Site.Title }}{{ end }}</title>
  <meta name="description" content="{{ .Site.Params.description }}">

  <link rel="icon" type="image/png" sizes="32x32" href="/img/favicon-32x32.png">
  <link rel="icon" type="image/png" sizes="16x16" href="/img/favicon-16x16.png">
  <link rel="apple-touch-icon" sizes="180x180" href="/img/apple-icon-180x180.png">
  <meta name="theme-color" content="#ffffff">

  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,400;9..144,600&family=Inter:wght@400;500;600&display=swap">

  {{ $css := resources.Get "css/main.css" | minify | fingerprint "sha512" }}
  <link rel="stylesheet" href="{{ $css.RelPermalink }}" integrity="{{ $css.Data.Integrity }}">

  {{ $js := resources.Get "js/site.js" | minify | fingerprint "sha512" }}
  <script defer src="{{ $js.RelPermalink }}" integrity="{{ $js.Data.Integrity }}"></script>

  <meta property="og:title" content="{{ .Site.Title }}">
  <meta property="og:description" content="{{ .Site.Params.description }}">
  <meta property="og:type" content="website">
  <meta property="og:url" content="{{ .Permalink }}">
</head>
```

- [ ] **Step 4: Replace `layouts/index.html` with the composition root**

```go-html-template
<!doctype html>
<html lang="{{ .Site.LanguageCode }}">
{{ partial "head.html" . }}
<body>
  <main>
  </main>
</body>
</html>
```

- [ ] **Step 5: Run the checks**

```bash
rm -rf public && hugo --gc --minify 2>&1 | tee /tmp/build.log; echo "exit=$?"
grep -Eq '^(ERROR|WARN)' /tmp/build.log && echo "WARN/ERROR" || echo "clean"
grep -Eq 'href="/css/main\.[0-9a-f]+\.css" integrity="sha512-' public/index.html && echo "css fingerprinted+SRI"
grep -Eq 'src="/js/site\.[0-9a-f]+\.js" integrity="sha512-' public/index.html && echo "js fingerprinted+SRI"
grep -q 'fonts.googleapis.com/css2?family=Fraunces' public/index.html && echo "fonts ok"
grep -q '<main>' public/index.html && echo "main landmark ok"
```

Expected: `exit=0`, `clean`, `css fingerprinted+SRI`, `js fingerprinted+SRI`, `fonts ok`, `main landmark ok`.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "Add base layout, head partial, CSS/JS asset pipeline, fonts"
```

---

## Task 3: Navigation header + mobile toggle

**Files:**
- Create: `layouts/partials/nav.html`
- Modify: `layouts/index.html` (add nav partial call)
- Modify: `assets/css/main.css` (structural nav rules only)

**Interfaces:**
- Consumes: `.Site.Menus.main`, `/img/logo.png`.
- Produces: partial `nav.html`; DOM contract for `site.js` — a `<button class="nav-toggle" aria-expanded aria-controls="menu">` and `<nav id="menu" class="nav-menu">`; JS toggles class `is-open` on `#menu`. CSS classes for Task 11 to style: `.site-header`, `.nav-inner`, `.brand`, `.nav-toggle`, `.nav-menu`, `.nav-menu.is-open`.

- [ ] **Step 1: Create `layouts/partials/nav.html`**

```go-html-template
<header class="site-header">
  <div class="container nav-inner">
    <a class="brand" href="#topo">
      <img src="/img/logo.png" alt="Quiploy" width="120" height="40">
    </a>
    <button class="nav-toggle" type="button" aria-expanded="false" aria-controls="menu">
      <span class="visually-hidden">Abrir menu</span>
      <span class="nav-toggle-bar" aria-hidden="true"></span>
      <span class="nav-toggle-bar" aria-hidden="true"></span>
      <span class="nav-toggle-bar" aria-hidden="true"></span>
    </button>
    <nav id="menu" class="nav-menu" aria-label="Navegação principal">
      <ul>
        {{ range .Site.Menus.main }}
        <li><a href="{{ .URL }}">{{ .Name }}</a></li>
        {{ end }}
      </ul>
    </nav>
  </div>
</header>
```

- [ ] **Step 2: Add the call to `layouts/index.html`**

Change the body so it reads:

```go-html-template
<body>
  {{ partial "nav.html" . }}
  <main>
  </main>
</body>
```

- [ ] **Step 3: Append structural nav rules to `assets/css/main.css`**

```css
.site-header {
  position: sticky;
  top: 0;
  z-index: 10;
  background: var(--bg);
  border-bottom: 1px solid var(--border);
}
.nav-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding-block: 0.75rem;
}
.nav-menu ul {
  display: flex;
  gap: 1.5rem;
  list-style: none;
  margin: 0;
  padding: 0;
}
.nav-menu a { color: var(--fg); text-decoration: none; }
.nav-toggle { display: none; }

@media (max-width: 720px) {
  .nav-toggle {
    display: inline-flex;
    flex-direction: column;
    gap: 4px;
    background: none;
    border: 0;
    padding: 0.5rem;
    cursor: pointer;
  }
  .nav-toggle-bar {
    width: 22px;
    height: 2px;
    background: var(--fg);
  }
  .nav-menu {
    display: none;
    position: absolute;
    left: 0;
    right: 0;
    top: 100%;
    background: var(--bg);
    border-bottom: 1px solid var(--border);
  }
  .nav-menu.is-open { display: block; }
  .nav-menu ul { flex-direction: column; gap: 0; }
  .nav-menu li { padding: 0.25rem clamp(1.25rem, 4vw, 2.5rem); }
}
```

- [ ] **Step 4: Run the checks**

```bash
rm -rf public && hugo --gc --minify 2>&1 | tee /tmp/build.log; echo "exit=$?"
grep -Eq '^(ERROR|WARN)' /tmp/build.log && echo "WARN/ERROR" || echo "clean"
grep -q 'class="site-header"' public/index.html && echo "header ok"
grep -q 'aria-controls="menu"' public/index.html && echo "toggle ok"
for w in Serviços Cases Sobre Contato; do grep -q ">$w<" public/index.html && echo "menu:$w ok"; done
JS=$(ls public/js/site.*.js); grep -q 'nav-toggle' "$JS" && grep -q 'is-open' "$JS" && echo "js ok"
```

Expected: `exit=0`, `clean`, `header ok`, `toggle ok`, four `menu:… ok` lines, `js ok`.

- [ ] **Step 5: Manual check (not a commit blocker)**

`hugo server` → open `http://localhost:1313`, narrow the window below 720px, click the toggle: menu shows/hides and `aria-expanded` flips. Tab through: focus ring visible on links and the button.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "Add sticky nav header with accessible mobile toggle"
```

---

## Task 4: Hero section

**Files:**
- Create: `layouts/partials/hero.html`
- Modify: `layouts/index.html`

**Interfaces:**
- Consumes: nothing (copy is inline, per spec — hero is not data-driven).
- Produces: partial `hero.html`; an element with `id="topo"` (the brand link target); CSS classes for Task 11: `.hero`, `.eyebrow`, `.hero-lead`, `.btn`, `.btn-primary`.

- [ ] **Step 1: Create `layouts/partials/hero.html`**

```go-html-template
<section class="hero" id="topo">
  <div class="container">
    <p class="eyebrow">Quiploy</p>
    <h1>Software sob medida e automação de processos para operações brasileiras.</h1>
    <p class="hero-lead">
      Sistemas de gestão, integrações e automação fiscal em Python e Django —
      construídos, migrados e mantidos por quem acompanha o sistema em produção.
    </p>
    <a class="btn btn-primary" href="#contato">Fale com a gente</a>
  </div>
</section>
```

- [ ] **Step 2: Add the call to `layouts/index.html`** (inside `<main>`)

```go-html-template
  <main>
    {{ partial "hero.html" . }}
  </main>
```

- [ ] **Step 3: Append minimal button rules to `assets/css/main.css`**

```css
.btn {
  display: inline-block;
  padding: 0.75rem 1.5rem;
  border-radius: 4px;
  font-weight: 500;
  text-decoration: none;
  border: 1px solid var(--accent);
  color: var(--accent);
}
.btn-primary {
  background: var(--accent);
  color: #fff;
}
.hero { padding-block: var(--space); }
.hero h1 { font-size: clamp(2rem, 5vw, 3.25rem); max-width: 18ch; }
.hero-lead { font-size: 1.125rem; max-width: 60ch; color: var(--muted); }
.eyebrow { text-transform: uppercase; letter-spacing: 0.08em; font-size: 0.8rem; color: var(--muted); margin: 0 0 0.5rem; }
```

- [ ] **Step 4: Run the checks**

```bash
rm -rf public && hugo --gc --minify 2>&1 | tee /tmp/build.log; echo "exit=$?"
grep -Eq '^(ERROR|WARN)' /tmp/build.log && echo "WARN/ERROR" || echo "clean"
grep -q 'Software sob medida e automação de processos para operações brasileiras.' public/index.html && echo "headline ok"
grep -q 'class="btn btn-primary" href="#contato"' public/index.html && echo "cta ok"
grep -q 'id="topo"' public/index.html && echo "anchor ok"
```

Expected: `exit=0`, `clean`, `headline ok`, `cta ok`, `anchor ok`.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "Add hero section"
```

---

## Task 5: Serviços section (data-driven)

**Files:**
- Create: `data/servicos.yaml`
- Create: `layouts/partials/servicos.html`
- Modify: `layouts/index.html`

**Interfaces:**
- Consumes: `.Site.Data.servicos` — a list of `{title: string, description: string}`.
- Produces: partial `servicos.html`; `<section id="servicos">`; repeated `<article class="card service-card">`; CSS classes for Task 11: `.section`, `.section-title`, `.grid`, `.grid-2`, `.card`, `.service-card`.

- [ ] **Step 1: Create `data/servicos.yaml`**

```yaml
- title: "Sistemas de gestão sob medida"
  description: >-
    ERPs verticais para o seu nicho — clínicas, laboratórios, locação de
    equipamentos, construção civil, contabilidade. Cadastro, agenda,
    financeiro, estoque e relatórios, com trilha de auditoria, controle de
    acesso por perfil e histórico completo de alterações.
- title: "Automação fiscal e contábil"
  description: >-
    Importação de NF-e, cálculo de ICMS, PIS e COFINS e apuração de créditos,
    emissão de NFS-e Nacional com assinatura digital, e consolidação
    automática de dados exportados de ERPs como Datasul, Protheus e Domínio.
- title: "Integrações sob demanda"
  description: >-
    Conecte o que você já usa: WhatsApp Business (Meta Cloud API), gateways de
    pagamento como Pagar.me e PagSeguro, e-mail transacional, SMS e geração de
    documentos em PDF.
- title: "Migração e suporte de legado"
  description: >-
    Recuperação de sistemas antigos, atualização de versão e migração de
    dados, seguidas de manutenção contínua com SLA, backup automático e
    monitoramento de erros.
```

- [ ] **Step 2: Create `layouts/partials/servicos.html`**

```go-html-template
<section class="section" id="servicos">
  <div class="container">
    <h2 class="section-title">Serviços</h2>
    <div class="grid grid-2">
      {{ range .Site.Data.servicos }}
      <article class="card service-card">
        <h3>{{ .title }}</h3>
        <p>{{ .description }}</p>
      </article>
      {{ end }}
    </div>
  </div>
</section>
```

- [ ] **Step 3: Add the call to `layouts/index.html`** (after hero)

```go-html-template
    {{ partial "hero.html" . }}
    {{ partial "servicos.html" . }}
```

- [ ] **Step 4: Append minimal section/grid rules to `assets/css/main.css`**

```css
.section { padding-block: var(--space); border-top: 1px solid var(--border); }
.section-title { font-size: clamp(1.5rem, 3vw, 2rem); margin: 0 0 2rem; }
.grid { display: grid; gap: 1.5rem; }
.grid-2 { grid-template-columns: repeat(2, 1fr); }
.card { padding: 1.5rem; border: 1px solid var(--border); border-radius: 6px; }
.card h3 { margin-top: 0; }
@media (max-width: 720px) {
  .grid-2 { grid-template-columns: 1fr; }
}
```

- [ ] **Step 5: Run the checks**

```bash
rm -rf public && hugo --gc --minify 2>&1 | tee /tmp/build.log; echo "exit=$?"
grep -Eq '^(ERROR|WARN)' /tmp/build.log && echo "WARN/ERROR" || echo "clean"
test "$(grep -c 'class="card service-card"' public/index.html)" = "4" && echo "4 cards ok"
grep -q 'id="servicos"' public/index.html && echo "anchor ok"
grep -q 'Automação fiscal e contábil' public/index.html && echo "content ok"
```

Expected: `exit=0`, `clean`, `4 cards ok`, `anchor ok`, `content ok`.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "Add serviços section driven by data/servicos.yaml"
```

---

## Task 6: Sobre section

**Files:**
- Create: `layouts/partials/sobre.html`
- Modify: `layouts/index.html`

**Interfaces:**
- Consumes: `.Site.Params.cnpj`, `.Site.Params.email`, `.Site.Params.phone`.
- Produces: partial `sobre.html`; `<section id="sobre">`; CSS classes for Task 11: `.section-alt`, `.prose`, `.muted`.

> **Copy note for the executor:** the founding year is intentionally *not* stated (the owner must confirm it before adding one). Do not insert a year.

- [ ] **Step 1: Create `layouts/partials/sobre.html`**

```go-html-template
<section class="section section-alt" id="sobre">
  <div class="container">
    <h2 class="section-title">Sobre</h2>
    <div class="prose">
      <p>
        A Quiploy desenvolve software sob medida em Python e Django, com
        sistemas em produção em clínicas, laboratórios, comércio e
        organizações de diferentes portes.
      </p>
      <p>
        Trabalhamos com os padrões que um sistema de negócio exige: exclusão
        reversível (soft delete), trilha de auditoria em todos os registros,
        permissões por perfil e testes automatizados. Entregamos, implantamos
        e mantemos — do primeiro cadastro ao suporte com SLA.
      </p>
      <p class="muted">
        Quiploy · CNPJ {{ .Site.Params.cnpj }} ·
        <a href="mailto:{{ .Site.Params.email }}">{{ .Site.Params.email }}</a> ·
        {{ .Site.Params.phone }}
      </p>
    </div>
  </div>
</section>
```

- [ ] **Step 2: Add the call to `layouts/index.html`** (after serviços)

```go-html-template
    {{ partial "servicos.html" . }}
    {{ partial "sobre.html" . }}
```

- [ ] **Step 3: Append minimal rules to `assets/css/main.css`**

```css
.section-alt { background: #f7f8fa; }
.prose { max-width: 65ch; }
.prose p { margin-block: 0 1rem; }
.muted { color: var(--muted); font-size: 0.95rem; }
```

- [ ] **Step 4: Run the checks**

```bash
rm -rf public && hugo --gc --minify 2>&1 | tee /tmp/build.log; echo "exit=$?"
grep -Eq '^(ERROR|WARN)' /tmp/build.log && echo "WARN/ERROR" || echo "clean"
grep -q 'id="sobre"' public/index.html && echo "anchor ok"
grep -q '23.612.194/0001-81' public/index.html && echo "cnpj ok"
grep -q 'soft delete' public/index.html && echo "content ok"
grep -Eq '(desde|há) (19|20)[0-9]{2}' public/index.html && echo "UNWANTED YEAR" || echo "no year ok"
```

Expected: `exit=0`, `clean`, `anchor ok`, `cnpj ok`, `content ok`, `no year ok`.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "Add sobre section"
```

---

## Task 7: Cases section (data-driven, name allowlist enforced)

**Files:**
- Create: `data/cases.yaml`
- Create: `layouts/partials/cases.html`
- Modify: `layouts/index.html`

**Interfaces:**
- Consumes: `.Site.Data.cases.destaque` — list of `{cliente, setor, resumo}`; `.Site.Data.cases.outros` — list of strings.
- Produces: partial `cases.html`; `<section id="cases">`; repeated `<article class="card case-card">` (exactly 4); `<ul>` of anonymized items; CSS classes for Task 11: `.case-card`, `.case-setor`, `.cases-outros`.

- [ ] **Step 1: Create `data/cases.yaml`**

```yaml
destaque:
  - cliente: "Tríade Patologia Veterinária"
    setor: "Laboratório de patologia veterinária"
    resumo: >-
      Sistema de gestão de laboratório: cadastro de clientes e animais,
      requisições de oito tipos de exame com numeração sequencial anual,
      laudos em PDF com assinatura digital e fotomicrografias, e dashboards de
      produtividade por tipo de exame, técnico e período.
  - cliente: "Clínica Marcela Monnerat"
    setor: "Clínica médica e estética"
    resumo: >-
      Plataforma de gestão clínica: prontuário, evoluções e prescrições,
      agenda, pagamentos, recebíveis e comissões, controle de estoque,
      emissão de NFS-e Nacional e comunicação com pacientes via WhatsApp.
  - cliente: "Hidrocenter"
    setor: "Materiais hidráulicos e construção civil"
    resumo: >-
      Gestão de propostas comerciais, obras em andamento com controle
      financeiro (notas, serviços, instaladores e saldo da obra), almoxarifado
      com movimentações e custo médio, e controle de acesso por perfil com
      isolamento de dados por vendedor.
  - cliente: "Donna Laser"
    setor: "Locação de equipamentos a laser"
    resumo: >-
      Gestão de locação: contratos com dezenas de modelos, agenda de
      equipamentos com arrastar-e-soltar, pagamentos parcelados, controle de
      despesas e entregas, e assinatura de contrato por link com token.
outros:
  - >-
    Automação fiscal e contábil para escritório de contabilidade — importação
    de NF-e, apuração de créditos PIS/COFINS e consolidação do razão contábil
    de três ERPs.
  - >-
    Recuperação e migração de sistema hospitalar legado — ambiente restaurado,
    base de milhares de registros migrada e validada, seguida de manutenção
    mensal com SLA.
  - >-
    Sistema de gestão financeira para organizações religiosas — membros,
    contribuições, despesas e balanços mensais e anuais.
```

- [ ] **Step 2: Create `layouts/partials/cases.html`**

```go-html-template
<section class="section" id="cases">
  <div class="container">
    <h2 class="section-title">Cases</h2>
    <div class="grid grid-2">
      {{ range .Site.Data.cases.destaque }}
      <article class="card case-card">
        <h3>{{ .cliente }}</h3>
        <p class="case-setor">{{ .setor }}</p>
        <p>{{ .resumo }}</p>
      </article>
      {{ end }}
    </div>
    <div class="cases-outros">
      <h3>E também</h3>
      <ul>
        {{ range .Site.Data.cases.outros }}
        <li>{{ . }}</li>
        {{ end }}
      </ul>
    </div>
  </div>
</section>
```

- [ ] **Step 3: Add the call to `layouts/index.html`** (after sobre)

```go-html-template
    {{ partial "sobre.html" . }}
    {{ partial "cases.html" . }}
```

- [ ] **Step 4: Append minimal rules to `assets/css/main.css`**

```css
.case-setor { color: var(--muted); font-size: 0.9rem; margin: 0 0 0.75rem; }
.cases-outros { margin-top: 2.5rem; }
.cases-outros ul { padding-left: 1.25rem; max-width: 70ch; }
.cases-outros li { margin-bottom: 0.75rem; }
```

- [ ] **Step 5: Run the checks — content present**

```bash
rm -rf public && hugo --gc --minify 2>&1 | tee /tmp/build.log; echo "exit=$?"
grep -Eq '^(ERROR|WARN)' /tmp/build.log && echo "WARN/ERROR" || echo "clean"
test "$(grep -c 'class="card case-card"' public/index.html)" = "4" && echo "4 case cards ok"
for c in "Tríade Patologia Veterinária" "Clínica Marcela Monnerat" "Hidrocenter" "Donna Laser"; do
  grep -qF "$c" public/index.html && echo "case:$c ok"
done
```

Expected: `exit=0`, `clean`, `4 case cards ok`, four `case:… ok` lines.

- [ ] **Step 6: Run the checks — name allowlist enforced**

```bash
# No forbidden client / repo names anywhere in the built output.
if grep -riE '\b(sanploy|misv|bps4|ultraimagem|beatriz|donnalaser)\b|donna laser locações' public/; then
  echo "FORBIDDEN NAME FOUND"; else echo "allowlist ok"; fi
# "LEC" as a standalone token (avoid matching words like 'eLECtron')
grep -rE '\bLEC\b' public/ && echo "LEC FOUND" || echo "no LEC ok"
```

Expected: `allowlist ok`, `no LEC ok`. If either fails, remove the offending name — do not proceed.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "Add cases section with four named cases plus anonymized work"
```

---

## Task 8: Contato section — Netlify form + /obrigado page

**Files:**
- Create: `layouts/partials/contato.html`
- Create: `content/obrigado.md`
- Create: `layouts/_default/single.html`
- Modify: `layouts/index.html`

**Interfaces:**
- Consumes: `.Site.Params.phone`, `.Site.Params.phoneHref`, `.Site.Params.email`, `.Site.Params.social.twitter`, `.Site.Params.social.instagram`; partials `head.html`, `nav.html`, `footer.html` (footer created in Task 9 — see Step 3 note).
- Produces: partial `contato.html`; `<section id="contato">` containing a `<form name="contato" data-netlify="true">`; the route `/obrigado/`; CSS classes for Task 11: `.section-dark`, `.contato-info`, `.contato-form`, `.hp-field`, `.social`.

- [ ] **Step 1: Create `layouts/partials/contato.html`**

```go-html-template
<section class="section section-dark" id="contato">
  <div class="container grid grid-2">
    <div class="contato-info">
      <h2 class="section-title">Vamos conversar?</h2>
      <p><a href="tel:{{ .Site.Params.phoneHref }}">{{ .Site.Params.phone }}</a></p>
      <p><a href="mailto:{{ .Site.Params.email }}">{{ .Site.Params.email }}</a></p>
      <ul class="social">
        <li><a href="{{ .Site.Params.social.twitter }}" rel="noopener">Twitter</a></li>
        <li><a href="{{ .Site.Params.social.instagram }}" rel="noopener">Instagram</a></li>
      </ul>
    </div>

    <form name="contato" method="POST" action="/obrigado/"
          data-netlify="true" netlify-honeypot="bot-field" class="contato-form">
      <input type="hidden" name="form-name" value="contato">
      <p class="hp-field">
        <label>Não preencha este campo: <input name="bot-field"></label>
      </p>
      <p>
        <label for="nome">Nome</label>
        <input type="text" id="nome" name="nome" required>
      </p>
      <p>
        <label for="email">E-mail</label>
        <input type="email" id="email" name="email" required>
      </p>
      <p>
        <label for="assunto">Assunto</label>
        <input type="text" id="assunto" name="assunto">
      </p>
      <p>
        <label for="mensagem">Mensagem</label>
        <textarea id="mensagem" name="mensagem" rows="5" required></textarea>
      </p>
      <button type="submit" class="btn btn-primary">Enviar mensagem</button>
    </form>
  </div>
</section>
```

- [ ] **Step 2: Create `content/obrigado.md`**

```markdown
---
title: "Mensagem enviada"
---

Recebemos sua mensagem e retornaremos em breve. Obrigado pelo contato.
```

- [ ] **Step 3: Create `layouts/_default/single.html`**

```go-html-template
<!doctype html>
<html lang="{{ .Site.LanguageCode }}">
{{ partial "head.html" . }}
<body>
  {{ partial "nav.html" . }}
  <main class="page-narrow">
    <section class="section">
      <div class="container prose">
        <h1>{{ .Title }}</h1>
        {{ .Content }}
        <p><a class="btn" href="/">Voltar para a página inicial</a></p>
      </div>
    </section>
  </main>
  {{ partial "footer.html" . }}
</body>
</html>
```

> Note: `footer.html` does not exist until Task 9. If executing strictly in order, temporarily create `layouts/partials/footer.html` as an empty file now and fill it in Task 9, OR reorder to do Task 9 before Task 8. The subagent runner should create the empty placeholder file in this step and let Task 9 own its content:
> `mkdir -p layouts/partials && [ -f layouts/partials/footer.html ] || printf '' > layouts/partials/footer.html`

- [ ] **Step 4: Add the call to `layouts/index.html`** (after cases)

```go-html-template
    {{ partial "cases.html" . }}
    {{ partial "contato.html" . }}
```

- [ ] **Step 5: Append minimal rules to `assets/css/main.css`**

```css
.hp-field { position: absolute; left: -9999px; }
.contato-form p { margin: 0 0 1rem; }
.contato-form label { display: block; margin-bottom: 0.25rem; font-size: 0.9rem; }
.contato-form input,
.contato-form textarea {
  width: 100%;
  padding: 0.6rem 0.75rem;
  font: inherit;
  border: 1px solid var(--border);
  border-radius: 4px;
  background: #fff;
  color: var(--fg);
}
.social { list-style: none; padding: 0; display: flex; gap: 1rem; }
```

- [ ] **Step 6: Run the checks**

```bash
rm -rf public && hugo --gc --minify 2>&1 | tee /tmp/build.log; echo "exit=$?"
grep -Eq '^(ERROR|WARN)' /tmp/build.log && echo "WARN/ERROR" || echo "clean"
grep -q 'name="contato" method="POST" action="/obrigado/"' public/index.html && echo "form attrs ok"
grep -q 'data-netlify="true"' public/index.html && echo "netlify ok"
grep -q 'netlify-honeypot="bot-field"' public/index.html && echo "honeypot ok"
grep -q '<input type="hidden" name="form-name" value="contato">' public/index.html && echo "form-name ok"
for f in nome email assunto mensagem; do grep -q "name=\"$f\"" public/index.html && echo "field:$f ok"; done
for f in nome email assunto mensagem; do grep -q "for=\"$f\"" public/index.html && echo "label:$f ok"; done
test -f public/obrigado/index.html && echo "obrigado route ok"
grep -q 'Recebemos sua mensagem' public/obrigado/index.html && echo "obrigado copy ok"
grep -q 'href="/"' public/obrigado/index.html && echo "obrigado backlink ok"
```

Expected: all lines end in `ok`.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "Add contato section with Netlify form and /obrigado page"
```

---

## Task 9: Footer + styled 404

**Files:**
- Create/replace: `layouts/partials/footer.html` (the placeholder from Task 8 gets its real content)
- Create: `layouts/404.html`
- Modify: `layouts/index.html`

**Interfaces:**
- Consumes: `.Site.Params.cnpj`, `.Site.Params.email`; partials `head.html`, `nav.html`, `footer.html`.
- Produces: partial `footer.html`; the `<footer class="site-footer">` landmark; `layouts/404.html` rendering at `public/404.html`. CSS class for Task 11: `.site-footer`, `.page-narrow`.

- [ ] **Step 1: Write `layouts/partials/footer.html`**

```go-html-template
<footer class="site-footer">
  <div class="container">
    <p>&copy; {{ now.Year }} Quiploy · CNPJ {{ .Site.Params.cnpj }}</p>
    <p><a href="mailto:{{ .Site.Params.email }}">{{ .Site.Params.email }}</a></p>
  </div>
</footer>
```

- [ ] **Step 2: Add the call to `layouts/index.html`** (after `</main>`)

```go-html-template
  </main>
  {{ partial "footer.html" . }}
</body>
```

- [ ] **Step 3: Create `layouts/404.html`**

```go-html-template
<!doctype html>
<html lang="{{ .Site.LanguageCode }}">
{{ partial "head.html" . }}
<body>
  {{ partial "nav.html" . }}
  <main class="page-narrow">
    <section class="section">
      <div class="container prose">
        <h1>Página não encontrada</h1>
        <p>O endereço que você procurou não existe ou foi movido.</p>
        <p><a class="btn" href="/">Voltar para a página inicial</a></p>
      </div>
    </section>
  </main>
  {{ partial "footer.html" . }}
</body>
</html>
```

- [ ] **Step 4: Append minimal rules to `assets/css/main.css`**

```css
.site-footer {
  border-top: 1px solid var(--border);
  padding-block: 2rem;
  color: var(--muted);
  font-size: 0.9rem;
}
.site-footer p { margin: 0.25rem 0; }
.page-narrow { min-height: 60vh; }
```

- [ ] **Step 5: Run the checks**

```bash
rm -rf public && hugo --gc --minify 2>&1 | tee /tmp/build.log; echo "exit=$?"
grep -Eq '^(ERROR|WARN)' /tmp/build.log && echo "WARN/ERROR" || echo "clean"
grep -q 'class="site-footer"' public/index.html && echo "footer ok"
grep -Eq "© 20[0-9]{2} Quiploy" public/index.html && echo "copyright ok"
test -f public/404.html && echo "404 exists"
grep -q 'Página não encontrada' public/404.html && echo "404 copy ok"
grep -Eq 'href="/css/main\.[0-9a-f]+\.css"' public/404.html && echo "404 styled ok"
```

Expected: all lines end in `ok` / `exists`.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "Add footer and styled 404 page"
```

---

## Task 10: netlify.toml + build hardening + full output audit

**Files:**
- Create: `netlify.toml`
- Modify: `config.toml` (add `[minify]` block)

**Interfaces:**
- Consumes: the whole built `public/` tree.
- Produces: `netlify.toml` with build command, `HUGO_VERSION`, and security/cache headers; a repeatable audit script that later tasks and CI-by-hand can rerun.

- [ ] **Step 1: Create `netlify.toml`**

```toml
[build]
  command = "hugo --gc --minify"
  publish = "public"

[build.environment]
  HUGO_VERSION = "0.128.0"

[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-Content-Type-Options = "nosniff"
    Referrer-Policy = "strict-origin-when-cross-origin"

[[headers]]
  for = "/css/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"

[[headers]]
  for = "/js/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"
```

- [ ] **Step 2: Add a `[minify]` block to `config.toml`**

Append:

```toml
[minify]
  disableXML = false
  minifyOutput = true
```

- [ ] **Step 3: Write the full audit script and run it**

Create `/tmp/audit.sh`:

```bash
#!/usr/bin/env bash
set -u
fail=0
note() { echo "$1"; }
check() { if eval "$2"; then note "ok   $1"; else note "FAIL $1"; fail=1; fi; }

rm -rf public
hugo --gc --minify 2>&1 | tee /tmp/build.log
check "build exits 0"            '[ "${PIPESTATUS[0]:-0}" -eq 0 ] || [ $? -eq 0 ]'
check "no ERROR/WARN lines"      '! grep -Eq "^(ERROR|WARN)" /tmp/build.log'

check "no google analytics"      '! grep -rqiE "googletagmanager|gtag\(|UA-118263902" public/'
check "no jquery/bootstrap/etc"  '! grep -rqiE "jquery|bootstrap|wow\.js|isotope|classie|scrolltofixed|fontawesome|font-awesome" public/'
check "css fingerprinted"        'grep -Eq "href=\"/css/main\.[0-9a-f]+\.css\" integrity=\"sha512-" public/index.html'
check "js fingerprinted"         'grep -Eq "src=\"/js/site\.[0-9a-f]+\.js\" integrity=\"sha512-" public/index.html'
check "home exists"              '[ -f public/index.html ]'
check "obrigado exists"          '[ -f public/obrigado/index.html ]'
check "404 exists"               '[ -f public/404.html ]'
check "netlify form present"     'grep -q "data-netlify=\"true\"" public/index.html'
check "form-name hidden input"   'grep -q "name=\"form-name\" value=\"contato\"" public/index.html'
check "lang pt-br home"          'grep -q "<html lang=\"pt-br\"" public/index.html'
check "lang pt-br 404"           'grep -q "<html lang=\"pt-br\"" public/404.html'
check "4 service cards"          '[ "$(grep -c "service-card" public/index.html)" -ge 4 ]'
check "4 case cards"             '[ "$(grep -c "case-card" public/index.html)" -eq 4 ]'
check "allowed client names"     'grep -qF "Tríade Patologia Veterinária" public/index.html && grep -qF "Clínica Marcela Monnerat" public/index.html && grep -qF "Hidrocenter" public/index.html && grep -qF "Donna Laser" public/index.html'
check "no forbidden names"       '! grep -rqiE "\b(sanploy|misv|bps4|ultraimagem|beatriz|donnalaser)\b" public/'
check "no bare LEC token"        '! grep -rqE "\bLEC\b" public/'

exit $fail
```

Run:

```bash
bash /tmp/audit.sh; echo "audit exit=$?"
```

Expected: every line starts `ok  `, `audit exit=0`.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "Add netlify.toml, minify config, and full output audit"
```

---

## Task 11: Visual design pass (frontend-design skill)

**Files:**
- Modify: `assets/css/main.css` (replace the skeleton with the full system; keep every class name already in use)
- Modify: `layouts/partials/head.html` (only if the font selection changes)

**Interfaces:**
- Consumes: every CSS class produced by Tasks 2–9 (`.container`, `.site-header`, `.nav-inner`, `.brand`, `.nav-toggle`, `.nav-toggle-bar`, `.nav-menu`, `.nav-menu.is-open`, `.hero`, `.eyebrow`, `.hero-lead`, `.btn`, `.btn-primary`, `.section`, `.section-alt`, `.section-dark`, `.section-title`, `.grid`, `.grid-2`, `.card`, `.service-card`, `.case-card`, `.case-setor`, `.cases-outros`, `.contato-info`, `.contato-form`, `.hp-field`, `.social`, `.site-footer`, `.page-narrow`, `.prose`, `.muted`, `.visually-hidden`).
- Produces: the finished stylesheet. No new class names in markup (CSS only). `#contato` renders as the dark section.

- [ ] **Step 1: Invoke the frontend-design skill**

Use `superpowers:frontend-design` (or the `frontend-design` skill) and follow it to set the aesthetic direction. Constraints from spec §4 that must hold:
- Light base (`--bg` near-white, `--fg` near-black), a single accent color used sparingly.
- `#contato` is the one dark section — set `.section-dark` to a dark background with light text and an accent that meets AA on that background; the form inputs inside it must stay legible (either keep white input fields or restyle with sufficient contrast).
- Display face **Fraunces** for `h1`/`h2`/`h3`; text face **Inter** for body. If a different pairing is chosen, update the Google Fonts URL in `head.html` and the `--font-display` / `--font-text` tokens together.
- Content column `max-width` ~1100px; full-bleed section backgrounds for alternation.
- One breakpoint at 720px (already used by the skeleton — keep that value).

- [ ] **Step 2: Rewrite `assets/css/main.css` as the full system**

Build, in this order, inside the file:
1. `:root` tokens — color, type scale (`--step--1` … `--step-5` via `clamp()`), spacing scale, radius, `--font-display`, `--font-text`.
2. Dark-section token overrides scoped to `.section-dark`.
3. Reset (`box-sizing`, `margin` zeroing, `img`, `:focus-visible`, `prefers-reduced-motion`).
4. Base elements — `body`, headings, links, `p`.
5. Layout — `.container`, `.section` rhythm, `.section-alt`, `.section-dark`, `.grid`, `.grid-2`, `.page-narrow`, `.prose`.
6. Components — `.site-header` + nav (desktop + the `@media (max-width:720px)` drawer), `.hero`, `.btn` / `.btn-primary` (with `:hover` / `:active`), `.card` / `.service-card` / `.case-card` / `.case-setor` / `.cases-outros`, `.contato-form` controls, `.social`, `.site-footer`.
7. Motion — section entry fade/rise behind `@media (prefers-reduced-motion: no-preference)`, using `animation-timeline: view()` with `@supports (animation-timeline: view())`; no fallback animation when unsupported (content just shows).
8. `.hp-field { position:absolute; left:-9999px; }` and `.visually-hidden` (carry over from skeleton).

Keep the file a single stylesheet. No `@import` except the Google Fonts link already in `head.html` (not in the CSS).

- [ ] **Step 3: Run the build + audit**

```bash
bash /tmp/audit.sh; echo "audit exit=$?"
```

Expected: `audit exit=0` (nothing structural changed; this proves the redesign didn't drop a class or break the pipeline).

- [ ] **Step 4: Manual + Lighthouse checks**

```bash
hugo server --bind 0.0.0.0 --port 1313 &
sleep 2
npx --yes lighthouse http://localhost:1313/ --quiet --chrome-flags="--headless" \
  --only-categories=performance,accessibility,best-practices,seo \
  --output=json --output-path=/tmp/lh.json || echo "run Lighthouse manually / via PageSpeed on the Netlify preview instead"
node -e "const r=require('/tmp/lh.json');for(const k in r.categories)console.log(k, Math.round(r.categories[k].score*100))"
kill %1
```

Expected: performance ≥ 95, accessibility ≥ 95, best-practices ≥ 95, seo ≥ 95. If the local Lighthouse can't run (no Chrome), defer this assertion to Task 12 on the Netlify preview URL via PageSpeed Insights.

Also verify by eye at widths 375 / 720 / 1280:
- no horizontal scroll at any width;
- nav collapses to the drawer at ≤720px;
- `#contato` is visually the dark section;
- with `prefers-reduced-motion: reduce` (DevTools rendering emulation) no section animates;
- keyboard focus ring visible on every link, button, and form field.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "Full visual design pass for the rebuilt landing page"
```

---

## Task 12: Netlify deploy-preview verification, then merge

**Files:** none.

**Interfaces:**
- Consumes: the finished branch.
- Produces: a verified production deploy.

- [ ] **Step 1: Push the branch and open a deploy preview**

```bash
git push -u origin HEAD
```

In the Netlify dashboard (site `modest-leakey-087549`), confirm a **Deploy Preview** builds from the branch/PR. Confirm the build log shows `hugo --gc --minify` and Hugo `0.128.0`.

- [ ] **Step 2: Confirm the form is detected**

In Netlify → the deploy preview → **Forms**: the `contato` form appears. If it does not, add `static/forms.html` containing a plain-HTML copy of the form (same field names, `name="contato"`, hidden `form-name`), redeploy, and recheck (spec §3.4).

- [ ] **Step 3: Submit a live test message on the preview URL**

Fill and submit the form on the preview site. Expected: redirect to `/obrigado/` showing "Mensagem enviada"; the submission appears under Netlify → Forms → contato within a minute.

- [ ] **Step 4: Configure the email notification**

Netlify → Forms → Settings & notifications → add an outgoing email notification to `contato@quiploy.com`. Submit once more; confirm the email arrives.

- [ ] **Step 5: Run PageSpeed Insights on the preview URL**

Run <https://pagespeed.web.dev/> against the deploy-preview URL (mobile + desktop). Expected: Performance, Accessibility, Best Practices, SEO all ≥ 95. Fix regressions in `assets/css/main.css` / `layouts/` and redeploy before merging.

- [ ] **Step 6: Merge**

Merge the branch to `master`. Netlify builds and publishes production.

- [ ] **Step 7: Post-deploy production checks**

```bash
curl -sI https://www.quiploy.com/ | grep -i 'server\|x-nf-request-id'
curl -s https://www.quiploy.com/ | grep -c 'case-card'          # expect 4
curl -s https://www.quiploy.com/obrigado/ | grep -c 'Recebemos' # expect 1
curl -sI https://www.quiploy.com/naoexiste | head -1            # expect 404
```

Submit the production form once; confirm it lands in Netlify → Forms and the email fires. Open the site in a browser: no console errors, nav/anchors/animation behave, `#contato` is dark.

- [ ] **Step 8: Final commit (docs)**

Update `CLAUDE.md` to drop the "Knight theme / Bootstrap 3 / jQuery / GTM / Heroku contact form" description and replace it with: custom Hugo theme in `layouts/` + `assets/` + `data/`, plain CSS, vanilla JS, Netlify Forms, no analytics.

```bash
git add CLAUDE.md
git commit -m "Update CLAUDE.md for the rebuilt site"
git push
```

---

## Self-Review

**Spec coverage:**

| Spec section | Covered by |
|---|---|
| §2 Approach (Hugo, no framework, one CSS, minimal JS) | Tasks 1–3, 11 |
| §3.1 File layout / deletions | Tasks 1 (theme + images), 2, 5, 7, 8 |
| §3.2 Rendering (`hugo --gc --minify`, fingerprint+SRI, fonts, inline SVG icons) | Tasks 2, 10 — *icons: see gap note* |
| §3.3 Content model (`servicos.yaml`, `cases.yaml` shapes + verbatim copy) | Tasks 5, 7 |
| §3.4 Netlify Forms (attrs, honeypot, `/obrigado/`, dashboard notify, forms.html fallback) | Tasks 8, 12 |
| §3.5 Analytics removed | Tasks 1, 10 (audit) |
| §3.6 `netlify.toml` (build, HUGO_VERSION, headers) | Task 10 |
| §4 Visual direction (light base, one accent, one dark section, CSS motion, 720px, a11y) | Task 11 |
| §5 Components table | Tasks 2–9 (one partial per task) |
| §6 Verification (build clean, output assertions, Lighthouse, responsive, reduced-motion) | per-task checks + Tasks 10–12 |
| §7 Migration/deploy steps | Task 12 |
| §8 Open questions | Hugo pin → Task 10 Step 1 / Task 12 Step 1; logo reuse → Task 1; fonts → Task 2 + Task 11; dark section → Task 11; `/obrigado/` → Task 8 |
| §9 Security note (GH token) | Out of scope by the spec's own statement; not a plan task. |

**Gap found and closed:** spec §3.2 says section icons are "inline SVG in the partials (4–6 small glyphs)". The service/case partials above render without icons to keep tasks small. **Decision:** icons are optional decoration, not required content; if wanted, they are added during Task 11 (design) as inline `<svg>` inside `servicos.html` — the design pass owns whether they earn their place. This is noted here so it isn't treated as a missing requirement. No separate task.

**Placeholder scan:** no "TBD"/"handle appropriately"/"similar to Task N". Every code step has literal file content. The one deliberate deferral (icons) is explained above. The "founding year" is deliberately absent with an explicit instruction not to invent one (Task 6).

**Type / name consistency:** CSS class names produced by Tasks 2–9 are listed verbatim in Task 11's "Consumes" block and match the markup. Data shapes (`{title, description}` for servicos; `{cliente, setor, resumo}` + string list for cases) match between the YAML (Steps 1) and the partials (Steps 2) and the range expressions. `#topo` (hero id) matches the brand link `href="#topo"` in nav. `/obrigado/` matches the form `action`, the `content/obrigado.md` route, and the audit checks. `form-name` value `contato` matches the form `name`. Menu anchors (`#servicos`, `#cases`, `#sobre`, `#contato`) match the section ids created in Tasks 5/7/6/8.

---

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-09-06-quiploy-rebuild.md`. Two execution options:**

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration.

**2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints for review.

**Which approach?**
