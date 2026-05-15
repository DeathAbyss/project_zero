#!/usr/bin/env bash
# setup.sh — aplica o project_zero num projeto destino.
#
# Cobre o trivial do Passo 5 (copia arquivos sem placeholder + mescla
# .gitignore + cria .claude/settings.json). Decisões importantes (detecção
# de agente, placeholders do CLAUDE.md, mapeamento) ficam pro fluxo
# interativo com o agente.
#
# Uso:  bash project_zero/setup.sh [destino]
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

if [[ ! -d "$DEST" ]]; then
  echo "ERRO: destino '$DEST' não existe."
  exit 1
fi

echo "═══════════════════════════════════════════════════════"
echo " project_zero setup"
echo "═══════════════════════════════════════════════════════"
echo "Template: $PROJECT_ZERO"
echo "Destino:  $DEST"
echo
read -p "Confirma? [y/N] " confirm
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
echo "[1/5] Copiando arquivos sem placeholder..."

copy_if_absent "$PROJECT_ZERO/SECURITY_NOTES.md"               "$DEST/SECURITY_NOTES.md"
copy_if_absent "$PROJECT_ZERO/docs/CONVENTIONS.md"             "$DEST/docs/CONVENTIONS.md"
copy_if_absent "$PROJECT_ZERO/docs/GLOSSARY.md"                "$DEST/docs/GLOSSARY.md"
copy_if_absent "$PROJECT_ZERO/docs/decisions/README.md"        "$DEST/docs/decisions/README.md"
copy_if_absent "$PROJECT_ZERO/docs/decisions/_TEMPLATE.md"     "$DEST/docs/decisions/_TEMPLATE.md"
copy_if_absent "$PROJECT_ZERO/docs/project_map/_GUIDE.md"      "$DEST/docs/project_map/_GUIDE.md"

# Skills, agents, hooks (Claude Code)
for skill_dir in "$PROJECT_ZERO/.claude/skills/"*/; do
  name=$(basename "$skill_dir")
  copy_if_absent "$skill_dir/SKILL.md" "$DEST/.claude/skills/$name/SKILL.md"
done

for agent in "$PROJECT_ZERO/.claude/agents/"*.md; do
  name=$(basename "$agent")
  copy_if_absent "$agent" "$DEST/.claude/agents/$name"
done

copy_if_absent "$PROJECT_ZERO/.claude/hooks/check-sync-project-map.sh" \
               "$DEST/.claude/hooks/check-sync-project-map.sh"
copy_if_absent "$PROJECT_ZERO/.claude/hooks/check-session-lock.sh" \
               "$DEST/.claude/hooks/check-session-lock.sh"
copy_if_absent "$PROJECT_ZERO/.claude/hooks/on-stop-check.sh" \
               "$DEST/.claude/hooks/on-stop-check.sh"
copy_if_absent "$PROJECT_ZERO/.claude/SESSION_LOCK.template.md" \
               "$DEST/.claude/SESSION_LOCK.template.md"

echo
echo "[2/5] Mesclando .gitignore..."

if [[ ! -f "$DEST/.gitignore" ]]; then
  cp "$PROJECT_ZERO/.gitignore.template" "$DEST/.gitignore"
  echo "  + criado: $DEST/.gitignore"
else
  # Adiciona linhas que não existem
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
echo "[3/5] Criando .claude/settings.json (mínimo)..."

if [[ ! -f "$DEST/.claude/settings.json" ]]; then
  cp "$PROJECT_ZERO/.claude/settings.template.json" "$DEST/.claude/settings.json"
  echo "  + criado: $DEST/.claude/settings.json"
else
  echo "  · .claude/settings.json já existe. Mescla manualmente se precisar."
fi

echo
echo "[4/5] Criando project_map/README.md inicial..."

if [[ ! -f "$DEST/docs/project_map/README.md" ]]; then
  cat > "$DEST/docs/project_map/README.md" <<'EOF'
# Project map — índice

Docs compactos por área do projeto (50-150 linhas cada). Regras
canônicas: [`docs/CONVENTIONS.md`](../CONVENTIONS.md).

## Áreas mapeadas

| Doc | Área | Status |
|---|---|---|
| _(vazio — popule conforme criar docs em Passo 6)_ | | |

## Como adicionar uma nova área

1. Crie `<area>.md` aqui seguindo `_GUIDE.md`
2. Adicione entrada na tabela acima
3. Adicione regex no `.claude/hooks/check-sync-project-map.sh`
4. Adicione entrada em `.claude/skills/sync-project-map/SKILL.md`
EOF
  echo "  + criado: $DEST/docs/project_map/README.md"
else
  echo "  · docs/project_map/README.md já existe. Mantido."
fi

echo
echo "[5/5] Copiando scripts auxiliares..."

copy_if_absent "$PROJECT_ZERO/validate.sh"        "$DEST/validate.sh"
copy_if_absent "$PROJECT_ZERO/update_template.sh" "$DEST/update_template.sh"

echo
echo "═══════════════════════════════════════════════════════"
echo " Setup base concluído"
echo "═══════════════════════════════════════════════════════"
echo
echo "Próximos passos (manuais, com o agente):"
echo "  1. Detectar/criar CLAUDE.md (ou .cursorrules, .clinerules, etc.)"
echo "     substituindo placeholders ({{PROJECT_NAME}}, {{STACK}}, ...)"
echo "  2. Mapear o projeto destino (Passo 6 do README — OBRIGATÓRIO)"
echo "  3. Rodar: bash validate.sh"
echo
echo "Veja project_zero/README.md (Passos 1-8) pro fluxo completo."
