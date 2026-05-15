#!/usr/bin/env bash
# PostToolUse hook — dispara reminder pra rodar sync-project-map
# quando o agente edita um arquivo coberto pelo catálogo.
#
# Filtros pra não disparar em vão (reduz ~85-90% do custo histórico):
#   1. Path não bate o catálogo → silencioso
#   2. Diff < 3 linhas (typo / micro-fix) → silencioso
#   3. Diff só em comentário/whitespace → silencioso
#   4. Mesmo doc já avisado nesta sessão → silencioso (throttling)
#
# Reset throttling entre sessões: delete .claude/tmp/sync_reminders_seen.txt
#
# Como popular o catálogo: edite o array RULES no bloco node abaixo.
# Patterns específicos primeiro, gerais depois.

INPUT=$(cat)

RESULT=$(node -e '
  let buf = "";
  process.stdin.on("data", c => buf += c);
  process.stdin.on("end", () => {
    try {
      const j = JSON.parse(buf);
      const fp = ((j.tool_input && j.tool_input.file_path) || "").replace(/\\/g, "/");
      if (!fp) { process.stdout.write(""); return; }

      // ====================================================================
      // CATÁLOGO arquivo → doc
      // ====================================================================
      // Adicione regras conforme criar docs em docs/project_map/.
      // Sintaxe: [regex no path relativo, "nome-do-doc.md"]
      //
      // Exemplos:
      //   [/^src\/core\/.+\.js$/,           "core.md"],
      //   [/^src\/api\/auth\.js$/,          "auth.md"],
      //   [/^src\/db\/migrations\/.+\.sql$/,"database.md"],
      // ====================================================================
      const RULES = [
        // ---- POPULAR AQUI ----
      ];

      const rel = fp.replace(/^.*?(?=src\/|lib\/|app\/|tests?\/|docs\/|scripts\/)/, "");

      for (const [re, doc] of RULES) {
        if (re.test(rel)) {
          process.stdout.write(rel + "|" + doc);
          return;
        }
      }
      process.stdout.write("");
    } catch (e) {
      process.stdout.write("");
    }
  });
' <<< "$INPUT")

# Filtro 1: sem match no catálogo → silencioso
if [[ -z "$RESULT" ]]; then
  exit 0
fi

REL="${RESULT%%|*}"
DOC="${RESULT##*|}"

# Filtros 2 e 3 dependem de git. Se não for repo, pula esses filtros.
if git rev-parse --git-dir > /dev/null 2>&1; then

  # Filtro 2: diff trivial (< 3 linhas total)
  STATS=$(git diff --numstat HEAD -- "$REL" 2>/dev/null | head -1)
  if [[ -n "$STATS" ]]; then
    ADDED=$(echo "$STATS" | awk '{print $1}')
    REMOVED=$(echo "$STATS" | awk '{print $2}')
    if [[ "$ADDED" =~ ^[0-9]+$ ]] && [[ "$REMOVED" =~ ^[0-9]+$ ]]; then
      TOTAL=$((ADDED + REMOVED))
      if [[ $TOTAL -lt 3 ]]; then
        exit 0
      fi
    fi
  fi

  # Filtro 3: diff só em comentário ou whitespace
  ONLY_COMMENT=$(git diff HEAD -- "$REL" 2>/dev/null | awk '
    /^[+-][^+-]/ {
      line = substr($0, 2)
      gsub(/^[ \t]+/, "", line)
      if (line == "") next
      if (line !~ /^(\/\/|\/\*|\*[^\/]|\*$|#|<!--|-->|"""|'\'\'\'')/) {
        non_comment++
      }
    }
    END { print (non_comment ? "no" : "yes") }
  ')
  if [[ "$ONLY_COMMENT" == "yes" ]]; then
    exit 0
  fi

fi

# Filtro 4: throttling — já avisou esse doc nesta sessão?
SEEN_FILE=".claude/tmp/sync_reminders_seen.txt"
mkdir -p .claude/tmp
if [[ -f "$SEEN_FILE" ]] && grep -Fxq "$DOC" "$SEEN_FILE"; then
  exit 0
fi
echo "$DOC" >> "$SEEN_FILE"

# Dispara reminder enxuto
cat <<JSON
{
  "continue": true,
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "doc afetado: docs/project_map/$DOC — revisar antes de fechar (skill sync-project-map). Detalhe do workflow na própria skill, não repetido aqui."
  }
}
JSON
