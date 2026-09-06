# Quiploy.com — Rebuild Design

**Date:** 2026-09-06
**Status:** Draft for review
**Author:** Gabriel Monnerat + Claude

## 1. Goal

Rebuild the quiploy.com single-page landing site. Two drivers:

- **Redesign the look** — replace the dated BootstrapMade "Knight" template with a clean, intentional, typographic design that does not read as a template.
- **Rewrite the content** — replace placeholder-quality copy with real positioning and real client cases, in Portuguese (pt-BR).

Non-goals: multi-page site, blog, CMS, i18n/English version, redesign of any client product.

## 2. Approach

Stay on **Hugo**, delete the `themes/Knight/` theme entirely, build a small custom theme in the project root (`layouts/`, `assets/`, `data/`). No CSS framework, no jQuery, no WOW.js, no Isotope. One hand-authored stylesheet using CSS custom properties, flexbox/grid. JavaScript limited to a single small vanilla script (mobile nav toggle + anchor smooth-scroll); the page is fully functional with JS disabled.

Rationale: Hugo is already the deploy pipeline on Netlify and the team knows it. The value was never in the theme — it was 340 lines of template glue around a single page. A custom theme at ~5 partials is smaller and fully owned. Astro / a rewrite to plain HTML were considered and rejected: Astro adds a Node toolchain for no gain on a 5-section static page; plain HTML loses the `data/*.yaml` content separation that makes cases editable without touching markup.

## 3. Architecture

### 3.1 File layout (after rebuild)

```
config.toml                     # baseURL, title, [params], [menus]
netlify.toml                    # [build] command = "hugo --gc --minify", publish = "public"
archetypes/                     # (removed — no content files)
content/                        # stays effectively empty (.gitkeep)
data/
  servicos.yaml                 # service cards (title, icon, description)
  cases.yaml                    # named cases + anonymized cases
layouts/
  index.html                    # <head> + composes section partials
  404.html                      # simple styled 404
  partials/
    head.html                   # meta, favicons, fonts, CSS link (fingerprinted)
    nav.html                    # sticky top nav
    hero.html
    servicos.html
    sobre.html
    cases.html
    contato.html                # Netlify Forms markup
    footer.html
assets/
  css/main.css                  # the whole stylesheet
  js/site.js                    # ~15 lines: nav toggle, smooth scroll
static/
  img/                          # favicons (kept), logo(s) (kept)
  robots.txt                    # kept
  # forms.html                  # NOT added unless a deploy shows the form undetected (see 3.4)
```

Files deleted: `themes/Knight/` (whole directory), all mockup/stock images
(`macbook*.png`, `iphone.png`, `iPad.png`, `imac.png`, `section-bg*.jpg`,
`bg-map.png`, `team-leader-pic*.jpg`, `client-pic1.jpg`, `wp.png`,
`pw_maze*`, `glyphicons-*`, `list-style.png`, `res_nav_click.png`),
`send_contact_form.js`, jQuery / bootstrap / wow / isotope / classie /
scrolltofixed / easing / respond / html5shiv JS, `animate.css`,
`bootstrap.css`, `font-awesome*.css`, Font Awesome font files.

Favicons under `static/img/` are kept as-is (the `apple-icon-*`,
`android-icon-*`, `favicon-*`, `ms-icon-*` set). `logo.png`,
`small-logo.png`, `footer-logo.png` kept pending a decision on whether the
logo art is redrawn (out of scope — reuse existing).

### 3.2 Rendering

- `hugo --gc --minify` produces `public/`. Single page at `/`, plus `/404.html`.
- CSS: `resources.Get "css/main.css" | minify | fingerprint`, linked with SRI. No inlining (one small file, HTTP/2, Netlify edge cache).
- JS: `resources.Get "js/site.js" | minify | fingerprint`, `defer`.
- Fonts: two families from Google Fonts (a display face + a text face — final choice made during build with the frontend-design skill), loaded with `preconnect` + `display=swap` and a real system fallback stack. No Font Awesome — icons are inline SVG in the partials (4–6 small glyphs total).

### 3.3 Content model

`data/servicos.yaml` — list of `{ title, description }` (icon key optional, maps to an inline SVG in the partial).

`data/cases.yaml` — two lists:

```yaml
destaque:            # named, with client permission
  - cliente: "Tríade Patologia Veterinária"
    setor: "Laboratório de patologia veterinária"
    resumo: "Sistema de gestão de laboratório: cadastro de clientes e animais,
             requisições de 8 tipos de exame com numeração sequencial anual,
             laudos em PDF com assinatura digital e fotomicrografias, e
             dashboards de produtividade (exames por tipo, técnico e período)."
  - cliente: "Clínica Marcela Monnerat"
    setor: "Clínica médica/estética"
    resumo: "Plataforma de gestão clínica: prontuário, evoluções e prescrições,
             agenda, pagamentos, recebíveis e comissões, controle de estoque,
             emissão de NFS-e Nacional e comunicação com pacientes via WhatsApp."
  - cliente: "Hidrocenter"
    setor: "Materiais hidráulicos e construção civil"
    resumo: "Gestão de propostas comerciais, obras em andamento com controle
             financeiro (notas, serviços, instaladores, saldo da obra),
             almoxarifado com movimentações e custo médio, e controle de acesso
             por perfil com isolamento de dados por vendedor."
  - cliente: "Donna Laser"
    setor: "Locação de equipamentos a laser"
    resumo: "Gestão de locação: contratos com dezenas de modelos, agenda de
             equipamentos com arrastar-e-soltar, pagamentos parcelados,
             controle de despesas e entregas, e assinatura de contrato por
             link com token."
outros:              # anonymized, no client name
  - "Automação fiscal e contábil para escritório de contabilidade —
     importação de NF-e, cálculo de créditos PIS/COFINS e consolidação
     do razão contábil de três ERPs (Datasul, Protheus, Domínio)."
  - "Recuperação e migração de sistema hospitalar legado — ambiente
     restaurado, base de mais de 3 mil registros migrada e validada,
     seguida de manutenção mensal com SLA."
  - "Sistema de gestão financeira para organizações religiosas —
     membros, contribuições, despesas e balanços mensais e anuais."
```

Copy in this spec is a first draft; final wording tuned during build.

### 3.4 Contact form — Netlify Forms

- `<form name="contato" method="POST" data-netlify="true" netlify-honeypot="bot-field">`.
- Hidden `<input type="hidden" name="form-name" value="contato">` and a hidden
  `bot-field` honeypot wrapped in a visually-hidden label.
- Fields: `nome` (text, required), `email` (email, required), `assunto` (text),
  `mensagem` (textarea, required). Native HTML5 validation only.
- `action="/obrigado"` → a success partial/section, OR a small `#sucesso`
  anchor state. Decision: use a dedicated section `#contato` that swaps to a
  thank-you message via Netlify's default redirect to `/` with `?success` is
  brittle; instead render a static `layouts/obrigado.html` → `/obrigado/`
  page with "Mensagem enviada" and a link back. Simplest reliable option.
- Netlify detects forms by parsing deployed HTML at build time. Because our
  form markup is rendered by Hugo (not static), it IS in the built HTML, so
  detection works without the `static/forms.html` dummy. Keep `forms.html`
  out unless a deploy shows the form undetected.
- Email notification configured in the Netlify dashboard (to
  contato@quiploy.com). Not in repo.
- Spam: honeypot + Netlify's built-in filtering. No reCAPTCHA.

### 3.5 Analytics

Removed entirely. No GTM, no GA, no Universal Analytics `UA-118263902-1`,
no replacement. `config.toml` analytics params and the `<script>` tags are
deleted.

### 3.6 Netlify config

Add `netlify.toml`:

```toml
[build]
  command = "hugo --gc --minify"
  publish = "public"

[build.environment]
  HUGO_VERSION = "0.128.0"   # pin; confirm against Netlify's available versions

[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-Content-Type-Options = "nosniff"
    Referrer-Policy = "strict-origin-when-cross-origin"

[[headers]]
  for = "/assets/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"
```

The Netlify dashboard currently holds the build settings; `netlify.toml`
takes precedence once merged. Confirm the site's build command/publish dir
in the dashboard match (or will be overridden by) this file before deploy.

## 4. Visual direction

Detailed treatment deferred to the `frontend-design` skill at build time.
Intent to lock now:

- **Layout:** single column, generous vertical rhythm, wide max-width (~1100px)
  content column, full-bleed section backgrounds for alternation.
