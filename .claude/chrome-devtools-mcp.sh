#!/bin/sh
# Lance chrome-devtools-mcp (pilotage de Chrome par Claude).
# - Navigateur invisible, profil temporaire effacé à la fermeture.
# - Aucune statistique d'usage ni URL envoyée à Google.
# - En session cloud, utilise le Chromium préinstallé ; ailleurs, Chrome normal.
set -e
if [ -x /opt/pw-browsers/chromium ]; then
  set -- --executablePath /opt/pw-browsers/chromium --chromeArg=--no-sandbox "$@"
fi
exec npx -y chrome-devtools-mcp@1.12.0 --headless --isolated \
  --usageStatistics=false --performanceCrux=false \
  --screenshotFormat=jpeg --screenshotMaxWidth=1280 "$@"
