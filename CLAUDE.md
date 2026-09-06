# CLAUDE.md

## Project Overview

Quiploy.com is a single-page marketing site for a software-development
services company (Python/Django). Hugo static site, custom theme, content
in Portuguese (pt-BR). Hosted on Netlify; DNS at GoDaddy.

## Tech Stack

- **Generator:** Hugo (extended) ≥ 0.128 — the only build tool, no npm
- **CSS:** one hand-authored stylesheet, `assets/css/main.css` (CSS custom
  properties, flex/grid, no framework)
- **JS:** `assets/js/site.js` — ~20 lines of vanilla JS, mobile nav toggle
  only; the page works fully with JS disabled
- **Fonts:** Fraunces + Inter, self-hosted from `static/fonts/` via
  `@font-face` in `main.css` (no Google Fonts request)
- **Contact form:** posts to Web3Forms (`https://api.web3forms.com/submit`), no
  backend code. Needs `params.web3forms_key` set in `config.toml` (free key from
  web3forms.com; the build warns if empty). On success Web3Forms redirects to
  `/obrigado/`. Honeypot: hidden `botcheck` checkbox.
- **Analytics:** none

## Project Structure

```
config.toml              # Hugo config: params, main menu, minify (keepQuotes)
netlify.toml             # build command, HUGO_VERSION pin, headers
scripts/audit.sh         # post-build assertion checks (see Verification)
data/
  servicos.yaml          # service cards
  cases.yaml             # cases: `destaque` (named) + `outros` (anonymized)
content/
  obrigado.md            # /obrigado/ thank-you page body
layouts/
  index.html             # home: composes section partials
  404.html               # styled 404
  robots.txt             # robots template (Sitemap line)
  _default/single.html   # layout for /obrigado/
  partials/              # head, nav, hero, servicos, sobre, cases, contato, footer
assets/
  css/main.css           # entire stylesheet (Hugo-fingerprinted + SRI)
  js/site.js             # mobile nav toggle
static/
  img/                   # favicons + logo.png
  fonts/                 # Fraunces + Inter woff2
```

## Build & Development

```bash
hugo server            # local dev at http://localhost:1313
hugo --gc --minify     # production build → public/
bash scripts/audit.sh  # run the assertion checks against public/
```

Netlify runs `hugo --gc --minify && bash scripts/audit.sh`.

## Conventions / Constraints

- All copy is Portuguese (pt-BR); `languageCode = "pt-br"`.
- **Client names on the site:** only `Tríade Patologia Veterinária`,
  `Clínica Marcela Monnerat`, `Hidrocenter`, `Donna Laser` may be named.
  All other client work is described by sector only, never named.
- No jQuery/Bootstrap/analytics — `scripts/audit.sh` fails the build if any
  reappear.
- Service and case copy live in `data/*.yaml`; partials range over them.
- CSS/JS go through Hugo's asset pipeline (minify + fingerprint + SRI).
- One responsive breakpoint at 720px; motion is CSS-only and respects
  `prefers-reduced-motion`.
- Design spec: `docs/superpowers/specs/2026-09-06-quiploy-rebuild-design.md`
- Contact CNPJ 23.612.194/0001-81 · contato@quiploy.com · +55 21 99909-5870

## Known follow-ups

- `logo.png` is a white-on-transparent mark shown via a `filter: brightness(0)`
  workaround in `main.css`; replace with a dark/SVG logo and drop the filter
  (also unblocks an `og:image`).
