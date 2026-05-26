#!/usr/bin/env bash
# Stop hook — lembrete de fechamento quando o turno teve mudanças.
#
# Heurística simples e robusta:
#  - git status mostra arquivos modificados/novos? → turno teve trabalho real
#  - Ainda não avisou nesta sessão (throttle file)? → injeta lembrete
#  - Senão, silencioso
#
# Não substitui o checklist "Antes de fechar a task" do CLAUDE.md.
# Lembra de coisas que escapam do checklist (memory, ADRs, deps, i18n,
# version bump, drift de project_map) — categorias que só viram bullet
# vago lá.
#
# Reset throttle: rm .claude/tmp/stop_reminder_shown
# (próxima sessão sem reset = silencioso, presumindo que já avisou)

THROTTLE=".claude/tmp/stop_reminder_shown"

# Throttle: já avisou nesta sessão → silencioso
[[ -f "$THROTTLE" ]] && exit 0

# Sem git → silencioso (sem como detectar mudanças)
git rev-parse --git-dir > /dev/null 2>&1 || exit 0

# Sem mudanças no working tree → nada pra fechar
CHANGES=$(git status --porcelain 2>/dev/null | wc -l)
[[ $CHANGES -eq 0 ]] && exit 0

# Marca throttle
mkdir -p .claude/tmp
touch "$THROTTLE"

# Lembrete enxuto. Detalhe de "como fazer" fica nas skills/docs
# canônicos — não repete aqui.
cat <<'JSON'
{
  "continue": true,
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "additionalContext": "Working tree tem mudanças. Antes de declarar a task fechada, considere as propagações que costumam escapar:\n- memory: algo surpreendente vale traço durável? (memory/_PATTERNS.md)\n- project_map: doc da área afetada precisa update? (skill sync-project-map)\n- ADR: decisão arquitetural não-óbvia? (.claude/docs/decisions/)\n- deps: manifesto de dependências (package.json / pom.xml / Cargo.toml / requirements.txt / go.mod / etc.) mudou?\n- i18n: se o projeto tem i18n, string visível adicionada cobre todos os idiomas?\n- version bump: se o projeto tem version field em algum manifesto, mudança significativa pede bump?\n\nPra varredura completa: skill task-retrospect.\nIgnore se nada se aplica. Reset throttle: rm .claude/tmp/stop_reminder_shown"
  }
}
JSON
