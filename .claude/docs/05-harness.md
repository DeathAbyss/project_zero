# Harness de verificação (SDD + gate)

Toda mudança de código passa por um **gate** antes de fechar. O gate
roda 4 perspectivas de verificação, acha problemas, e — quando o fix é
mecânico — o principal corrige em loop automático. Objetivo: implementação
nova não degrada segurança, testes nem proteção de dados sem alguém ver.

> Doutrina geral de multiagente (Camadas 1/2, briefing mastigado) em
> [`03-multiagent.md`](03-multiagent.md). Este doc foca no **gate de
> verificação** e no **ciclo de fix**.

## Lifecycle SDD

```text
[explore] → propose → design → tasks → implementa → [ HARNESS GATE ↻ ] → archive
```

- `explore` (opcional): skill [`sdd-explore`](../skills/sdd-explore/SKILL.md). Coleta info e enquadra decisões pro usuário (não decide). Ideia clara pula.
- `propose/design/tasks`: skill [`sdd-propose`](../skills/sdd-propose/SKILL.md). Artefatos transitórios em `.claude/changes/<nome>/`.
- `implementa + HARNESS GATE`: skill [`sdd-apply`](../skills/sdd-apply/SKILL.md). Implementa as tasks **e**, na cauda, auto-dispara o gate (as 4 perspectivas abaixo) — o gate é o ato de fechamento da implementação, não da arquivação. O fix loop também roda aqui.
- `archive`: skill [`sdd-archive`](../skills/sdd-archive/SKILL.md). **Só confere** os 4 vereditos (o gate já rodou no apply), compacta tudo em recap breve, apaga o change-dir. **Recap-only — sem living-spec.**

## As 4 perspectivas do gate

| Perspectiva | Quem | Eixo primário | Roda? |
|---|---|---|---|
| Segurança | agente `seguranca` | vuln, authz, input, segredo | sim (npm audit/etc) + opina |
| Testes | agente `testes` | cobertura, suíte verde | sim (pytest/jest/go test/etc) + opina |
| Proteção de dados | agente `protecao-dados` | base legal, minimização, retenção | opina (config de jurisdição) |
| Qualidade | skill `code-review-and-quality` | correção, legibilidade, arquitetura, perf | `sdd-apply` roda a skill no gate |

Os 3 agentes são **sempre presentes** (entram em qualquer profile). A
4ª perspectiva é a skill, rodada pelo `sdd-apply` — não é agente.

Cada perspectiva grava seu veredito em `.claude/changes/<nome>/harness/`:
`security.md`, `tests.md`, `data-protection.md`, `code-review.md`.

## Execução do gate (paralela via Agent Teams)

Quem dispara o gate é a skill [`sdd-apply`](../skills/sdd-apply/SKILL.md),
na cauda da implementação — o detalhe operacional ("como spawnar") vive lá.
Aqui fica o conceito.

Os 3 agentes gravam em arquivos disjuntos → zero conflito → rodam em
**paralelo como teammates** (~3x mais rápido que sequencial):

```text
spawn teammate seguranca       ┐
spawn teammate testes          ├─ simultâneos; cada um grava seu harness/*.md
spawn teammate protecao-dados  ┘  e manda SendMessage ao lead com 1 linha
aguarda os 3 TeammateIdle
→ sdd-apply roda a skill code-review-and-quality (4ª perspectiva)
→ confere os 4 vereditos (gate abaixo)
```

- O hook `TeammateIdle` ([`check-teammate-verdict.sh`](../hooks/check-teammate-verdict.sh))
  bloqueia o encerramento de um agente de harness que não gravou seu
  veredito — garante que nenhum teammate fica idle sem fechar sua parte.
- **Fallback**: sem Agent Teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`
  desligado, ou agente não-Claude), `sdd-apply` não auto-spawna; o gate
  vira checklist manual nos arquivos `harness/` e o hook ainda bloqueia o
  archive. O gate funciona igual — só sem o paralelismo. Ver dimensão
  subagent-vs-teammate em [`03-multiagent.md`](03-multiagent.md).

Detalhe operacional do dispatch na skill [`sdd-apply`](../skills/sdd-apply/SKILL.md).

## Mandatório-triado

O gate **sempre dispara** as 4 perspectivas. Não significa análise pesada
em mudança trivial — significa que cada perspectiva responde, e a resposta
pode ser `N/A` com justificativa.

```text
toca dado pessoal?      não → data-protection: Status N/A + porquê
superfície de ataque?   não → seguranca: Status N/A + porquê
muda comportamento?     não → testes: Status N/A + porquê
```

Triagem é a primeira ação de cada agente. Profundidade proporcional ao
risco. `N/A + justificativa` é veredito válido — o gate libera.

## Veredito (formato canônico)

Cada arquivo em `harness/` começa com frontmatter de status:

```markdown
---
perspective: seguranca
status: PASS | N/A | BLOCKED
---

