# CLAUDE.md

## Project Overview

Quiploy.com is a single-page landing website for a software development services company. Built with Hugo static site generator using the Knight Bootstrap theme (from BootstrapMade). Content is in Portuguese (pt-BR).

## Tech Stack

- **Static site generator:** Hugo (min v0.36)
- **CSS framework:** Bootstrap 3
- **JavaScript:** jQuery 1.8.3, WOW.js (scroll animations), Isotope (grid layout), jQuery Easing
- **Animations:** Animate.css + WOW.js for scroll-triggered effects
- **Icons:** Font Awesome
- **Fonts:** Google Fonts (Montserrat, Open Sans)
- **Contact form backend:** Heroku app (XHR POST with CORS)
- **Analytics:** Google Tag Manager (UA-118263902-1)

## Project Structure

```
quiploy.com/
├── config.toml              # Hugo config (baseURL, title, theme)
├── content/                 # Hugo content (empty - all content in templates)
└── themes/Knight/
    ├── layouts/
    │   ├── index.html       # Main single-page template (all site content)
    │   ├── 404.html         # Error page
    │   └── _default/        # Default layouts (unused)
    ├── static/
    │   ├── css/             # Bootstrap, Animate.css, custom styles
    │   ├── js/              # jQuery, plugins, contact form handler
    │   ├── fonts/           # Font Awesome font files
    │   └── img/             # Favicons, mockups, backgrounds, logos
    └── theme.toml           # Theme metadata
```

## Build & Development

No package.json or build tooling. Hugo is the only build tool.

```bash
# Local development server
hugo serve

# Production build (outputs to /public)
hugo
```

## Key Files

- `config.toml` - Hugo site configuration (baseURL: https://www.quiploy.com)
- `themes/Knight/layouts/index.html` - The entire site content and layout (340 lines)
- `themes/Knight/static/css/style.css` - Custom theme styles
- `themes/Knight/static/css/responsive.css` - Media query breakpoints
- `themes/Knight/static/js/send_contact_form.js` - Contact form submission logic

## Architecture Notes

- All page content is hardcoded in `index.html` template (no separate content files)
- Navigation uses anchor links (#service, #contact) with smooth scroll
- Responsive breakpoints: desktop (992px+), tablet (768-991px), mobile (<767px)
- Contact form uses base64-encoded backend URL decoded at runtime via `atob()`
- No testing framework, linting, or CI/CD configured
