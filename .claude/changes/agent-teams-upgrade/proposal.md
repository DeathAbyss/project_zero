# Proposal — agent-teams-upgrade

## Por que

project_zero tem 6 agentes funcionando como subagents sequenciais. Agent
Teams (já ativado em settings.json) permite rodar agentes como teammates
paralelos com comunicação direta — o harness gate hoje despacha 3 agentes
um por vez; com teammates roda em paralelo (~3x mais rápido). Além disso,
o `operador` foi concebido com uma restrição ("sub-agente não invoca
sub-agente") que não existe mais no modelo de Agent Teams.

## O que muda

- **NOVO** skill `sdd-apply` — aplica tasks do tasks.md; preenche lacuna
  entre propose e archive.
- `sdd-archive` — despacha harness gate como 3 teammates paralelos em vez
  de 3 subagents sequenciais.
- `sdd-explore` — usa teammates paralelos (analista + architect) para
  coleta simultânea em vez de subagents sequenciais.
- `operador.md` — vira orquestrador: pode usar SendMessage pra coordenar
  teammates além de só devolver plano ao principal.
- Todos os 6 agentes — seção "Quando teammate" documentando padrão
  SendMessage (disponível automaticamente, mas não documentado).
- Hooks Agent Teams — `TeammateIdle`, `TaskCreated`, `TaskCompleted` em
  settings.json para quality gates específicos do model de times.
- `setup-global.sh` — copia sdd-apply + agentes atualizados.
- **Consistência** (ampliação pós-exploração): doutrina (`03-multiagent.md`,
  `05-harness.md`) alinhada a Agent Teams; edições de agente portadas pro
  source-of-truth `agent-profiles/` (estavam só na cópia efêmera
  `.claude/agents/`); `architect`/`worker` do lean ganham seção teammate.

> Backlog (change separado, não entra aqui): `cost-report` não capta custo
> de teammate (#4); raiz da duplicação — harness agents replicados em N
> profiles (avaliar `_shared/` em vez de cópia flat).

## Impacto

- Código/áreas afetadas:
  - `.claude/agents/*.md` — todos os 6 agentes
  - `.claude/skills/sdd-archive/SKILL.md`
  - `.claude/skills/sdd-explore/SKILL.md`
  - `.claude/skills/sdd-apply/SKILL.md` (novo)
  - `setup-global.sh`
  - `~/.claude/settings.json` (hooks Agent Teams)
- APIs/contratos: nenhuma mudança de contrato público; harness gate
  continua gravando os mesmos arquivos de veredito.
- Dependências: requer `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "1"` (já
  ativo) e Claude Code v2.1.32+ (já em uso).
- Dado pessoal envolvido? **não**
