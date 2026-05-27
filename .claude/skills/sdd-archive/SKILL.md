---
name: sdd-archive
description: |
  Fecha uma change de SDD: verifica o gate da harness, compacta os
  artefatos num recap breve em .claude/changes/archive/<nome>.md, e apaga
  o change-dir transitório. Recap-only — não mantém os arquivos de propose.

  Triggers manuais: "arquiva a change X", "fecha o SDD de Y", "compacta
  a change", "/sdd-archive", "terminei a feature, pode arquivar".

  NÃO usa pra: criar change (sdd-propose); implementar (dev/worker);
  pular o gate (o hook bloqueia archive sem os 4 vereditos).
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
escrita do recap. Não tente contornar — resolve o gate primeiro (roda os
agentes faltantes / corrige os achados / justifica N/A).

## Gate paralelo (Agent Team)

Os 3 agentes de harness gravam em arquivos disjuntos (`security.md`,
`tests.md`, `data-protection.md`) — zero conflito. Rode-os como **teammates
paralelos** em vez de subagents sequenciais (~3x mais rápido):

```
spawn teammate "seguranca"       ┐
spawn teammate "testes"          ├─ simultâneos, cada um grava seu harness/*.md
spawn teammate "protecao-dados"  ┘
aguarda os 3 TeamateIdle (hook check-teammate-verdict bloqueia idle
  sem o arquivo de veredito gravado)
→ principal roda a skill code-review-and-quality (4ª perspectiva)
→ confere o gate (abaixo)
```

Cada teammate recebe briefing mastigado: o diff/`file:line`, o change-dir,
o contexto da feature. Cada um envia SendMessage ao lead com 1 linha de
sumário ao concluir. Fallback: se Agent Teams indisponível, despacha os 3
como subagents sequenciais — o gate funciona igual, só mais lento.

## Workflow

1. **Seleciona a change** — nome dado, ou infere do contexto, ou lista
   `.claude/changes/*/` e pergunta.
2. **Roda o gate** — despacha os 3 agentes de harness em paralelo (acima)
   + a skill code-review-and-quality. Aguarda os 4 vereditos.
3. **Confere o gate** — lê os 4 arquivos `harness/`. Algum faltando/BLOCKED
   → para e reporta o que falta. Não arquiva.
4. **Gera o recap** — lê proposal/design/tasks/harness e escreve
   `archive/<nome>.md` BREVE (formato abaixo). Foco no que foi FEITO, não
   no que se planejou.
5. **Apaga o change-dir** — `rm -rf .claude/changes/<nome>/`. Recap +
   git são o histórico; o transitório não fica.
6. **Reporta** — "arquivada em `archive/<nome>.md`, change-dir removido."

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
