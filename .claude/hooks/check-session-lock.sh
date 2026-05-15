#!/usr/bin/env bash
# PreToolUse hook — avisa quando Edit/Write toca arquivo reivindicado
# por sessão ativa em SESSION_LOCK.md.
#
# Não bloqueia (não tem como saber se é a sessão dona). Só injeta
# AVISO via additionalContext. A IA decide: se for a própria sessão
# que reivindicou, ignora; senão, pergunta ao usuário antes de
# prosseguir.
#
# Silencioso (exit 0) quando:
#   - SESSION_LOCK.md não existe (projeto não usa)
#   - Nenhuma sessão ativa reivindica o arquivo
#
# Formato esperado de SESSION_LOCK.md (template em
# .claude/SESSION_LOCK.template.md):
#   ### Sessão X — <timestamp> — <user>
#   **Status**: ativa
#   **Arquivos reservados**:
#   - `path/to/foo.js`
#   - `src/auth/*`

INPUT=$(cat)
LOCK_FILE=".claude/SESSION_LOCK.md"

[[ ! -f "$LOCK_FILE" ]] && exit 0

RESULT=$(node -e '
  let buf = "";
  process.stdin.on("data", c => buf += c);
  process.stdin.on("end", () => {
    try {
      const fs = require("fs");
      const j = JSON.parse(buf);
      const fp = ((j.tool_input && j.tool_input.file_path) || "").replace(/\\/g, "/");
      if (!fp) { process.stdout.write(""); return; }

      const rel = fp.replace(/^.*?(?=src\/|lib\/|app\/|tests?\/|docs\/|scripts\/|\.claude\/)/, "");
      const lock = fs.readFileSync(".claude/SESSION_LOCK.md", "utf8");

      // Cada bloco começa em "### "
      const sessions = lock.split(/^### /m).slice(1);

      for (const s of sessions) {
        const header = s.split("\n")[0].trim();
        // Só considera sessões com Status: ativa
        if (!/\*\*Status\*\*\s*:\s*ativa/i.test(s)) continue;

        // Extrai paths em linhas `- ` + crases
        const re = /^[-*]\s*`([^`]+)`/gm;
        let m;
        while ((m = re.exec(s)) !== null) {
          const claimed = m[1].trim();
          // Glob simples: `*` vira `.*` em regex
          const escaped = claimed.replace(/[.+?^${}()|\[\]\\]/g, "\\$&").replace(/\*/g, ".*");
          const reMatch = new RegExp("^" + escaped + "$");
          if (
            reMatch.test(rel) ||
            reMatch.test(fp) ||
            (claimed.endsWith("/") && (rel.startsWith(claimed) || fp.includes("/" + claimed))) ||
            fp.endsWith("/" + claimed) ||
            rel === claimed
          ) {
            process.stdout.write(header + "|||" + claimed + "|||" + fp);
            return;
          }
        }
      }
      process.stdout.write("");
    } catch (e) {
      process.stdout.write("");
    }
  });
' <<< "$INPUT")

[[ -z "$RESULT" ]] && exit 0

SESSION=$(echo "$RESULT" | awk -F'\\|\\|\\|' '{print $1}')
CLAIMED=$(echo "$RESULT" | awk -F'\\|\\|\\|' '{print $2}')
TARGET=$(echo "$RESULT"  | awk -F'\\|\\|\\|' '{print $3}')

cat <<JSON
{
  "continue": true,
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "AVISO SESSION_LOCK: \`$TARGET\` está reivindicado em \`$SESSION\` (pattern: \`$CLAIMED\`). Se esta sessão NÃO é a dona, pergunte ao usuário antes de continuar."
  }
}
JSON
