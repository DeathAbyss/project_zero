#!/usr/bin/env bash
# setup.sh — aplica o project_zero num projeto destino.
#
# Cobre o trivial do Passo 5 (copia arquivos sem placeholder + mescla
# .gitignore + cria settings.json). Decisões importantes (placeholders
# do CLAUDE.md, mapeamento) ficam pro fluxo interativo com o agente.
#
# REGRA: docs do template vão SEMPRE pra `<NS>/docs/` do destino, onde
# <NS> é o namespace do agente alvo (default `.claude` pra Claude Code).
# Nunca cria `docs/` solto na raiz. `docs/` na raiz do destino é
# território do usuário — script não toca.
#
# Uso:
#   bash project_zero/setup.sh                              # Claude Code, destino = cwd
#   bash project_zero/setup.sh /path/to/dest                # Claude Code, destino explícito
#   bash project_zero/setup.sh --agent cursor /path/to/dest # outro agente
#
# Agentes suportados (mapeamento --agent → namespace):
#   claude (default) → .claude
#   cursor           → .cursor
#   cline            → .cline
#   windsurf         → .windsurf
#   aider            → .aider
#   copilot          → .github/copilot
#   generic          → .ai
#
# Windows: rodar via Git Bash.

set -e

PROJECT_ZERO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Parse args ────────────────────────────────────────────────────
AGENT="claude"
AGENT_EXPLICIT=0
DEST=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent)
      AGENT="$2"
      AGENT_EXPLICIT=1
      shift 2
      ;;
    --agent=*)
      AGENT="${1#--agent=}"
      AGENT_EXPLICIT=1
      shift
      ;;
    -h|--help)
      sed -n '1,30p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      DEST="$1"
      shift
      ;;
  esac
done
DEST="${DEST:-$(pwd)}"

# ─── Auto-detect agente se --agent não foi passado ────────────────
if [[ "$AGENT_EXPLICIT" == "0" ]]; then
  if [[ -f "$DEST/CLAUDE.md" || -d "$DEST/.claude" ]]; then
    AGENT="claude"   # já é o default, mas explicito por clareza
  elif [[ -f "$DEST/.cursorrules" || -d "$DEST/.cursor" ]]; then
    AGENT="cursor"
    echo "  Auto-detect: encontrei .cursorrules / .cursor/ → --agent cursor"
  elif [[ -f "$DEST/.clinerules" ]]; then
    AGENT="cline"
    echo "  Auto-detect: encontrei .clinerules → --agent cline"
  elif [[ -f "$DEST/.windsurfrules" ]]; then
    AGENT="windsurf"
    echo "  Auto-detect: encontrei .windsurfrules → --agent windsurf"
  elif [[ -f "$DEST/.aider.conf.yml" ]]; then
    AGENT="aider"
    echo "  Auto-detect: encontrei .aider.conf.yml → --agent aider"
  elif [[ -f "$DEST/.github/copilot-instructions.md" ]]; then
    AGENT="copilot"
    echo "  Auto-detect: encontrei .github/copilot-instructions.md → --agent copilot"
  elif [[ -f "$DEST/AGENTS.md" ]]; then
    AGENT="generic"
    echo "  Auto-detect: encontrei AGENTS.md → --agent generic"
  fi
  # Senão fica claude (default mais comum)
fi

# ─── Mapeia agente → namespace ────────────────────────────────────
case "$AGENT" in
  claude|claude-code) AI_NS=".claude" ;;
  cursor)             AI_NS=".cursor" ;;
  cline)              AI_NS=".cline" ;;
  windsurf)           AI_NS=".windsurf" ;;
  aider)              AI_NS=".aider" ;;
  copilot)            AI_NS=".github/copilot" ;;
  generic|other|ai)   AI_NS=".ai" ;;
  *)
    echo "ERRO: agente '$AGENT' não reconhecido."
    echo "Suportados: claude (default), cursor, cline, windsurf, aider, copilot, generic"
    exit 1
    ;;
esac

