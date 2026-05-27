#!/usr/bin/env bash
# TeammateIdle hook — garante que agente de harness gravou o veredito
# antes de ficar idle.
#
# No gate paralelo, seguranca/testes/protecao-dados rodam como teammates.
# Cada um deve gravar seu arquivo em .claude/changes/<nome>/harness/ antes
# de encerrar. Este hook bloqueia o idle (exit 2 = mantém o teammate
# trabalhando + envia feedback) se o veredito esperado não existe.
#
# Teammate → arquivo esperado:
#   seguranca / pz-seguranca   → security.md
#   testes / pz-testes         → tests.md
#   protecao-dados             → data-protection.md
# Qualquer outro nome → não é problema deste hook (exit 0).
#
# Doutrina: .claude/docs/05-harness.md

INPUT=$(cat)

RESULT=$(node -e '
  let buf = "";
  process.stdin.on("data", c => buf += c);
  process.stdin.on("end", () => {
    try {
      const fs = require("fs");
      const path = require("path");
      let j = {};
      try { j = JSON.parse(buf); } catch (e) {}

      // Nome do teammate: tenta vários campos + env var.
      const raw = (
        j.teammate_name || j.teammateName || j.agent_type ||
        j.agentType || j.name ||
        (j.teammate && (j.teammate.name || j.teammate.agent_type)) ||
        process.env.TEAMMATE_NAME || ""
      ).toString().trim().toLowerCase();

      if (!raw) { process.stdout.write("ALLOW"); return; }

      // Mapa nome → arquivo de veredito (normaliza prefixo pz-).
      const map = {
        "seguranca": "security.md",
        "pz-seguranca": "security.md",
        "testes": "tests.md",
        "pz-testes": "tests.md",
        "protecao-dados": "data-protection.md",
        "pz-protecao-dados": "data-protection.md"
      };
      const wanted = map[raw];
      if (!wanted) { process.stdout.write("ALLOW"); return; }

      // Acha a change-dir ativa (mais recentemente modificada),
      // ignorando _templates e archive.
      const base = ".claude/changes";
      let dirs = [];
      try {
        dirs = fs.readdirSync(base).filter(d => {
          if (d === "_templates" || d === "archive") return false;
          try { return fs.statSync(path.join(base, d)).isDirectory(); }
          catch (e) { return false; }
        });
      } catch (e) { process.stdout.write("ALLOW"); return; }
      if (dirs.length === 0) { process.stdout.write("ALLOW"); return; }

      dirs.sort((a, b) => {
        const ma = fs.statSync(path.join(base, a)).mtimeMs;
        const mb = fs.statSync(path.join(base, b)).mtimeMs;
        return mb - ma;
      });
      const active = dirs[0];

      const verdict = path.join(base, active, "harness", wanted);
      if (fs.existsSync(verdict)) { process.stdout.write("ALLOW"); return; }

      process.stdout.write("BLOCK|||" + raw + "|||" + active + "|||" + wanted);
    } catch (e) {
      // Em dúvida, não bloqueia (hook não trava trabalho por bug próprio).
      process.stdout.write("ALLOW");
    }
  });
' <<< "$INPUT")

if [[ "$RESULT" == "ALLOW" ]] || [[ -z "$RESULT" ]]; then
  exit 0
fi

NAME=$(echo "$RESULT"    | awk -F'\\|\\|\\|' '{print $2}')
CHANGE=$(echo "$RESULT"  | awk -F'\\|\\|\\|' '{print $3}')
FILE=$(echo "$RESULT"    | awk -F'\\|\\|\\|' '{print $4}')

echo "Teammate '$NAME' tentou ficar idle sem gravar o veredito do gate." >&2
echo "Grave .claude/changes/$CHANGE/harness/$FILE com frontmatter 'status: PASS|N/A|BLOCKED'" >&2
echo "e envie SendMessage ao lead com o sumário antes de encerrar. Ver .claude/docs/05-harness.md." >&2
exit 2
