# changes/ — SDD próprio (recap-only)

Fluxo de spec-driven development do project_zero. Leve, sem CLI externa,
sem living-spec: artefatos são **transitórios** e colapsam num recap breve
no archive.

> Doutrina do gate de verificação: [`../docs/05-harness.md`](../docs/05-harness.md).
> Skills: [`sdd-explore`](../skills/sdd-explore/SKILL.md) explora (opcional),
> [`sdd-propose`](../skills/sdd-propose/SKILL.md) cria, [`sdd-archive`](../skills/sdd-archive/SKILL.md) fecha.

## Lifecycle

```text
[explore] → propose → design → tasks → implementa → [ harness gate ] → archive
```

`explore` é opcional: para ideia vaga, `sdd-explore` coleta info e enquadra
as decisões pro usuário (não decide). Mudança clara pula direto pro propose.

## Estrutura

```text
changes/
├── _templates/              esqueletos (não editar; copiar)
│   ├── proposal.md
│   ├── design.md
│   ├── tasks.md
│   └── harness-verdict.md
├── <nome-da-change>/        ATIVA — transitória, apagada no archive
│   ├── proposal.md          por que + o que
│   ├── design.md            como (só se não-trivial)
│   ├── tasks.md             checklist `- [ ]`
│   └── harness/             vereditos do gate
│       ├── security.md
│       ├── tests.md
│       ├── data-protection.md
│       └── code-review.md
└── archive/                 DURÁVEL — recap breve por change
    └── <nome-da-change>.md
```

## Regras

1. **Nome em kebab-case**: `add-user-export`, `fix-auth-leak`.
2. **`design.md` é opcional** — só pra mudança cross-cutting, dependência
   nova, ou trade-off não-óbvio. Mudança simples pula direto pra `tasks.md`.
3. **Gate obrigatório-triado**: os 4 vereditos em `harness/` precisam
   existir com status {PASS, N/A} antes do archive. Hook
   [`check-harness-gate.sh`](../hooks/check-harness-gate.sh) bloqueia senão.
4. **Archive compacta**: `sdd-archive` resume tudo em
   `archive/<nome>.md` (recap breve) e **apaga o change-dir**. Sem
   living-spec — o histórico de "o que foi feito" vive no recap + git.
5. **Change-dir é transitório**: não acumula. Se uma change ficou parada,
   ou retoma ou apaga — não vira lixo.
