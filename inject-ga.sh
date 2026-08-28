#!/usr/bin/env bash
set -euo pipefail

GA_ID="G-KTKGBI3SF7"
MARKER="driveq-ga4"

read -r -d '' GA_SNIPPET <<EOF || true
<!-- ${MARKER} -->
<script async src="https://www.googletagmanager.com/gtag/js?id=${GA_ID}"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', '${GA_ID}');
  document.addEventListener('click', function(e) {
    const link = e.target.closest('a');
    if (!link) return;
    const href = link.getAttribute('href') || '';
    if (href.indexOf('tel:') === 0) gtag('event', 'phone_click', {event_category: 'engagement', event_label: href});
    if (href.indexOf('wa.me/') !== -1) gtag('event', 'whatsapp_click', {event_category: 'engagement', event_label: href});
  });
</script>
EOF

while IFS= read -r -d '' file; do
  # Do not inject a second GA tag into pages that already contain one.
  if grep -q "${MARKER}" "$file" || grep -q "gtag('config', '${GA_ID}')" "$file"; then
    continue
  fi
  python3 - "$file" "$GA_SNIPPET" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
snippet = sys.argv[2]
text = path.read_text(encoding='utf-8')
needle = '</head>'
if needle in text:
    text = text.replace(needle, snippet + needle, 1)
    path.write_text(text, encoding='utf-8')
PY
done < <(find . -type f -name '*.html' -not -path './.git/*' -print0)

echo "DriveQ GA4 injected: ${GA_ID}"