if [[ "$PROJECT_ZERO" == "$DEST" ]]; then
  echo "ERRO: destino é o próprio project_zero. Aborta."
  exit 1
fi

if [[ ! -d "$DEST" ]]; then
  echo "ERRO: destino '$DEST' não existe."
  exit 1
fi

echo "═══════════════════════════════════════════════════════"
echo " project_zero setup"
echo "═══════════════════════════════════════════════════════"
echo "Template:  $PROJECT_ZERO"
echo "Destino:   $DEST"
echo "Agente:    $AGENT"
echo "Namespace: $AI_NS"
echo

# ─── Política de docs ─────────────────────────────────────────────
if [[ -d "$DEST/$AI_NS/docs" ]]; then
  echo "  ✓ $DEST/$AI_NS/docs existe. Arquivos do template que faltarem serão adicionados."
else
  echo "  ✓ $DEST/$AI_NS/docs será criado."
fi

echo
read -p "Confirma setup? [y/N] " confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo "Cancelado."; exit 0; }

copy_if_absent() {
  local src="$1"
  local dst="$2"
  if [[ -e "$dst" ]]; then
    echo "  · skip (já existe): $dst"
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "  + criado: $dst"
  fi
}

echo
echo "[1/6] Copiando arquivos sem placeholder..."

# Arquivo de raiz (sempre copia)
copy_if_absent "$PROJECT_ZERO/SECURITY_NOTES.md"               "$DEST/SECURITY_NOTES.md"

# Docs de IA — sempre vão pra $AI_NS/docs/ (NUNCA solto na raiz)
copy_if_absent "$PROJECT_ZERO/.claude/docs/CONVENTIONS.md"          "$DEST/$AI_NS/docs/CONVENTIONS.md"
copy_if_absent "$PROJECT_ZERO/.claude/docs/GLOSSARY.md"             "$DEST/$AI_NS/docs/GLOSSARY.md"
copy_if_absent "$PROJECT_ZERO/.claude/docs/decisions/README.md"     "$DEST/$AI_NS/docs/decisions/README.md"
copy_if_absent "$PROJECT_ZERO/.claude/docs/decisions/_TEMPLATE.md"  "$DEST/$AI_NS/docs/decisions/_TEMPLATE.md"
copy_if_absent "$PROJECT_ZERO/.claude/docs/project_map/_GUIDE.md"   "$DEST/$AI_NS/docs/project_map/_GUIDE.md"

# Skills, agents, hooks (features Claude-específicas — sob $AI_NS pra organização)
for skill_dir in "$PROJECT_ZERO/.claude/skills/"*/; do
  name=$(basename "$skill_dir")
  copy_if_absent "$skill_dir/SKILL.md" "$DEST/$AI_NS/skills/$name/SKILL.md"
done

for agent_md in "$PROJECT_ZERO/.claude/agents/"*.md; do
  name=$(basename "$agent_md")
  copy_if_absent "$agent_md" "$DEST/$AI_NS/agents/$name"
done

copy_if_absent "$PROJECT_ZERO/.claude/hooks/check-sync-project-map.sh" \
               "$DEST/$AI_NS/hooks/check-sync-project-map.sh"
copy_if_absent "$PROJECT_ZERO/.claude/hooks/check-session-lock.sh" \
               "$DEST/$AI_NS/hooks/check-session-lock.sh"
copy_if_absent "$PROJECT_ZERO/.claude/hooks/on-stop-check.sh" \
               "$DEST/$AI_NS/hooks/on-stop-check.sh"
copy_if_absent "$PROJECT_ZERO/.claude/SESSION_LOCK.template.md" \
               "$DEST/$AI_NS/SESSION_LOCK.md"

echo
echo "[2/6] Mesclando .gitignore..."

if [[ ! -f "$DEST/.gitignore" ]]; then
  cp "$PROJECT_ZERO/.gitignore.template" "$DEST/.gitignore"
  echo "  + criado: $DEST/.gitignore"
