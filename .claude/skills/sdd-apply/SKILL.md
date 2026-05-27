---
name: sdd-apply
description: |
  Aplica as tasks de uma change SDD do project_zero. Lê tasks.md, despacha
  o agente certo por task (dev pra código, escriba pra doc), marca cada
  `- [ ]` como `- [x]` ao concluir. Etapa entre sdd-propose e o gate/archive.

  Triggers manuais: "aplica a change X", "implementa as tasks de Y",
  "/sdd-apply", "executa o tasks.md", "continua a implementação de Z".

  NÃO usa pra: criar a change (sdd-propose); rodar o gate / arquivar
  (sdd-archive faz o gate harness); decidir escopo (volta pro usuário);
  mudança trivial sem change-dir (faz direto).
---

# sdd-apply

Executa o `tasks.md` de uma change. Despacha agentes, marca progresso,
para quando trava. Não gerencia o gate — isso é do `sdd-archive`.

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
6. **Ao terminar** — todas as tasks de implementação marcadas → reporta e
   aponta o gate: "tasks aplicadas; rode o gate harness e depois
   `sdd-archive`". A task de gate no fim do tasks.md NÃO é do sdd-apply.

## Roteamento de agente por task

| Task mexe em | Worker |
|---|---|
| código de produção | agente `dev` (ou `worker` no profile lean) |
| doc / project_map / CLAUDE.md | agente `escriba` (ou `worker`) |
| investigação antes de implementar | agente `analista` (ou `worker`) |

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

## Regras

- **Marca progresso na hora.** `- [x]` imediatamente após cada task —
  não acumula pra marcar tudo no fim (perde rastro se interromper).
- **Escopo mínimo por task.** Não implementa task futura "de quebra".
- **Não roda o gate.** sdd-apply só implementa. Gate + archive é outra skill.
- **Não commita.** Regra global de git — usuário commita manual.
- **Para em ambiguidade.** Task vaga → pergunta. Não inventa comportamento.