## Triagem
<por que esta profundidade — 1 frase>

## Achados
- <SEVERIDADE>: <problema> — evidência: `path/file.ext:linha`
  Fix briefing: <prompt file:line pro dev corrigir>
- RIPPLE: <efeito em outra camada — DB/front/DevOps/etc>

## Veredito
<PASS: limpo | N/A: não se aplica porque X | BLOCKED: críticos pendentes>
```

Status:
- `PASS` — verificado, sem problema obrigatório aberto.
- `N/A` — triado pra fora, com justificativa.
- `BLOCKED` — tem problema obrigatório/crítico não resolvido.

Gate libera archive **só** com os 4 status ∈ {PASS, N/A}. Qualquer
`BLOCKED` trava (hook [`check-harness-gate.sh`](../hooks/check-harness-gate.sh)).

## Severidade (reusa taxonomia do code-review)

| Prefixo | Dispara loop de fix? |
|---|---|
| `CRÍTICO` | sim — sempre |
| (sem prefixo) obrigatório | sim |
| `RIPPLE` | não dispara fix aqui; vira nota pro recap/planejador |
| `Nit:` / `Opcional:` | não — vira "deferido" no recap |
| `FYI` | não |

## Ripple cross-cutting

Cada agente opina **além do que roda**. Funcionalidade nova no backend
costuma respingar:

| Mudança | Ripple que o agente reporta |
|---|---|
| Endpoint novo | `seguranca`: rate-limit/authz no DevOps |
| Muda contrato de API | `testes`: teste de integração no front |
| Passa a guardar PII | `protecao-dados`: cripto-at-rest + retenção no DB |

Ripple **não** dispara fix automático — vira nota pro planejador decidir
escopo, e entra no recap do archive.

Impacto puramente arquitetural (ex: "quebra contrato pro mobile") **não**
é do harness — fica com o planejador (`operador`/`architect`) e a skill
`code-review`.

## Ciclo de fix automático

O loop de fix roda **dentro de `sdd-apply`** (a mesma skill que disparou
o gate) — os workers dev já estão spawnados ali, então achado → fix →
re-gate fica na mesma skill, sem repassar contexto pro archive. O agente
de harness só acha e devolve briefing, nunca corrige a si mesmo. Ver
[`03-multiagent.md`](03-multiagent.md):

```text
sdd-apply dispara o gate
   │
   ▼
agente acha problema → devolve {achado + fix briefing file:line}
   │
   ▼
sdd-apply classifica:
   ├─ CRÍTICO/obrigatório + fix mecânico óbvio → FULL-AUTO: despacha dev, re-roda harness
   ├─ decisão de ESCOPO → CHECKPOINT humano (não decide sozinho)
   └─ nit/opcional → deferido (anota no recap, não corrige)
```

### Freio do loop

- **Cap = 2 voltas.** Após 2 ciclos fix→re-harness sem limpar, **para e
  chama o humano**. Não insiste — loop sem freio thrasha (anti-padrão de
  [`02-token-efficiency.md`](02-token-efficiency.md)).
- **Checkpoint humano** dispara quando: aparece decisão de escopo, OU
  estoura o cap, OU o fix de um problema cria problema novo na volta seguinte.
- Full-auto só pra fix **mecânico** (severidade alta + correção óbvia,
  ex: parametrizar query, sanitizar input, adicionar teste faltante).
  Fix que exige decisão de design não é mecânico → checkpoint.

## Enforcement

- O gate **roda no `sdd-apply`** (cauda da implementação). O hook
  `PreToolUse` ([`check-harness-gate.sh`](../hooks/check-harness-gate.sh))
  é a **rede de segurança no archive**: bloqueia escrita em
  `.claude/changes/archive/` enquanto os 4 vereditos não forem
  {PASS, N/A}. Pega o caso de o apply ter pulado o gate — não é onde o
  gate roda, é onde se garante que rodou.
- Em agente não-Claude (Cursor/Cline/etc.) sem auto-despacho: `sdd-apply`
  não auto-spawna; o gate vira checklist manual nos arquivos `harness/` +
  o hook ainda bloqueia o archive. Perde o loop automático, mantém a
  obrigatoriedade.

## Config

Jurisdição e baselines em [`.claude/harness.config`](../../harness.config)
(template `harness.config.template`). Agentes leem sob demanda — não infla
contexto por turno.

## Quando o gate NÃO se aplica

- Mudança só em doc/markdown sem efeito runtime → as 4 perspectivas
  respondem `N/A` rápido (a triagem é barata).
- Sem change-dir aberto (mudança fora do fluxo SDD) → gate não dispara;
  o checklist [`04-task-closure.md`](04-task-closure.md) ainda vale.
