#!/usr/bin/env bash
# Post-build assertion checks for the Quiploy site.
# Audits an EXISTING public/ tree — it does NOT run hugo or delete anything.
# Netlify runs `hugo --gc --minify` first, then this script.
set -u

fail=0
check() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }

check "public/index.html exists"        '[ -f public/index.html ]'
check "public/obrigado/index.html exists" '[ -f public/obrigado/index.html ]'
check "public/404.html exists"          '[ -f public/404.html ]'

check "no google analytics"             '! grep -rqiE "googletagmanager|gtag\(|UA-118263902" public/'
check "no jquery/bootstrap/etc"         '! grep -rqiE "jquery|bootstrap|wow\.js|isotope|classie|scrolltofixed|fontawesome|font-awesome" public/'

check "css fingerprinted + SRI"         'grep -Eq "href=\"/css/main\.min\.[0-9a-f]+\.css\"[^>]*integrity=\"sha512-" public/index.html'
check "js fingerprinted + SRI"          'grep -Eq "src=\"/js/site\.min\.[0-9a-f]+\.js\"[^>]*integrity=\"sha512-" public/index.html'

check "netlify form present"            'grep -q "data-netlify=\"true\"" public/index.html'
check "form-name hidden input"          'grep -q "name=\"form-name\" value=\"contato\"" public/index.html'

check "lang pt-br home"                 'grep -q "<html lang=\"pt-br\"" public/index.html'
check "lang pt-br 404"                  'grep -q "<html lang=\"pt-br\"" public/404.html'

check "at least 4 service cards"        '[ "$(grep -o "service-card" public/index.html | wc -l)" -ge 4 ]'
check "exactly 4 case cards"            '[ "$(grep -o "case-card" public/index.html | wc -l)" -eq 4 ]'

check "allowed client names present"    'grep -qF "Tríade Patologia Veterinária" public/index.html && grep -qF "Clínica Marcela Monnerat" public/index.html && grep -qF "Hidrocenter" public/index.html && grep -qF "Donna Laser" public/index.html'

check "no forbidden names"              '! grep -rqiE "sanploy|misv|bps4|ultraimagem|beatriz|donnalaser" public/'
check "no bare LEC token"               '! grep -rqE "\bLEC\b" public/'

exit $fail