else
  added=0
  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    if ! grep -Fxq "$line" "$DEST/.gitignore"; then
      echo "$line" >> "$DEST/.gitignore"
      added=$((added+1))
    fi
  done < "$PROJECT_ZERO/.gitignore.template"
  echo "  · .gitignore existia. Adicionadas $added linhas novas."
fi

echo
echo "[3/6] Criando settings.json (Claude Code) ou skip..."

if [[ "$AI_NS" == ".claude" ]]; then
  if [[ ! -f "$DEST/.claude/settings.json" ]]; then
    cp "$PROJECT_ZERO/.claude/settings.template.json" "$DEST/.claude/settings.json"
    echo "  + criado: $DEST/.claude/settings.json"
  else
    echo "  · .claude/settings.json já existe. Mescla manualmente se precisar."
  fi
else
  echo "  · skip (settings.json é Claude Code-específico — agente $AGENT não usa)."
fi

echo
echo "[4/6] Criando project_map/README.md inicial..."

if [[ ! -f "$DEST/$AI_NS/docs/project_map/README.md" ]]; then
  cp "$PROJECT_ZERO/.claude/docs/project_map/README.template.md" "$DEST/$AI_NS/docs/project_map/README.md"
  echo "  + criado: $DEST/$AI_NS/docs/project_map/README.md (a partir de README.template.md)"
else
  echo "  · $AI_NS/docs/project_map/README.md já existe. Mantido."
fi

echo
echo "[5/6] Copiando scripts auxiliares..."

copy_if_absent "$PROJECT_ZERO/validate.sh"        "$DEST/validate.sh"
copy_if_absent "$PROJECT_ZERO/update_template.sh" "$DEST/update_template.sh"

echo
echo "[6/6] Reescrevendo refs internas .claude/ → $AI_NS/ (se necessário)..."

if [[ "$AI_NS" != ".claude" ]]; then
  # Escapa o namespace pra sed (lida com /, . que viram literais)
  AI_NS_ESC=$(printf '%s\n' "$AI_NS" | sed 's/[\/&]/\\&/g')
  # Reescreve refs em todos arquivos sob $DEST/$AI_NS/
  find "$DEST/$AI_NS" -type f \( -name '*.md' -o -name '*.sh' -o -name '*.json' \) \
    -exec sed -i "s|\.claude/|${AI_NS_ESC}/|g" {} \; 2>/dev/null || \
  find "$DEST/$AI_NS" -type f \( -name '*.md' -o -name '*.sh' -o -name '*.json' \) \
    -exec sed -i '' "s|\.claude/|${AI_NS_ESC}/|g" {} \; 2>/dev/null  # macOS fallback
  echo "  ✓ Refs reescritas em $DEST/$AI_NS/"
  echo "  ✓ Refs em validate.sh / SECURITY_NOTES.md / .gitignore na raiz NÃO foram tocadas — ajuste manual se necessário."
else
  echo "  · skip (namespace é .claude, refs já corretas)."
fi

echo
echo "═══════════════════════════════════════════════════════"
echo " Setup base concluído"
echo "═══════════════════════════════════════════════════════"
echo
echo "Próximos passos (manuais, com o agente):"
echo "  1. Detectar/criar arquivo de instruções do agente:"
case "$AGENT" in
  claude|claude-code) echo "       CLAUDE.md (a partir de project_zero/CLAUDE.template.md)" ;;
  cursor)             echo "       .cursorrules ou .cursor/rules/project.mdc" ;;
  cline)              echo "       .clinerules" ;;
  windsurf)           echo "       .windsurfrules" ;;
  aider)              echo "       CONVENTIONS.md (raiz) + .aider.conf.yml" ;;
  copilot)            echo "       .github/copilot-instructions.md" ;;
  generic|other|ai)   echo "       AGENTS.md" ;;
esac
echo "     substituindo placeholders ({{PROJECT_NAME}}, {{STACK}}, ...)"
echo "  2. Mapear o projeto destino (Passo 6 do README — OBRIGATÓRIO)"
echo "  3. Rodar: bash validate.sh"
echo
echo "Veja project_zero/README.md (Passos 1-8) pro fluxo completo."
