# Sub-agentes (multiagente)

Padrão de despacho do Claude Code. Cada sub-agente roda em **contexto
isolado** — investigação pesada não polui o principal, e cada um tem
sua especialidade.

## Regra fundamental

**Sub-agente NÃO pode invocar outro sub-agente.** Por isso o padrão de
subagent é hub-and-spoke — o principal é o único que despacha:

```text
usuario → principal → operador (planeja, devolve plano)
                       ↓
                 principal despacha:
                   dev / analista / escriba
                       ↓
                 cada um devolve resultado
                       ↓
                  principal consolida
```

Essa regra vale pro modelo **subagent** (`Agent()`). O **Agent Teams**
(modo experimental, `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) levanta a
restrição: teammates rodam em paralelo, se comunicam via SendMessage e
coordenam por uma task list compartilhada. Ver a dimensão subagent-vs-
teammate abaixo.

## Quem usar quando

Agentes do template em `.claude/agents/`:

| Agente | Quando despachar | Custo |
|---|---|---|
| `operador` (Opus) | Demanda multi-papel ou escopo vago. Devolve plano de despacho. | Alto — só pra task complexa |
| `dev` | Spec clara → produz código | Médio |
| `analista` | Investigação read-only, audit, causa raiz | Baixo (só lê) |
| `escriba` | Atualizar docs depois de mudança | Baixo |

## Camada 1 — filtro rápido (regra dura)

Antes de chamar `Agent()`, responda:

1. Precisa abrir 4+ arquivos? Sim → considera. 10+? Delega.
2. Tool results vão poluir contexto com lixo? Sim → delega.
3. 2+ investigações paralelas independentes? Sim → delega em paralelo.

Se 2 respostas forem "não", **faz direto** (sem Camada 2).
Se passar o filtro (delega), vai pra Camada 2.

## Camada 2 — receita por nível (Fibonacci)

Esta tabela define **QUAL time** montar. Escala não-linear (1, 2, 3, 5,
8) força decisão qualitativa: pergunta "isso é mais parecido com 3 ou
com 5?", não "isso é 4?".

| Nível | Sinal de entrada | Time | Custo estimado |
|---|---|---|---|
| **1** | 1 investigação OU 1 implementação focada, escopo claro, 1 área | 1 subagente (analista OU dev) | ~10k |
| **2** | Investigar antes de implementar, mesma área | analista → principal → dev | ~20k |
| **3** | 2+ áreas independentes, paralelizáveis | 2-3 subagentes em paralelo | ~30-40k |
| **5** | Escopo precisa decomposição, 3+ disciplinas envolvidas | operador planeja → principal despacha conforme plano | ~50-60k |
| **8** | Multi-papel + decisão de escopo + gates entre passos | operador com gates → cadeia + checkpoint humano em pontos críticos | ~70k+ |

### Regra anti-conservadora

- Classificou **entre 2 níveis**? Escolhe o **MENOR**. Subir "por
  garantia" infla custo sem ganho de qualidade.
- Default é descer, não subir. Sobre-orquestrar 1 task é pior que
  sub-orquestrar — o segundo se corrige rápido, o primeiro paga já.
- Se durante execução perceber que era nível maior, **re-classifica
  explicitamente** ("essa task é nível 5, não 2 — pivotando pra
  operador") em vez de bancar silenciosamente.

### Sinais de re-classificação durante execução

- Nível 1 vira 2 quando: a investigação encontrou que precisa editar.
- Nível 2 vira 3 quando: a edição vai tocar outra área independente.
- Nível 3 vira 5 quando: as áreas têm dependência que exige ordem.
- Nível 5 vira 8 quando: aparece decisão de escopo que precisa
  validação humana antes de seguir.

## Dimensão subagent vs teammate (Agent Teams)

Camadas 1/2 decidem SE delega e QUE time montar. Esta dimensão decide o
**mecanismo**: subagent (`Agent()`) ou teammate (Agent Team).

```
                 SUBAGENT                    TEAMMATE
                 ════════                    ════════
contexto         isolado, resultado          isolado, sessão própria
                 volta pro principal         independente
comunicação      só devolve no fim           SendMessage entre todos
                                             + ao lead, durante o trabalho
coordenação      principal orquestra tudo    task list compartilhada,
                                             self-claim, auto-coordenação
custo            1× boot por agente          N× context window (caro)
melhor pra       worker focado, resultado    paralelismo real +
                 importa, sem conversa       comunicação entre workers
```

### Default: decompõe e paraleliza

O viés é **decompor o trabalho e rodar em paralelo**. Sequencial e single
não são o ponto de partida — são o que sobra quando algo **força**:

```
pergunta antes de despachar:
  "dá pra quebrar isso em unidades independentes?"
        │
   ┌────┴────┐
  SIM        NÃO (1 unidade, ou cadeia de deps)
   │          │
   ▼          ▼
PARALELO   colapsa pra sequencial/single
(teammates  (caso degenerado, não default)
 ou subagent
 paralelo)
```

O que **força** colapsar pro sequencial/single (e só isso):

| Força | Resultado |
|---|---|
| 1 unidade de trabalho (fix de 1 linha, 1 grep) | single — principal faz direto |
| Cadeia de dependência (B precisa do output de A) | serializa só a aresta dependente; ramos paralelos seguem paralelos |
| Edição do MESMO arquivo por 2+ workers | serializa esses, ou divide por arquivo |

### Mecanismo: teammate vs subagent paralelo

Decidido que paraleliza, escolhe o mecanismo:

| Sinal | Mecanismo |
|---|---|
| Workers precisam conversar / coordenar / se desafiar durante o trabalho | **teammate** (SendMessage + task list) |
| Workers independentes, sem conversa, só resultado | **subagent paralelo** (`Agent()` no mesmo turno) — mais barato |
| Gate harness, explore multi-perspectiva, grafo de tasks | teammate paralelo |

**Alerta de custo (não é teammate cego):** teammate custa N× context
window. "Paralelizar por default" = paralelizar **quando há unidades
independentes de verdade** — não spawnar teammate pra trabalho que tem
1 unidade ou é cadeia pura. A doc do Agent Teams avisa: tarefa rotineira
de 1 unidade roda mais barato em sessão única. O default-paralelo é sobre
**topologia** (decompõe sempre que dá), não sobre forçar o mecanismo caro.

> Agentes que coordenam (`operador`/`architect`) têm modo orquestrador:
> como teammate, criam tasks e coordenam via SendMessage em vez de só
> devolver plano. Ver o body de cada agente.

## Quando NÃO usar sub-agente

- Edit de 1-2 linhas → principal faz direto.
- Pergunta isolada que cabe em 1 grep → principal faz direto.
- Tarefa já decomposta + escopo claro → pula o operador, vai direto
  pro dev.
- Verificação rápida pós-edit → principal usa Read.

Sub-agente tem boot cost. Vale quando o trade entrega ganho real de
contexto/especialização — não como hábito automático.

## Briefing mastigado

Todo `prompt` do `Agent()` deve levar paths com `file:line` quando
possível. Briefing vago força o agente a gastar 10-30k tokens na fase
de localização (Glob + Grep + Read exploratório) antes de chegar no
trabalho real.

> **Padrão canônico do briefing** (Objetivo / Paths relevantes /
> Constraints / Saída esperada) está em
> [`CONVENTIONS.md`](CONVENTIONS.md#padrão-do-briefing-entre-agentes).

**Padrão correto:**

```text
prompt: "Edita path/to/file.ext:67 trocando validateSync por
validateAsync. Constraint: respeitar refresh() em :120 que assume
retorno síncrono — adapta a chamada."
```

**Padrão errado:**

```text
prompt: "Implementa validação assíncrona"
```

**Quando o principal não sabe os paths ainda**: despache `analista`
primeiro com briefing genérico. Use o **"Briefing pronto pra próxima
etapa"** do output dele direto no prompt do dev/escriba. Isso amortiza
o custo do analista entre múltiplos agentes downstream.

**Paralelizar quando possível**: se o analista entregou paths de
código + paths de doc afetados, despache `dev` e `escriba` no MESMO
turno (`Agent()` em paralelo). Sem briefing mastigado, escriba teria
que esperar o dev — sequencial vira paralelo.

## Fallback: briefing em arquivo (só pra casos pesados)

Quando o briefing pra um agente passa de ~5k tokens (dump de schema,
log gigante, lista enorme de paths), em vez de inflar o `prompt`:

1. Salva em `.claude/tmp/briefing_<task-slug>.md` (gitignored).
2. No prompt: "Lê `.claude/tmp/briefing_<task-slug>.md` ANTES de
   começar. Contém contexto da task."
3. Próxima task sobrescreve o arquivo (não precisa limpar).

Use só pra briefing > 5k. Inline é mais barato pra briefing menor.

## Por que ajuda no token

- **Contexto isolado**: analista lê 10 arquivos, devolve resumo de
  500 tokens. O principal nunca carrega os 10 arquivos.
- **Especialização**: cada um tem system prompt focado, não precisa
  carregar regras gerais que o principal já tem.
- **Paralelização**: 2-3 sub-agentes podem rodar simultâneo em
  investigações independentes.

Trade-off: cada boot custa tokens. Pra task < 3 reads, **não vale**.
