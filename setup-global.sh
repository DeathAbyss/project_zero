#!/usr/bin/env bash
# setup-global.sh — instala a CAMADA REUTILIZÁVEL do project_zero no
# ~/.claude/ do Claude Code (agents, skills, hooks, docs de doutrina,
# scripts), registra os hooks no settings.json e anexa ponteiros no
# CLAUDE.md global. Idempotente: pode rodar de novo pra atualizar.
#
# NÃO instala peças per-projeto (changes/, harness.config, project_map,
# GLOSSARY, SESSION_LOCK) — isso é o setup-project.sh.
#
# Uso:
#   bash project_zero/setup-global.sh            # instala em ~/.claude
#   bash project_zero/setup-global.sh <dir>      # instala em <dir> (override)
#
# Requisitos: bash, node, (Git Bash no Windows). cygpath usado se houver.

set -euo pipefail
shopt -s nullglob

PROJECT_ZERO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$PROJECT_ZERO/.claude"

DST_IN="${1:-$HOME/.claude}"
mkdir -p "$DST_IN"
DST="$(cd "$DST_IN" && pwd)"

# Caminho do dest em forma que o Claude Code entende no command do hook.
# No Windows (Git Bash), converte /c/Users/... → C:/Users/... via cygpath.
if command -v cygpath >/dev/null 2>&1; then
  DST_CMD="$(cygpath -m "$DST")"
else
  DST_CMD="$DST"
fi

# sed -i portável (GNU vs BSD/macOS)
sed_inplace() {
  sed -i "$@" 2>/dev/null || sed -i '' "$@"
}

mkdir -p "$DST/agents" "$DST/skills" "$DST/hooks" "$DST/docs/decisions" "$DST/scripts" "$DST/backups"

echo "project_zero → instalação GLOBAL em: $DST"
echo

# ── Backup de settings.json + CLAUDE.md (se existirem) ───────────────
TS="$(date +%Y%m%d_%H%M%S)"
for f in settings.json CLAUDE.md; do
  if [[ -f "$DST/$f" ]]; then
    cp "$DST/$f" "$DST/backups/$f.$TS.bak"
    echo "  backup: backups/$f.$TS.bak"
  fi
done

# ── Agents ───────────────────────────────────────────────────────────
echo
echo "[1/6] Agents..."
for a in operador dev analista escriba protecao-dados; do
  cp "$SRC/agents/$a.md" "$DST/agents/$a.md"
  echo "  + $a.md"
done

# seguranca/testes: renomeia pra pz-* SE já existir versão diferente no
# destino (evita clobber de agentes de mesmo nome — ex: BookDragon).
install_harness_agent() {
  local name="$1" target="$1"
  if [[ -f "$DST/agents/$name.md" ]] && ! cmp -s "$SRC/agents/$name.md" "$DST/agents/$name.md"; then
    target="pz-$name"
  fi
  cp "$SRC/agents/$name.md" "$DST/agents/$target.md"
  sed_inplace "s/^name: $name\$/name: $target/" "$DST/agents/$target.md"
  printf '%s' "$target"
}
SEG="$(install_harness_agent seguranca)"
TST="$(install_harness_agent testes)"
echo "  + $SEG.md (harness segurança)"
echo "  + $TST.md (harness testes)"

# ── Skills (pula switch-agent-profile: depende de tooling per-projeto) ─
echo
echo "[2/6] Skills..."
for skill_dir in "$SRC/skills/"*/; do
  name="$(basename "$skill_dir")"
  [[ "$name" == "switch-agent-profile" ]] && { echo "  · skip $name (per-projeto)"; continue; }
  [[ -f "$skill_dir/SKILL.md" ]] || continue
  mkdir -p "$DST/skills/$name"
  cp "$skill_dir/SKILL.md" "$DST/skills/$name/SKILL.md"
  echo "  + $name"
done

# ── Hooks ──────────────────────────────────────────────────────────────
echo
echo "[3/6] Hooks..."
for h in check-sync-project-map check-session-lock check-harness-gate on-stop-check check-teammate-verdict; do
  cp "$SRC/hooks/$h.sh" "$DST/hooks/$h.sh"
  echo "  + $h.sh"
done

# ── Docs de doutrina (pula GLOSSARY e project_map: per-projeto) ─────────
echo
echo "[4/6] Docs de doutrina..."
for d in CONVENTIONS SECURITY_NOTES 01-git 02-token-efficiency 03-multiagent 04-task-closure 05-harness; do
  cp "$SRC/docs/$d.md" "$DST/docs/$d.md"
  echo "  + docs/$d.md"
done
cp "$SRC/docs/decisions/README.md"    "$DST/docs/decisions/README.md"
cp "$SRC/docs/decisions/_TEMPLATE.md" "$DST/docs/decisions/_TEMPLATE.md"
cp "$SRC/scripts/cost-report.py"      "$DST/scripts/cost-report.py"
echo "  + docs/decisions/ + scripts/cost-report.py"

