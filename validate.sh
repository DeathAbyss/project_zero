#!/usr/bin/env bash
# validate.sh — smoke test pós-setup. Roda na raiz do projeto destino.
#
# Confere: estrutura mínima de arquivos, hook registrado, catálogo
# populado, .gitignore com defaults sensatos.
#
# Uso: bash validate.sh
# Exit code: 0 = tudo OK; != 0 = pelo menos um check falhou.
#
# Windows: rodar via Git Bash.

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
echo
echo "[Estrutura básica]"
check "docs/CONVENTIONS.md existe" \
  "test -f docs/CONVENTIONS.md"
check "docs/project_map/README.md existe" \
  "test -f docs/project_map/README.md"
check "docs/project_map/_GUIDE.md existe" \
  "test -f docs/project_map/_GUIDE.md"
check "SECURITY_NOTES.md existe" \
  "test -f SECURITY_NOTES.md"
check "docs/GLOSSARY.md existe" \
  "test -f docs/GLOSSARY.md"

echo
echo "[Arquivo de instruções do agente]"
warn "Algum arquivo de instruções existe (CLAUDE.md / .cursorrules / etc.)" \
  "test -f CLAUDE.md || test -f .cursorrules || test -d .cursor/rules || test -f .clinerules || test -f .windsurfrules || test -f CONVENTIONS.md || test -f .github/copilot-instructions.md || test -f AGENTS.md"

echo
echo "[Claude Code (skip silencioso se não usa)]"
if [[ -d .claude ]]; then
  check ".claude/settings.json existe" \
    "test -f .claude/settings.json"
  check ".claude/settings.json tem hook PostToolUse" \
    "grep -q PostToolUse .claude/settings.json"
  check ".claude/hooks/check-sync-project-map.sh existe" \
    "test -f .claude/hooks/check-sync-project-map.sh"
  warn ".claude/hooks/check-session-lock.sh existe (opcional, pra sessões paralelas)" \
    "test -f .claude/hooks/check-session-lock.sh"
  warn ".claude/hooks/on-stop-check.sh existe (lembrete de fechamento)" \
    "test -f .claude/hooks/on-stop-check.sh"
  check ".claude/settings.json tem hook Stop registrado" \
    "grep -q '\"Stop\"' .claude/settings.json"
  check ".claude/skills/ tem pelo menos 1 SKILL.md" \
    "ls .claude/skills/*/SKILL.md 2>/dev/null"
  warn ".claude/agents/ existe (multiagente ativo)" \
    "test -d .claude/agents"
else
  echo "  · .claude/ ausente — provavelmente outro agente (Cursor/Cline/Aider/etc.). Skip."
fi

echo
echo "[.gitignore]"
check ".gitignore existe" \
  "test -f .gitignore"
check ".gitignore cobre .env" \
  "grep -Eq '^\\.env' .gitignore"
warn ".gitignore cobre .claude/tmp/ (necessário pra fallback de briefing)" \
  "grep -q '\\.claude/tmp/' .gitignore"
warn ".gitignore cobre node_modules/ (skip se não JS)" \
  "grep -q 'node_modules' .gitignore"

echo
echo "[Catálogo project_map populado]"
warn "Pelo menos 1 doc em docs/project_map/ além do README/GUIDE" \
  "[[ \$(ls docs/project_map/*.md 2>/dev/null | grep -Ev '(README|_GUIDE)\\.md\$' | wc -l) -gt 0 ]]"
warn "Hook tem regras populadas (não só comentário)" \
  "grep -Eq '^[[:space:]]*\\[/' .claude/hooks/check-sync-project-map.sh"

echo
echo "═══════════════════════════════════════════════════════"
echo " Resultado: $PASS OK, $WARN warnings, $FAIL falhas"
echo "═══════════════════════════════════════════════════════"

if [[ $FAIL -gt 0 ]]; then
  echo
  echo "Há falhas. Reveja os passos 5 e 6 do project_zero/README.md."
  exit 1
fi

if [[ $WARN -gt 0 ]]; then
  echo
  echo "Há warnings — provavelmente projeto ainda não mapeado ou catálogo vazio."
  echo "Se for projeto novo e o mapeamento ainda não foi feito (Passo 6),"
  echo "isso é esperado por pouco tempo. Senão, vale popular."
fi

exit 0
