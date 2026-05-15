#!/bin/bash
# Manage agent profiles in .claude/agent-profiles/.
#
# Usage:
#   bash .claude/switch-agents.sh                          → lista profile ativo + disponíveis
#   bash .claude/switch-agents.sh <profile>                → troca pro profile dado
#   bash .claude/switch-agents.sh create <nome>            → cria profile vazio
#   bash .claude/switch-agents.sh create <nome> <base>     → cria profile clonado de <base>
#
# O profile ativo é registrado em .claude/agent-profiles/.active.

set -euo pipefail
shopt -s nullglob

PROFILES_DIR=".claude/agent-profiles"
ACTIVE_DIR=".claude/agents"
MARKER="$PROFILES_DIR/.active"

if [ ! -d "$PROFILES_DIR" ]; then
  echo "Erro: $PROFILES_DIR não existe." >&2
  exit 1
fi

list_profiles() {
  for d in "$PROFILES_DIR"/*/; do
    [ -d "$d" ] && echo "  - $(basename "$d")"
  done
}

CMD="${1:-}"

# Modo: listar
if [ -z "$CMD" ]; then
  if [ -f "$MARKER" ]; then
    echo "Profile ativo: $(cat "$MARKER")"
  else
    echo "Profile ativo: <desconhecido> (marker $MARKER ausente)"
  fi
  echo ""
  echo "Profiles disponíveis:"
  list_profiles
  echo ""
  echo "Uso:"
  echo "  bash $0 <profile>                  troca pro profile"
  echo "  bash $0 create <nome> [<base>]     cria profile (opcionalmente clonando)"
  exit 0
fi

# Modo: criar
if [ "$CMD" = "create" ]; then
  NAME="${2:-}"
  BASE="${3:-}"

  if [ -z "$NAME" ]; then
    echo "Erro: nome do profile faltando." >&2
    echo "Uso: bash $0 create <nome> [<profile-base>]" >&2
    exit 1
  fi

  # Validação básica de nome (evita paths arbitrários, espaços etc.)
  if ! [[ "$NAME" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    echo "Erro: nome '$NAME' inválido. Use só letras, números, '.', '_', '-'." >&2
    exit 1
  fi

  TARGET="$PROFILES_DIR/$NAME"
  if [ -e "$TARGET" ]; then
    echo "Erro: '$TARGET' já existe." >&2
    exit 1
  fi

  # Valida base ANTES de criar nada (evita deixar pasta órfã em caso de erro)
  if [ -n "$BASE" ]; then
    BASE_DIR="$PROFILES_DIR/$BASE"
    if [ ! -d "$BASE_DIR" ]; then
      echo "Erro: profile base '$BASE' não existe em $PROFILES_DIR." >&2
      echo "Disponíveis:" >&2
      list_profiles >&2
      exit 1
    fi
  fi

  mkdir -p "$TARGET"

  if [ -n "$BASE" ]; then
    base_files=( "$BASE_DIR"/*.md )
    if [ ${#base_files[@]} -gt 0 ]; then
      cp "${base_files[@]}" "$TARGET/"
      echo "Profile '$NAME' criado em $TARGET (clonado de '$BASE')."
      echo "Arquivos:"
      for f in "$TARGET"/*.md; do
        echo "  - $(basename "$f")"
      done
    else
      echo "Profile '$NAME' criado em $TARGET. Base '$BASE' não tinha .md — ficou vazio."
    fi
  else
    echo "Profile '$NAME' criado vazio em $TARGET."
    echo "Pra popular: adicione arquivos .md em $TARGET/ manualmente,"
    echo "ou copie de outro profile (ex.: cp $PROFILES_DIR/fibonacci/*.md $TARGET/)."
  fi

  echo ""
  echo "Pra ativar: bash $0 $NAME"
  exit 0
fi

# Modo: trocar profile
PROFILE="$CMD"
SRC="$PROFILES_DIR/$PROFILE"
if [ ! -d "$SRC" ]; then
  echo "Erro: profile '$PROFILE' não encontrado em $PROFILES_DIR." >&2
  echo "Disponíveis:" >&2
  list_profiles >&2
  exit 1
fi

mkdir -p "$ACTIVE_DIR"

# Limpa agentes ativos antigos (só .md no nível raiz de .claude/agents/)
find "$ACTIVE_DIR" -maxdepth 1 -name '*.md' -type f -delete

# Copia o profile escolhido (tolera profile vazio)
src_files=( "$SRC"/*.md )
if [ ${#src_files[@]} -gt 0 ]; then
  cp "${src_files[@]}" "$ACTIVE_DIR/"
fi

# Atualiza marker
echo "$PROFILE" > "$MARKER"

echo "Profile ativo agora: $PROFILE"
active_files=( "$ACTIVE_DIR"/*.md )
if [ ${#active_files[@]} -eq 0 ]; then
  echo "Agentes em $ACTIVE_DIR/: (nenhum — profile vazio)"
else
  echo "Agentes em $ACTIVE_DIR/:"
  for f in "${active_files[@]}"; do
    echo "  - $(basename "$f")"
  done
fi
