---
name: sdd-apply
description: |
  Aplica as tasks de uma change SDD do project_zero. Lê tasks.md, despacha
  obrigatoriamente o agente certo por task (dev pra código, escriba pra
  doc), marca cada `- [ ]` como `- [x]` ao concluir, e AO FIM dispara o
  gate harness (3 agentes + code-review) com fix loop. Implementa + fecha o gate.

  Triggers manuais: "aplica a change X", "implementa as tasks de Y",
  "/sdd-apply", "executa o tasks.md", "continua a implementação de Z".

  NÃO usa pra: criar a change (sdd-propose); arquivar / gerar recap
  (sdd-archive — que só confere os vereditos, não roda o gate); decidir
  escopo (volta pro usuário); mudança trivial sem change-dir (faz direto).
---

# sdd-apply

Executa o `tasks.md` de uma change. Despacha agentes (obrigatório), marca
progresso, e ao fim roda o gate harness com fix loop. Não arquiva — recap +
rm é do `sdd-archive`.

> Lifecycle: [`.claude/changes/README.md`](../../changes/README.md).
> Briefing entre agentes: [`.claude/docs/CONVENTIONS.md`](../../docs/CONVENTIONS.md).
> Gate harness: [`.claude/docs/05-harness.md`](../../docs/05-harness.md).

## Workflow

1. **Seleciona a change** — nome dado, ou infere do contexto, ou lista
   `.claude/changes/*/` e pergunta. Anuncia: "Aplicando: <nome>".
2. **Lê o contexto** — `proposal.md`, `tasks.md`, e `design.md` se existir.
   Entende deps e ordem antes de começar.
3. **Mostra progresso** — "N/M tasks concluídas" + tasks restantes.
4. **Executa (paralelo por default)** — monta o grafo de deps e despacha
   (ver "Paralelismo" abaixo): ramos independentes em paralelo, cadeias
   dependentes serializadas pela task list. Cada worker:
   - Anuncia a task que pegou.
   - Aplica a mudança com briefing mastigado; escopo mínimo.
   - Marca `- [ ]` → `- [x]` no tasks.md **assim que conclui**.
   - Self-claim a próxima task unblocked.
5. **Para quando** — task ambígua (pergunta), implementação revela falha
   de design (sugere atualizar design.md/proposal.md), erro/bloqueio
   (reporta e espera). Não chuta.
6. **Auto-dispara o gate harness** — terminadas TODAS as tasks de
   implementação, roda o gate na hora (não espera o usuário pedir). Ver
   "Gate harness (cauda do apply)" abaixo. Aguarda os 4 vereditos.
7. **Fix loop** — achado obrigatório/`CRÍTICO` → corrige e re-roda (cap=2).
   Ver "Fix loop" abaixo.
8. **Ao terminar** — 4 vereditos {PASS, N/A} → marca a linha de gate do
   `tasks.md` como `- [x]` e reporta: "tasks + gate fechados; rode
   `sdd-archive`".

## Agentes (obrigatório chamar)

Dispatch é **obrigatório** (mandatório-triado): a skill DELEGA o trabalho ao
agente certo — o principal não absorve inline. Sempre spawna o worker
designado pelo tipo da task. (A trivialidade filtra na ENTRADA do SDD;
dentro da skill, delega sempre — ver fronteira em
[`03-multiagent.md`](../../docs/03-multiagent.md).)

| Task mexe em | Worker | Papel |
|---|---|---|
| código de produção | `dev` (ou `worker` no lean) | implementa o código da task |
| doc / project_map / CLAUDE.md | `escriba` (ou `worker`) | atualiza doc após a mudança |
| investigação antes de implementar | `analista` (ou `worker`) | mapeia read-only, devolve briefing |

**Escriba + sync-project-map.** Quando tasks de `dev` alteram código de
produção, o briefing do `escriba` inclui chamar a skill `sync-project-map`
pra atualizar refs `file:line` em `.claude/docs/project_map/`. O hook
`check-sync-project-map.sh` dispara reminder automático se o drift não for
resolvido, mas a responsabilidade primária é do `escriba` no apply.

