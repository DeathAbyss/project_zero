---
name: sdd-archive
description: |
  Fecha uma change de SDD: verifica o gate da harness, compacta os
  artefatos num recap breve em .claude/changes/archive/<nome>.md, e apaga
  o change-dir transitório. Recap-only — não mantém os arquivos de propose.

  Triggers manuais: "arquiva a change X", "fecha o SDD de Y", "compacta
  a change", "/sdd-archive", "terminei a feature, pode arquivar".

  NÃO usa pra: criar change (sdd-propose); implementar / rodar o gate
  (sdd-apply faz ambos — o gate roda na cauda da implementação); pular o
  gate (o hook bloqueia archive sem os 4 vereditos).
---

# sdd-archive

Compacta uma change concluída em recap breve e remove o transitório.

> Estrutura: [`.claude/changes/README.md`](../../changes/README.md).
> Gate e vereditos: [`.claude/docs/05-harness.md`](../../docs/05-harness.md).

## Pré-condição (gate duro)

Antes de qualquer escrita em `archive/`, os 4 vereditos em
`.claude/changes/<nome>/harness/` precisam existir com status {PASS, N/A}:
`security.md`, `tests.md`, `data-protection.md`, `code-review.md`.

Se faltar veredito ou algum estiver `BLOCKED`, o hook
[`check-harness-gate.sh`](../../hooks/check-harness-gate.sh) **bloqueia** a
escrita do recap. Não tente contornar — o gate é responsabilidade do
`sdd-apply` (que o roda na cauda da implementação). Veredito faltando ou
`BLOCKED` → volta pro `sdd-apply` resolver os achados antes de arquivar.

## Workflow

1. **Seleciona a change** — nome dado, ou infere do contexto, ou lista
   `.claude/changes/*/` e pergunta.
2. **Confere o gate** — lê os 4 arquivos `harness/` (já gravados pelo
   `sdd-apply`, que roda o gate na cauda da implementação). **Não despacha
   agente.** Algum faltando/`BLOCKED` → para e reporta que o gate não
   fechou; manda voltar pro `sdd-apply` resolver. Não arquiva.
3. **Gera o recap** — lê proposal/design/tasks/harness e escreve
   `archive/<nome>.md` BREVE (formato abaixo). Foco no que foi FEITO, não
   no que se planejou.
4. **Apaga o change-dir** — `rm -rf .claude/changes/<nome>/`. Recap +
   git são o histórico; o transitório não fica.
5. **Reporta** — "arquivada em `archive/<nome>.md`, change-dir removido."

## Formato do recap (breve)

```markdown
## <nome-da-change> — <YYYY-MM-DD>
<1-2 frases: o que foi entregue.>
Harness: seg <✓|N/A> · testes <✓|N/A, o que rodou> · dados <✓|N/A, base legal> · review <✓>
Ripple aplicado: <notas cross-cutting que viraram ação, se houver>
Deferido: <nits/opcionais não corrigidos, se houver>
```

## Regras

- **Recap-only.** Não preserva proposal/design/tasks. Resume e descarta.
- **Breve de verdade.** O recap é GPS, não relatório. 4-8 linhas.
- **Não arquiva com gate incompleto.** Sem exceção — é o ponto de
  enforcement do sistema.
- **rm é só do change-dir alvo.** Nunca toca outras changes nem o archive.