# Alinha refs de despacho no 05-harness e a hint do hook com o nome
# resolvido dos agentes (no-op se não houve rename).
sed_inplace "s/agente \`seguranca\`/agente \`$SEG\`/g; s/agente \`testes\`/agente \`$TST\`/g" "$DST/docs/05-harness.md"
sed_inplace "s#seguranca/testes/protecao-dados#$SEG/$TST/protecao-dados#g" "$DST/hooks/check-harness-gate.sh"

# ── Merge dos hooks no settings.json (preserva o que já existe) ─────────
echo
echo "[5/6] Registrando hooks em settings.json..."
SETTINGS="$DST/settings.json" HOOKDIR="$DST_CMD/hooks" node -e '
  const fs = require("fs");
  const sp = process.env.SETTINGS, hd = process.env.HOOKDIR;
  let s = {};
  try { s = JSON.parse(fs.readFileSync(sp, "utf8")); } catch (e) {}
  s.hooks = s.hooks || {};

  function ensure(event, matcher, files) {
    s.hooks[event] = s.hooks[event] || [];
    const present = new Set();
    for (const blk of s.hooks[event])
      for (const h of (blk.hooks || [])) present.add(h.command || "");
    let block = s.hooks[event].find(b => (b.matcher || "") === (matcher || ""));
    if (!block) { block = matcher ? { matcher, hooks: [] } : { hooks: [] }; s.hooks[event].push(block); }
    block.hooks = block.hooks || [];
    for (const f of files) {
      const has = [...present].some(c => c.includes(f));
      if (!has) block.hooks.push({ type: "command", command: `bash "${hd}/${f}"` });
    }
  }

  ensure("PreToolUse",  "Edit|Write|MultiEdit", ["check-session-lock.sh", "check-harness-gate.sh"]);
  ensure("PostToolUse", "Edit|Write|MultiEdit", ["check-sync-project-map.sh"]);
  ensure("Stop",        null,                   ["on-stop-check.sh"]);
  ensure("TeammateIdle", null,                  ["check-teammate-verdict.sh"]);

  fs.writeFileSync(sp, JSON.stringify(s, null, 2) + "\n");
  console.log("  ✓ settings.json: PreToolUse/PostToolUse/Stop/TeammateIdle garantidos (existentes preservados)");
'

# ── Ponteiros no CLAUDE.md global (idempotente por marcador) ───────────
echo
echo "[6/6] CLAUDE.md global..."
MARKER="# Camada project_zero (global)"
if [[ -f "$DST/CLAUDE.md" ]] && grep -qF "$MARKER" "$DST/CLAUDE.md"; then
  echo "  · já tem a seção project_zero. Mantido."
else
  cat >> "$DST/CLAUDE.md" <<EOF

$MARKER

Doutrina genérica reutilizável instalada de \`project_zero\`. Carrega sob
demanda — leia o doc relevante quando aplicável.

- \`~/.claude/docs/CONVENTIONS.md\` — docs compactos, estilo, output, briefing.
- \`~/.claude/docs/01-git.md\` — git/PR/branch protegida.
- \`~/.claude/docs/02-token-efficiency.md\` — anti-padrões de token.
- \`~/.claude/docs/03-multiagent.md\` — quando despachar sub-agente.
- \`~/.claude/docs/04-task-closure.md\` — checklist antes de fechar task.
- \`~/.claude/docs/05-harness.md\` — gate de verificação SDD + ciclo de fix.
- \`~/.claude/docs/SECURITY_NOTES.md\` — arquivos sensíveis a não tocar.

## SDD + harness (genérico)

Mudança não-trivial: \`sdd-explore\` (opcional) → \`sdd-propose\` → implementa
→ gate harness → \`sdd-archive\`. Gate roda 4 perspectivas: agentes
\`$SEG\`, \`$TST\`, \`protecao-dados\` + skill \`code-review-and-quality\`.
Hook \`check-harness-gate.sh\` bloqueia archive sem os 4 {PASS, N/A}.

Per-projeto (rode setup-project.sh no repo): \`.claude/changes/\` +
\`.claude/harness.config\` (jurisdição LGPD/GDPR).
EOF
  echo "  + seção project_zero anexada (BookDragon/conteúdo prévio preservado acima)"
fi

echo
echo "═══════════════════════════════════════════════════════"
echo " Global instalado em $DST"
echo "═══════════════════════════════════════════════════════"
echo "Agents harness: $SEG, $TST, protecao-dados"
echo "Hooks ativos em TODO projeto (paths relativos ao cwd)."
echo "Próximo: em cada repo rode  bash project_zero/setup-project.sh"
