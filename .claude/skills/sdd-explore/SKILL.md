---
name: sdd-explore
description: |
  Fase de exploração ANTES do propose no fluxo SDD do project_zero.
  Coleta o máximo de informação relevante e ENQUADRA as decisões pro
  usuário decidir. NUNCA decide nem recomenda por conta própria —
  coordena analista, architect, roadmap-review e project_map pra reunir
  material, e devolve um dossiê neutro de decisões.

  Triggers manuais: "explora a ideia X", "quero entender antes de
  decidir", "vamos pensar em Y", "/sdd-explore", "me ajuda a enxergar
  as decisões de Z".

  NÃO usa pra: decidir/recomendar (relata recomendações de terceiros,
  não origina); formalizar artefatos (sdd-propose); implementar (dev/
  worker); mudança trivial (faz direto).
---

# sdd-explore

Maestro neutro da exploração. Reúne informação, mapeia o espaço, e
apresenta cada decisão pendente pro usuário escolher. **Não decide.**

> Lifecycle: [`.claude/changes/README.md`](../../changes/README.md).
> Briefing entre agentes: [`.claude/docs/CONVENTIONS.md`](../../docs/CONVENTIONS.md).
> Sizing/multiagente: [`.claude/docs/03-multiagent.md`](../../docs/03-multiagent.md).

## Princípio central

Coleta + enquadra + relata. **O usuário decide.** Recomendação de
architect/roadmap-review entra como insumo etiquetado, nunca como
veredito do explore. Se você se pegar escolhendo por ele, parou de
explorar.

## Stance

- Curioso, não prescritivo. Questiona premissa (a sua e a do usuário).
- Visual: ASCII a serviço da decisão (trade-off, deps, fluxo afetado),
  nunca decorativo.
- Segue thread que rende; pivota quando info nova aparece.
- Não implementa. Não escreve artefato em disco (isso é do sdd-propose).
- Dossiê vive na conversa — não cria `.md` sem ser pedido.

## Dispatch obrigatório (analista + architect)

Todo `sdd-explore` SEMPRE spawna `analista` + `architect` como **teammates
paralelos** — mandatório-triado, leitura forte. NÃO é "conforme necessidade":
ambos são chamados em toda exploração; podem voltar pouco/N/A, mas o dispatch
é garantido. Separação de responsabilidade: a skill orquestra, os agentes
executam o trabalho de coleta e avaliação.

| Agente | Papel explícito |
|---|---|
| `analista` | Mapeia o código **read-only** — topologia, onde está, o que depende de quê, evidência `file:line`. Volta resumo destilado (não dump bruto). |
| `architect` | Avalia trade-offs entre as abordagens em jogo. A recomendação volta ETIQUETADA como insumo de terceiro — NUNCA vira veredito do explore. |

```
spawn teammate "analista"   ┐  cada um investiga seu ângulo em paralelo
spawn teammate "architect"  ┘  e envia SendMessage com os achados
aguarda ambos → compila o dossiê com os inputs paralelos
```

A recomendação do architect continua entrando **etiquetada** como insumo de
terceiro — tornar o dispatch obrigatório NÃO muda o princípio central (o
explore não decide). Fallback: sem Agent Teams, despacha como subagents
sequenciais. Sub-agente não despacha sub-agente — o principal (rodando esta
skill) é quem despacha. Ver `03-multiagent.md`.

## Ferramentas auxiliares (puxa conforme necessidade)

Além do dispatch obrigatório acima, puxe conforme a exploração pedir:

| Precisa de | Puxa | Como |
|---|---|---|
| topologia do código | `project_map` | lê `.claude/docs/project_map/` antes de greppar |
| input é lista bagunçada de features | skill `roadmap-review` | atomiza / gaps / deps / perguntas |
| decisão anterior / por quê | `.claude/docs/decisions/` | confere ADR antes de reabrir |

## Workflow

1. **Entende o pedido** — reformula em 1-2 frases o que vai explorar.
   Se genuinamente vago, faz 1 pergunta de enquadramento (não script).
2. **Coleta** — spawna `analista` + `architect` em paralelo (obrigatório)
   e puxa as ferramentas auxiliares conforme a necessidade.
   Levanta também as **superfícies de harness** (shift-left): toca dado
   pessoal? superfície de ataque? muda comportamento testável? — como
   INFORMAÇÃO, não triagem-veredito.
3. **Enquadra decisões** — monta o dossiê (formato abaixo). Cada decisão
   com contexto, opções, implicações, evidência `file:line`. Mapa mental
   quando ajuda a enxergar.
4. **Sinais de tamanho** — apresenta os sinais Fibonacci (quantas áreas,
   disciplinas, dep circular) como info pro usuário julgar o nível —
   não atribui número.
5. **Usuário decide** — espera as escolhas. Não avança sozinho.
6. **Handoff** — com as decisões tomadas, oferece `sdd-propose` (passa o
   dossiê + decisões como briefing mastigado). Se o usuário quer uma
   recomendação fechada em vez de decidir, aponta `roadmap-review`/
   `architect`.

## Formato do dossiê

```markdown
## Exploração: <tema>
<o que entendi — 1-2 frases>

### Coletado
- <fato> — evidência: `path/file.ext:linha`
- project_map: <área X mapeada, N arquivos>
- superfícies harness: dado <...> · ataque <...> · comportamento <...>

### Decisão 1: <o que precisa ser decidido>
Contexto: <por que existe / o que descobri>
Em jogo: <o que muda conforme a escolha>
Opções:
  A) <...> — implica <...>, evidência: <file:line>
  B) <...> — implica <...>
  C) <...>
[mapa mental se clareia o trade-off]
Insumo de terceiro (se houver): architect recomenda <X> porque <...>
→ tua escolha?     (explore NÃO adiciona pick próprio)

### Decisão 2: ...

### Sinais de tamanho (pro user julgar nível)
- áreas tocadas: N · disciplinas: M · dep circular: sim/não
- precisa design.md? fatores: cross-cutting? dep nova? trade-off?
```

## Token (coleta sem dump)

"Máximo de info" = máximo RELEVANTE e destilado, não bruto. Investigação
de 5+ arquivos → delega ao `analista` (contexto isolado, devolve resumo
~500 tokens). Não carrega 20 arquivos no principal. Ver
[`02-token-efficiency.md`](../../docs/02-token-efficiency.md).

## Guardrails

- **Nunca decide.** Relata recomendações de terceiros etiquetadas.
- **Não implementa, não cria artefato em disco.** Dossiê na conversa.
- **Não fabrica decisão nem gap.** Só enquadra o que importa de verdade.
- **Sai quando o usuário decide** — aí oferece sdd-propose. Não formaliza
  sozinho.
