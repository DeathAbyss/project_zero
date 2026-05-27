#!/usr/bin/env bash
# setup-project.sh — instala no PROJETO o que falta pro fluxo do
# project_zero rodar, assumindo que a camada reutilizável já está no
# global (~/.claude/, via setup-global.sh).
#
# Instala só o SCAFFOLDING DE ESTADO per-projeto:
#   - .claude/changes/ (templates + archive)  → fluxo SDD
#   - .claude/harness.config                   → jurisdição do gate
#   - .claude/docs/project_map/ (README + guia) → GPS do código
#   - .claude/docs/GLOSSARY.md                  → vocabulário do projeto
#   - .claude/SESSION_LOCK.md                   → sessões paralelas
#   - .gitignore: linha .claude/tmp/
#
# NÃO instala agents/skills/hooks/docs-doutrina — isso vive no global.
# NÃO gera CLAUDE.md (tem placeholder; o agente preenche — ou use setup.sh).
# NÃO sobrescreve nada que já exista (copy_if_absent).
#
# Uso:
#   bash project_zero/setup-project.sh           # aplica no diretório atual
#   bash project_zero/setup-project.sh <destino> # aplica em <destino>

set -euo pipefail
shopt -s nullglob

PROJECT_ZERO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$PROJECT_ZERO/.claude"

DEST_IN="${1:-$(pwd)}"
mkdir -p "$DEST_IN"
DEST="$(cd "$DEST_IN" && pwd)"
NS=".claude"
DST="$DEST/$NS"

if [[ "$DEST" == "$PROJECT_ZERO" ]]; then
  echo "Erro: destino é o próprio project_zero. Rode em outro repo." >&2
  exit 1
fi

copy_if_absent() {
  local src="$1" dst="$2"
  if [[ -e "$dst" ]]; then
    echo "  · skip (já existe): ${dst#$DEST/}"
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "  + ${dst#$DEST/}"
  fi
}

echo "project_zero → scaffolding de PROJETO em: $DST"
echo "(pré-requisito: camada global instalada via setup-global.sh)"
echo

# ── SDD: changes/ ──────────────────────────────────────────────────────
echo "[1/4] SDD (changes/)..."
copy_if_absent "$SRC/changes/README.md" "$DST/changes/README.md"
for tmpl in "$SRC/changes/_templates/"*.md; do
  copy_if_absent "$tmpl" "$DST/changes/_templates/$(basename "$tmpl")"
done
mkdir -p "$DST/changes/archive"
[[ -e "$DST/changes/archive/.gitkeep" ]] || { touch "$DST/changes/archive/.gitkeep"; echo "  + changes/archive/.gitkeep"; }

# ── Harness config ─────────────────────────────────────────────────────
echo
echo "[2/4] harness.config..."
copy_if_absent "$SRC/harness.config.template" "$DST/harness.config"
echo "    (edite data_protection: [LGPD|GDPR|...] conforme o projeto)"

# ── Docs per-projeto (project_map + GLOSSARY + SESSION_LOCK) ────────────
echo
echo "[3/4] Docs per-projeto..."
copy_if_absent "$SRC/docs/project_map/README.template.md" "$DST/docs/project_map/README.md"
copy_if_absent "$SRC/docs/project_map/_GUIDE.md"          "$DST/docs/project_map/_GUIDE.md"
copy_if_absent "$SRC/docs/GLOSSARY.md"                    "$DST/docs/GLOSSARY.md"
copy_if_absent "$SRC/SESSION_LOCK.template.md"            "$DST/SESSION_LOCK.md"

# ── .gitignore: .claude/tmp/ ───────────────────────────────────────────
echo
echo "[4/4] .gitignore..."
GI="$DEST/.gitignore"
LINE=".claude/tmp/"
if [[ -f "$GI" ]] && grep -Fxq "$LINE" "$GI"; then
  echo "  · .gitignore já ignora $LINE"
else
  echo "$LINE" >> "$GI"
  echo "  + $LINE → .gitignore"
fi

echo
echo "═══════════════════════════════════════════════════════"
echo " Projeto pronto: $DST"
echo "═══════════════════════════════════════════════════════"
echo "Falta (manual): CLAUDE.md do projeto — gere de project_zero/CLAUDE.template.md"
echo "  preenchendo placeholders, ou rode o setup.sh completo."
echo "Começa o fluxo:  \"explora a ideia X\" (sdd-explore)  ou  \"propõe a change Y\""