Mecanismo: teammates paralelos quando há ramos independentes (default);
1 subagent quando o grafo é trivial (1 task). Ver "Paralelismo" abaixo.

## Paralelismo (default — via task list com deps)

O default é **decompor e paralelizar**, não rodar em fila. Deps no
tasks.md forçam ORDEM, não serialização total — o grafo quase sempre tem
ramos independentes que rodam juntos. Modelo (Agent Teams nativo):

```
1. parseia o grafo de deps do tasks.md (o que depende do quê)
2. cria as tasks na task list compartilhada COM as deps marcadas
3. spawna N workers (dev/escriba conforme o tipo de cada task)
4. cada worker self-claim a próxima task UNBLOCKED:
     ├─ ramos independentes  → rodam em paralelo
     └─ cadeias dependentes  → serializam sozinhas (a task list
                                bloqueia task com dep não resolvida)
5. aguarda todas concluírem; sintetiza
```

Exemplo (grafo deste próprio fluxo): `T1,T2,T3` independentes → 3 workers
em paralelo; `T4` depende de `T3` → a task list segura T4 até T3 fechar.

Sequencial é o **caso degenerado** (grafo linear, ou tudo no mesmo
arquivo), não o ponto de partida. Ver dimensão de paralelismo em
[`03-multiagent.md`](../../docs/03-multiagent.md).

### O que força colapsar um ramo pro sequencial

- **Mesma unidade / mesmo arquivo** — 2 tasks editam o mesmo arquivo →
  serializa as duas (Agent Teams sobrescreve em edição paralela), ou
  divide por arquivo se der.
- **Dep real** — task B usa output de A → a task list já serializa via
  dependência marcada. Não precisa forçar à mão.
- **1 task só** — grafo trivial → 1 subagent, sem montar time.

## Gate harness (cauda do apply)

Terminadas as tasks, a skill dispara o gate — descrição **operacional** aqui
(conceito, formato de veredito e severidade em
[`05-harness.md`](../../docs/05-harness.md)):

```
spawn teammate "seguranca"       ┐
spawn teammate "testes"          ├─ paralelos; cada um grava harness/*.md
spawn teammate "protecao-dados"  ┘  (security.md / tests.md / data-protection.md)
aguarda os 3 TeammateIdle (hook check-teammate-verdict bloqueia idle sem veredito)
→ o sdd-apply roda a skill code-review-and-quality (4ª perspectiva → code-review.md)
→ confere os 4 vereditos
```

Cada teammate recebe briefing mastigado (diff/`file:line`, change-dir,
contexto da feature) e manda SendMessage ao lead com 1 linha de sumário.
Fallback: sem Agent Teams, despacha os 3 como subagents sequenciais — gate
funciona igual, só mais lento.

## Fix loop (cap=2)

Veredito com achado obrigatório/`CRÍTICO` dispara o loop, dirigido pela skill
(os workers dev já estão spawnados):

```
fix mecânico óbvio   → FULL-AUTO: despacha dev, re-roda o gate
decisão de ESCOPO    → checkpoint humano (não decide sozinho)
nit / opcional       → deferido (anota no recap, não corrige)
```

- **Cap = 2 voltas.** Após 2 ciclos fix→re-gate sem limpar, para e chama o
  humano. Não insiste (loop sem freio thrasha).
- Severidade e o que dispara fix: [`05-harness.md`](../../docs/05-harness.md)
  ("Severidade", "Ciclo de fix automático"). Não duplica aqui.

## Regras

- **Marca progresso na hora.** `- [x]` imediatamente após cada task —
  não acumula pra marcar tudo no fim (perde rastro se interromper).
- **Escopo mínimo por task.** Não implementa task futura "de quebra".
- **Roda o gate, não arquiva.** O gate é a cauda do apply; recap + rm do
  change-dir é do `sdd-archive`.
- **Não commita.** Regra global de git — usuário commita manual.
- **Para em ambiguidade.** Task vaga → pergunta. Não inventa comportamento.
