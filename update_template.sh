#!/usr/bin/env bash
# update_template.sh — compara o project_zero com o estado do destino
# e mostra arquivos que diferem. NÃO aplica mudanças automaticamente.
#
# O usuário decide o que mesclar usando diff/merge tool de escolha.
#
# Uso:  bash project_zero/update_template.sh [destino]
# Default destino = cwd.
#
# Windows: rodar via Git Bash.

set -e

PROJECT_ZERO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${1:-$(pwd)}"

if [[ "$PROJECT_ZERO" == "$DEST" ]]; then
  echo "ERRO: destino é o próprio project_zero. Aborta."
  exit 1
fi

# Arquivos do template que valem comparar (skip de placeholders).
# Assume destino usando namespace .claude/. Pra outros agentes, paths
# divergem e o script reportaria falsos faltantes — futuro: aceitar --agent.
FILES=(
  ".claude/docs/SECURITY_NOTES.md"
  ".claude/docs/CONVENTIONS.md"
  ".claude/docs/GLOSSARY.md"
  ".claude/docs/01-git.md"
  ".claude/docs/02-token-efficiency.md"
  ".claude/docs/03-multiagent.md"
  ".claude/docs/04-task-closure.md"
  ".claude/docs/decisions/README.md"
  ".claude/docs/decisions/_TEMPLATE.md"
  ".claude/docs/project_map/_GUIDE.md"
  ".claude/skills/roadmap-review/SKILL.md"
  ".claude/skills/dry-pass/SKILL.md"
  ".claude/skills/polish/SKILL.md"
  ".claude/skills/sync-project-map/SKILL.md"
  ".claude/skills/code-review-and-quality/SKILL.md"
  ".claude/skills/deprecation-and-migration/SKILL.md"
  ".claude/skills/browser-testing-with-devtools/SKILL.md"
  ".claude/skills/task-retrospect/SKILL.md"
  ".claude/skills/cost-report/SKILL.md"
  ".claude/skills/switch-agent-profile/SKILL.md"
  ".claude/agents/operador.md"
  ".claude/agents/dev.md"
  ".claude/agents/analista.md"
  ".claude/agents/escriba.md"
  ".claude/hooks/check-sync-project-map.sh"
  ".claude/hooks/check-session-lock.sh"
  ".claude/hooks/on-stop-check.sh"
  ".claude/scripts/validate.sh"
  ".claude/scripts/cost-report.py"
)
# Nota: setup.sh e update_template.sh NÃO entram aqui — são tooling
# do project_zero source, não vão pro destino.

DIFFERS=()
MISSING=()
SAME_COUNT=0

for f in "${FILES[@]}"; do
  SRC="$PROJECT_ZERO/$f"
  DST="$DEST/$f"

  [[ ! -f "$SRC" ]] && continue

  if [[ ! -f "$DST" ]]; then
    MISSING+=("$f")
  elif ! diff -q "$SRC" "$DST" > /dev/null 2>&1; then
    DIFFERS+=("$f")
  else
    SAME_COUNT=$((SAME_COUNT+1))
  fi
done

echo "═══════════════════════════════════════════════════════"
echo " update_template — diff project_zero ↔ destino"
echo "═══════════════════════════════════════════════════════"
echo "Template: $PROJECT_ZERO"
echo "Destino:  $DEST"
echo
echo "Em sync:    $SAME_COUNT arquivos"
echo "Diferentes: ${#DIFFERS[@]} arquivos"
echo "Faltando:   ${#MISSING[@]} arquivos"
echo

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "═══ Faltando no destino ═══"
  for f in "${MISSING[@]}"; do
    echo "  $f"
  done
  echo
  echo "Pra copiar individualmente:"
  echo "  cp \"$PROJECT_ZERO/<arquivo>\" \"$DEST/<arquivo>\""
  echo
fi

if [[ ${#DIFFERS[@]} -gt 0 ]]; then
  echo "═══ Diferentes (template tem versão diferente do destino) ═══"
  for f in "${DIFFERS[@]}"; do
    echo "  $f"
  done
  echo
  echo "Pra ver o diff de um arquivo:"
  echo "  diff \"$PROJECT_ZERO/<arquivo>\" \"$DEST/<arquivo>\""
  echo
  echo "Pra aplicar a versão do template (CUIDADO — sobrescreve):"
  echo "  cp \"$PROJECT_ZERO/<arquivo>\" \"$DEST/<arquivo>\""
  echo
  echo "AVISO: arquivos personalizados no destino (ex.: hook com RULES"
  echo "populadas, agent com regras do projeto) NÃO devem ser"
  echo "sobrescritos cegamente. Reveja o diff antes de aplicar."
fi

[[ ${#DIFFERS[@]} -eq 0 && ${#MISSING[@]} -eq 0 ]] && echo "Tudo em sync."

exit 0