- **Type:** a strong display face for headings (large, tight), a neutral
  readable text face for body. Portuguese copy, so accented glyph coverage
  required.
- **Color:** light base (near-white background, near-black text), one accent
  color used sparingly (links, CTA, section marker). One dark section
  (hero or contato) for contrast.
- **Motion:** CSS only — a subtle fade/rise on section entry via
  `@media (prefers-reduced-motion: no-preference)` and
  `animation-timeline: view()` where supported, degrading to no animation.
  No scroll libraries.
- **Icons:** inline SVG, single stroke weight, currentColor.
- **Responsive:** one breakpoint around 720px (stack nav, single-column
  cards). Mobile-first CSS.
- **Accessibility:** semantic landmarks, visible focus states, color contrast
  AA, `prefers-reduced-motion` respected, form labels associated.

## 5. Components / units

| Unit | Responsibility | Depends on |
|---|---|---|
| `head.html` | document head, meta, favicon links, font + CSS/JS asset pipeline | `assets/css/main.css`, `assets/js/site.js`, `.Site.Params` |
| `nav.html` | sticky nav, anchor links, mobile toggle target | `.Site.Menus.main` |
| `hero.html` | name, positioning line, primary CTA | `.Site.Params` |
| `servicos.html` | render service cards | `.Site.Data.servicos` |
| `sobre.html` | company description, approach, CNPJ | static copy in partial |
| `cases.html` | named case cards + anonymized list | `.Site.Data.cases` |
| `contato.html` | Netlify form, phone, email, social links | `.Site.Params` |
| `footer.html` | copyright, minimal links | `.Site.Params` |
| `site.js` | nav toggle, smooth scroll | none (vanilla) |
| `main.css` | all styling, custom properties | none |

Each partial is independently readable and renders in isolation given its
data. `config.toml [params]` is the single source for contact details, site
title, and social URLs.

## 6. Testing / verification

No test framework exists and none is added (static marketing page). Verification is manual + build-based:

1. `hugo --gc --minify` builds with zero errors/warnings.
   **Risk:** Hugo is not installed on this dev machine — install (`>= 0.128`)
   or verify via a Netlify deploy preview branch.
2. `public/index.html` contains: the Netlify form with `form-name` hidden
   input; no reference to jQuery/bootstrap/wow/isotope; no `googletagmanager`
   or `UA-` string; fingerprinted CSS/JS URLs.
3. HTML validates (W3C validator) — no unclosed tags, `lang="pt-br"`.
4. Lighthouse on the built page: Performance ≥ 95, Accessibility ≥ 95,
   Best Practices ≥ 95, SEO ≥ 95.
5. Manual: mobile nav toggle works; anchor links scroll; form submits on a
   Netlify deploy preview and the submission appears in the dashboard;
   `/obrigado/` renders; 404 page renders styled.
6. Responsive check at 375px, 720px, 1280px.
7. `prefers-reduced-motion: reduce` disables entry animations.

## 7. Migration / deploy steps

1. Branch. Build the new theme alongside the old (delete `themes/Knight`
   last, or first on the branch — either way the branch is the safety net).
2. Open a Netlify deploy preview from the branch; verify section 6 against
   the preview URL.
3. Submit a test message through the preview form; confirm it lands and
   the email notification fires.
4. Merge to `master`; Netlify builds and publishes production.
5. Post-deploy: confirm `https://www.quiploy.com` and apex both serve the
   new page; confirm form works in production; confirm no console errors.

## 8. Open questions

1. **Hugo version pin** — confirm `HUGO_VERSION` against what Netlify
   currently offers and what's installed locally.
2. ~~Logo~~ — **Decided: reuse existing `logo.png` as-is.**
3. **Fonts** — specific families chosen during the frontend-design pass;
   spec assumes two Google Fonts families.
4. **Dark section placement** — hero vs. contato. Decided during design.
5. ~~`/obrigado/` page vs. inline success state~~ — **Decided: dedicated
   `/obrigado/` page.**

## 9. Security note (unrelated to this work)

During the rebuild, credentials were noticed in local git configuration on
the development machine. Rotate any credentials that are stored outside a
credential manager and re-point the affected remotes. Out of scope for this
rebuild; flagged for follow-up.
