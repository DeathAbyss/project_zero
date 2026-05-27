# Tasks — agent-teams-upgrade

> Checkbox `- [ ]` é parseado pra progresso. Tarefa fora desse formato
> não é rastreada. Ordena por dependência.

## 1. Nova skill sdd-apply

- [x] 1.1 Criar `.claude/skills/sdd-apply/SKILL.md` — lê tasks.md,
  despacha agentes corretos por task (dev→código, escriba→doc), marca
  `- [x]` ao concluir cada task, não gerencia gate (isso é sdd-archive)

## 2. operador → orquestrador

- [x] 2.1 Atualizar `.claude/agents/operador.md` — adicionar modo
  "orquestrador de teammates": quando spawnado como teammate, usa
  SendMessage + task list pra coordenar; modo subagent mantido (devolve
  plano ao principal). Remover linguagem de "limitação técnica" (virou
  decisão de design)

## 3. Padrão SendMessage em todos os agentes

- [x] 3.1 Adicionar seção "Quando usado como teammate" em `analista.md`
  — SendMessage ao lead ao concluir/bloquear
- [x] 3.2 Adicionar seção "Quando usado como teammate" em `dev.md`
- [x] 3.3 Adicionar seção "Quando usado como teammate" em `escriba.md`
- [x] 3.4 Atualizar `seguranca.md` — seção teammate + instrução de
  SendMessage com sumário de veredito (1 linha PASS/N/A/BLOCKED) ao
  gravar harness/security.md
- [x] 3.5 Atualizar `testes.md` — mesmo padrão, harness/tests.md
- [x] 3.6 Atualizar `protecao-dados.md` — mesmo padrão,
  harness/data-protection.md

## 4. Skills: harness e explore em paralelo

- [x] 4.1 Atualizar `.claude/skills/sdd-archive/SKILL.md` — step do
  gate despacha `seguranca`, `testes`, `protecao-dados` como 3 teammates
  paralelos em vez de 3 subagents sequenciais; aguarda 3 TeamateIdle;
  code-review skill continua após os 3 terminarem
- [x] 4.2 Atualizar `.claude/skills/sdd-explore/SKILL.md` — despacha
  `analista` e `architect` como teammates paralelos; cada um envia
  SendMessage ao lead com achados; lead compila dossiê com inputs
  de ambos

## 5. Hooks Agent Teams

- [x] 5.1 Criar `.claude/hooks/check-teammate-verdict.sh` — hook para
  `TeammateIdle`: se o teammate é agente de harness, verifica que
  gravou o arquivo de veredito correspondente antes de ficar idle;
  exit 2 se não encontrou (bloqueia idle e envia feedback)
- [x] 5.2 Atualizar `setup-global.sh` para registrar `TeammateIdle`
  hook no settings.json via node (mesmo padrão idempotente já existente)

## 6. Setup

- [x] 6.1 Atualizar `setup-global.sh` — copiar `sdd-apply/SKILL.md` +
  todos os agentes atualizados (T1-T3) + hook `check-teammate-verdict.sh`
  (skills loop e agents loop já genéricos; hook adicionado ao loop de cópia)

## 7. Doutrina alinhada a Agent Teams (consistência #1)

- [x] 7.1 `docs/03-multiagent.md` — reenquadra "sub-agente não despacha
  sub-agente" (era limite técnico, agora decisão de modo); adiciona a
  dimensão subagent-vs-teammate (quando paralelismo + comunicação
  justifica o custo N× de context window)
- [x] 7.2 `docs/05-harness.md` — documenta o gate paralelo (3 teammates)
  + hook `TeammateIdle`/`check-teammate-verdict.sh`; reenquadra a
  linguagem de loop só-sequencial

## 8. Source-of-truth dos agentes (consistência #2)

> T2+T3 editaram `.claude/agents/` — camada EFÊMERA (switch sobrescreve).
> Fonte real é `agent-profiles/<profile>/`. Portar pra lá.

- [x] 8.1 Portar edições T2+T3 pra `agent-profiles/fibonacci/` (operador,
  dev, analista, escriba, seguranca, testes, protecao-dados)
- [x] 8.2 Portar seção "Quando teammate" dos harness pra
  `agent-profiles/lean/` (seguranca, testes, protecao-dados)
- [x] 8.3 Re-sincronizar `.claude/agents/` rodando
  `switch-agents.sh fibonacci` (propaga fonte → cópia ativa) — verificado:
  8 seções teammate nos 7 agentes ativos

## 9. architect + worker (lean) como teammates (consistência #3)

- [x] 9.1 `agent-profiles/lean/architect.md` — modo orquestrador + seção
  "Quando teammate" + SendMessage (sdd-explore o spawna como teammate)
- [x] 9.2 `agent-profiles/lean/worker.md` — seção "Quando teammate"
  (worker é o implementador do lean; mesmo padrão do dev)

## 10. Inverter viés de paralelismo na doutrina

- [x] 10.1 `docs/03-multiagent.md` — vira "decompor + paralelizar por
  default; colapsa pra sequencial/single SÓ quando dep ou unidade-única
  força". Mantém o alerta de custo (paralelo quando HÁ o que paralelizar,
  não teammate cego pra tudo). Reescreve a regra de escolha e o "default
  é subagent".

## 11. sdd-apply paralelo (task-list com deps)

- [x] 11.1 `skills/sdd-apply/SKILL.md` — troca "sequencial default" por:
  parseia grafo de deps do tasks.md → cria tasks na task list com deps →
  spawna N workers → ramos independentes rodam paralelo, cadeias
  dependentes serializam sozinhas (task list bloqueia). Sequencial vira
  o caso degenerado (grafo linear), não o default.

## Gate (não marca como done até passar)

- [ ] harness: 4 vereditos {PASS, N/A} em `harness/`
