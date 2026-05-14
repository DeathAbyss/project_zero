#!/usr/bin/env bash
# PostToolUse hook — dispara um lembrete pra rodar a skill
# `sync-project-map` quando o agente edita um arquivo coberto pelo
# catálogo da pasta docs/project_map/.
#
# Lê o JSON do tool no stdin, extrai `tool_input.file_path`, normaliza
# pra forward slashes e tenta resolver pro doc correspondente. Se acha,
# devolve um system reminder via additionalContext sinalizando o doc
# que precisa de revisão. Não-bloqueante: a edição segue normal.
#
# Como popular o catálogo: edite o array RULES no bloco node abaixo.
# Ordem importa — primeira regra que bater ganha. Patterns específicos
# primeiro, gerais depois.

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
      // Exemplos (apague e substitua pelas suas regras):
      //   [/^src\/core\/.+\.js$/,           "core.md"],
      //   [/^src\/api\/auth\.js$/,          "auth.md"],
      //   [/^src\/db\/migrations\/.+\.sql$/,"database.md"],
      // ====================================================================
      const RULES = [
        // ---- POPULAR AQUI ----
      ];

      // Normaliza fp removendo prefixo absoluto. Match relativo é o
      // que funciona com as regras. Ajuste o prefixo conforme a raiz
      // canonical do seu projeto (ex: "src/", "lib/", "app/").
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

# Sem match → não interrompe nem injeta nada.
if [[ -z "$RESULT" ]]; then
  exit 0
fi

REL="${RESULT%%|*}"
DOC="${RESULT##*|}"

# Devolve um system reminder via hookSpecificOutput.additionalContext.
cat <<JSON
{
  "continue": true,
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Você editou \`$REL\`. Antes de fechar o turno, atualize \`docs/project_map/$DOC\`: (1) verifique refs file:line, símbolos exportados e valores citados; (2) atualize o doc se houver drift; (3) se descobriu seção/função nova relevante, documente. **Se multiagente está ativo** (existe \`.claude/agents/escriba.md\`), despache o sub-agente \`escriba\` pra fazer isso — a skill \`sync-project-map\` é a documentação canônica do workflow que ele segue. **Senão**, invoque a skill \`sync-project-map\` diretamente. Skip apenas se a mudança for puramente cosmética OU refactor sem novo símbolo público / sem efeito na topologia documentada."
  }
}
JSON
