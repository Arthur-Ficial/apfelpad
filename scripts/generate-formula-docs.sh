#!/bin/bash
# Regenerate the bounded formula catalogue sections in README.md and
# docs/formulas.md from `FormulaRegistry.all`.
#
# This is the SSOT generator described in issue #4 — the catalogue in
# Swift is authoritative; this script writes the markdown that mirrors
# it. Running twice produces no diff (idempotent), guaranteed by
# `FormulaCatalogueGeneratorTests.idempotent`.
#
# After running, re-run `swift test --filter FormulaCatalogueGeneratorTests`
# without the env var — it must pass on the freshly written files.

set -euo pipefail

cd "$(dirname "$0")/.."

echo "→ regenerating README.md + docs/formulas.md from FormulaRegistry"
APFELPAD_REGENERATE=1 swift test --filter FormulaCatalogueGeneratorTests > /dev/null

echo "→ verifying generated content matches FormulaRegistry (no env var)"
swift test --filter FormulaCatalogueGeneratorTests > /dev/null

echo "✔ formula docs regenerated and verified"
