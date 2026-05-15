#!/usr/bin/env bash
# validate.sh — smoke test pós-setup. Vive em <NS>/scripts/validate.sh.
#
# Auto-detecta o namespace olhando onde ele próprio mora (BASH_SOURCE).
# Confere: estrutura mínima de arquivos, hook registrado, catálogo
# populado, .gitignore com defaults sensatos.
#
# Uso: bash <NS>/scripts/validate.sh
# Ex.: bash .claude/scripts/validate.sh
#
# Exit code: 0 = tudo OK; != 0 = pelo menos um check falhou.
#
# Windows: rodar via Git Bash.

# ─── Self-locate ───────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NS_DIR="$(dirname "$SCRIPT_DIR")"
NS="$(basename "$NS_DIR")"            # ex: .claude, .cursor
PROJECT_ROOT="$(dirname "$NS_DIR")"
cd "$PROJECT_ROOT"

PASS=0
FAIL=0
WARN=0

check() {
  local name="$1"
  local cmd="$2"
  if eval "$cmd" > /dev/null 2>&1; then
    echo "  OK   $name"
    PASS=$((PASS+1))
  else
    echo "  FAIL $name"
    FAIL=$((FAIL+1))
  fi
}

warn() {
  local name="$1"
  local cmd="$2"
  if eval "$cmd" > /dev/null 2>&1; then
    echo "  OK   $name"
    PASS=$((PASS+1))
  else
    echo "  WARN $name"
    WARN=$((WARN+1))
  fi
}

echo "═══════════════════════════════════════════════════════"
echo " validate.sh — sanidade do setup"
echo "═══════════════════════════════════════════════════════"
echo " Project root: $PROJECT_ROOT"
echo " Namespace:    $NS"
echo
echo "[Estrutura básica]"
check "$NS/docs/CONVENTIONS.md existe" \
  "test -f $NS/docs/CONVENTIONS.md"
check "$NS/docs/project_map/README.md existe" \
  "test -f $NS/docs/project_map/README.md"
check "$NS/docs/project_map/_GUIDE.md existe" \
  "test -f $NS/docs/project_map/_GUIDE.md"
check "$NS/docs/SECURITY_NOTES.md existe" \
  "test -f $NS/docs/SECURITY_NOTES.md"
check "$NS/docs/GLOSSARY.md existe" \
  "test -f $NS/docs/GLOSSARY.md"

echo
echo "[Arquivo de instruções do agente]"
warn "Algum arquivo de instruções existe (CLAUDE.md / .cursorrules / etc.)" \
  "test -f CLAUDE.md || test -f .cursorrules || test -d .cursor/rules || test -f .clinerules || test -f .windsurfrules || test -f CONVENTIONS.md || test -f .github/copilot-instructions.md || test -f AGENTS.md"

echo
echo "[$NS — features do agente]"
check "$NS/settings.json existe (ou skip se non-Claude)" \
  "[[ '$NS' != '.claude' ]] || test -f $NS/settings.json"
warn "$NS/settings.json tem hook PostToolUse" \
  "[[ '$NS' != '.claude' ]] || grep -q PostToolUse $NS/settings.json"
check "$NS/hooks/check-sync-project-map.sh existe" \
  "test -f $NS/hooks/check-sync-project-map.sh"
warn "$NS/hooks/check-session-lock.sh existe (opcional, pra sessões paralelas)" \
  "test -f $NS/hooks/check-session-lock.sh"
warn "$NS/SESSION_LOCK.md existe sem sufixo .template" \
  "test -f $NS/SESSION_LOCK.md && ! test -f $NS/SESSION_LOCK.template.md"
warn "$NS/hooks/on-stop-check.sh existe (lembrete de fechamento)" \
  "test -f $NS/hooks/on-stop-check.sh"
warn "$NS/settings.json tem hook Stop registrado" \
  "[[ '$NS' != '.claude' ]] || grep -q '\"Stop\"' $NS/settings.json"
check "$NS/skills/ tem pelo menos 1 SKILL.md" \
  "ls $NS/skills/*/SKILL.md 2>/dev/null"
warn "$NS/agents/ existe (multiagente ativo)" \
  "test -d $NS/agents"

echo
echo "[.gitignore]"
check ".gitignore existe" \
  "test -f .gitignore"
check ".gitignore cobre .env" \
  "grep -Eq '^\\.env' .gitignore"
warn ".gitignore cobre $NS/tmp/ (necessário pra fallback de briefing)" \
  "grep -q '$NS/tmp/' .gitignore"
warn ".gitignore cobre node_modules/ (skip se não JS)" \
  "grep -q 'node_modules' .gitignore"

echo
echo "[Catálogo project_map populado]"
warn "Pelo menos 1 doc em $NS/docs/project_map/ além do README/GUIDE" \
  "[[ \$(ls $NS/docs/project_map/*.md 2>/dev/null | grep -Ev '(README|_GUIDE)\\.md\$' | wc -l) -gt 0 ]]"
warn "Hook tem regras populadas (não só comentário)" \
  "grep -Eq '^[[:space:]]*\\[/' $NS/hooks/check-sync-project-map.sh"

echo
echo "═══════════════════════════════════════════════════════"
echo " Resultado: $PASS OK, $WARN warnings, $FAIL falhas"
echo "═══════════════════════════════════════════════════════"

if [[ $FAIL -gt 0 ]]; then
  echo
  echo "Há falhas. Reveja o README do project_zero (etapas de aplicação)."
  exit 1
fi

if [[ $WARN -gt 0 ]]; then
  echo
  echo "Há warnings — provavelmente projeto ainda não mapeado ou catálogo vazio."
  echo "Se for projeto novo e o mapeamento ainda não foi feito, é esperado."
fi

exit 0
