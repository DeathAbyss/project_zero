#!/usr/bin/env bash
# PreToolUse hook — gate DURO da harness.
# Bloqueia escrita do recap em .claude/changes/archive/<nome>.md enquanto
# os 4 vereditos do gate não estiverem {PASS, N/A}.
#
# Vereditos esperados em .claude/changes/<nome>/harness/:
#   security.md  tests.md  data-protection.md  code-review.md
# Cada um com frontmatter `status: PASS|N/A|BLOCKED`.
#
# Libera (allow/silencioso) quando:
#   - O alvo não é um recap em changes/archive/ → não é problema do gate
#   - Os 4 vereditos existem com status PASS ou N/A
#
# Bloqueia (deny) quando: falta veredito OU algum está BLOCKED.
# Doutrina: .claude/docs/05-harness.md

INPUT=$(cat)

RESULT=$(node -e '
  let buf = "";
  process.stdin.on("data", c => buf += c);
  process.stdin.on("end", () => {
    try {
      const fs = require("fs");
      const j = JSON.parse(buf);
      const fp = ((j.tool_input && j.tool_input.file_path) || "").replace(/\\/g, "/");
      if (!fp) { process.stdout.write("ALLOW"); return; }

      // Só intercepta escrita de recap em changes/archive/<nome>.md
      const m = fp.match(/\.claude\/changes\/archive\/([^/]+)\.md$/);
      if (!m) { process.stdout.write("ALLOW"); return; }
      const name = m[1];
      if (name === "" || name === ".gitkeep") { process.stdout.write("ALLOW"); return; }

      const dir = ".claude/changes/" + name + "/harness";
      const required = ["security.md", "tests.md", "data-protection.md", "code-review.md"];
      const missing = [];
      const blocked = [];

      for (const f of required) {
        const path = dir + "/" + f;
        let txt;
        try { txt = fs.readFileSync(path, "utf8"); }
        catch (e) { missing.push(f); continue; }
        const sm = txt.match(/^status:\s*(.+)$/m);
        const status = sm ? sm[1].trim().toUpperCase() : "";
        if (status === "PASS" || status === "N/A" || status === "NA") continue;
        blocked.push(f + " (status: " + (status || "ausente") + ")");
      }

      if (missing.length === 0 && blocked.length === 0) {
        process.stdout.write("ALLOW");
        return;
      }
      process.stdout.write("DENY|||" + name + "|||" + missing.join(",") + "|||" + blocked.join(","));
    } catch (e) {
      // Em dúvida, não bloqueia (hook não deve travar trabalho por bug próprio)
      process.stdout.write("ALLOW");
    }
  });
' <<< "$INPUT")

if [[ "$RESULT" == "ALLOW" ]] || [[ -z "$RESULT" ]]; then
  exit 0
fi

NAME=$(echo "$RESULT"    | awk -F'\\|\\|\\|' '{print $2}')
MISSING=$(echo "$RESULT" | awk -F'\\|\\|\\|' '{print $3}')
BLOCKED=$(echo "$RESULT" | awk -F'\\|\\|\\|' '{print $4}')

REASON="Gate da harness incompleto para a change '$NAME'. Archive bloqueado."
[[ -n "$MISSING" ]] && REASON="$REASON Vereditos faltando: $MISSING."
[[ -n "$BLOCKED" ]] && REASON="$REASON Vereditos não resolvidos: $BLOCKED."
REASON="$REASON Resolva o gate (rode os agentes seguranca/testes/protecao-dados + skill code-review; corrija achados ou justifique N/A) antes de arquivar. Ver .claude/docs/05-harness.md."

node -e '
  const reason = process.argv[1];
  process.stdout.write(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: reason
    }
  }));
' "$REASON"

exit 0
