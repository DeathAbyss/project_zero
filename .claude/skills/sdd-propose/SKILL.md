---
name: sdd-propose
description: |
  Cria uma change de spec-driven development no project_zero. Gera os
  artefatos (proposal, design opcional, tasks) em .claude/changes/<nome>/
  a partir de uma descrição. SDD próprio recap-only — sem CLI externa,
  sem living-spec.

  Triggers manuais: "propõe a change X", "abre uma change pra Y",
  "monta o SDD de Z", "/sdd-propose", "quero começar a feature W".

  NÃO usa pra: implementar (depois do propose, dev/worker pega tasks.md);
  fechar/arquivar (skill sdd-archive); mudança trivial de 1-2 linhas
  (não vale o overhead de SDD — faz direto).
---

# sdd-propose

Cria a change e seus artefatos num passo. Fluxo leve, sem dependência
externa.

> Estrutura e regras: [`.claude/changes/README.md`](../../changes/README.md).
> Gate de verificação: [`.claude/docs/05-harness.md`](../../docs/05-harness.md).

## Workflow

> Se veio de [`sdd-explore`](../sdd-explore/SKILL.md), use o dossiê +
> decisões do usuário como insumo direto — não re-investiga o que o
> explore já coletou.

1. **Nome** — deriva kebab-case da descrição ("adicionar export de
   usuário" → `add-user-export`). Se a change já existe, pergunta:
   continua ou cria nova.
2. **Cria o change-dir** — `.claude/changes/<nome>/` + subpasta `harness/`.
3. **proposal.md** — copia de `_templates/proposal.md` e preenche: por quê,
   o que muda, impacto. **Campo crítico**: "dado pessoal envolvido?" —
   alimenta a triagem do gate depois.
4. **design.md (condicional)** — cria SÓ se: cross-cutting, dependência
   nova, ou trade-off não-óbvio. Mudança simples pula.
5. **tasks.md** — copia de `_templates/tasks.md`. Quebra em tarefas
   pequenas verificáveis `- [ ]`, ordenadas por dependência. Mantém a
   tarefa de gate no fim.
6. **Reporta** — lista artefatos criados + "pronto pra implementar: pega
   `tasks.md`. Ao fechar, roda `sdd-apply`."

## Regras

- **Não cria design por padrão.** Default é proposal + tasks. Design é
  exceção justificada.
- **Não implementa.** Propose só gera os artefatos. Implementação é etapa
  seguinte (dev/worker).
- **Não infla.** Proposal 1 página, tasks pequenas. Detalhe de "como" vai
  pro design só quando vale.
- **Cria a subpasta `harness/` vazia** — sinaliza que o gate vai preenchê-la.
