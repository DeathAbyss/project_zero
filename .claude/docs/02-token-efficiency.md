# Eficiência de tokens

Token é orçamento. Cada mensagem do agente paga 100% do contexto
acumulado da sessão. Estas regras existem pra manter qualidade ao
mesmo tempo que reduzem custo — não são limites duros, são default.

> **Estilo de output do agente** (sem prefácio, sem emoji, etc.) vive
> em [`CONVENTIONS.md`](CONVENTIONS.md). Esta doc foca em **decisão de
> ferramentas + tamanho de payload**.

## Princípios

1. **Read parcial > Read inteiro.** Usa `offset`/`limit` quando souber
   o range. `Grep` antes de `Read` quando procurar símbolo.
   **Obrigatório dar `limit` em arquivo > 1000 linhas** — Read default
   queima 5-20k tokens facilmente.
2. **Subagent pra investigação cara.** Read de 5+ arquivos pra
   responder uma pergunta → delegue. Devolve resumo de ~500 tokens em
   vez de 20k de contexto.
3. **Path relativo > absoluto em refs.** `path/file.ext:42` é mais
   curto, mais clicável e mais portátil que absoluto longo.

## Hierarquia de carregamento

Onde colocar a informação importa pro custo recorrente:

| Canal | Carregamento | Quando usar |
|---|---|---|
| `CLAUDE.md` (raiz) | Sempre, todo turno | Regras duras + gotchas que afetam decisões em qualquer tarefa |
| `.claude/docs/*.md` | Sob demanda, agente lê | Doutrina específica (esta doc, multiagent, git, etc.) |
| `.claude/docs/project_map/*.md` | Sob demanda, agente lê | Topologia do código por área |
| `.claude/skills/*/SKILL.md` | Só quando invocada | Workflow especializado |
| `memory/*.md` | Entre sessões | Traço durável sobre usuário/projeto |
| Subagent (`Explore`, `Plan`, etc.) | Sob demanda, isolado | Investigação pesada que retornaria resumo |

Regra: **quanto mais alto na tabela, mais cuidadoso com o tamanho**.
`CLAUDE.md` inflado custa toda sessão; skill inflada só custa quando
roda.

## Padrões pro usuário pedir coisas

Quando o usuário escrever pedido (ou quando o agente ajudar a
escrever):

- **Escopo concreto + path** > escopo aberto. "Refactor `X` em
  `path/file.ext`" >> "limpa o X".
- **Cap de resposta quando aplicável.** "Responda em < 200 palavras",
  "lista os 3 piores", "uma tabela só".
- **Pergunta única > múltipla.** Cada pergunta vira um ramo de
  contexto. 4 perguntas distintas pode justificar 4 turnos enxutos
  em vez de 1 turno gigante.
- **Não cole o CLAUDE.md (ou trecho dele) no prompt.** Já carrega
  automático todo turno. Repetir = pagar duas vezes pelo mesmo
  contexto.

## Anti-padrões caros (evite)

- **Re-explicar contexto a cada turno.** Confie no que já foi
  estabelecido. Se o agente "esqueceu", ele consulta `CLAUDE.md` ou
  memória, não pede pra você repetir.
- **Screenshot sem motivo.** Imagem pesa muito em tokens. Use quando
  o problema é genuinamente visual; caso contrário descreva.
- **Read de arquivo inteiro quando 50 linhas bastam.** Use
  `offset`/`limit` ou `Grep` com `-A`/`-B` pra contexto local.
- **Subagent pra coisa trivial.** Subagent tem overhead de boot — não
  vale a pena pra 1-2 reads. Vale pra investigação 5+ arquivos ou
  tarefa de 3+ steps.
- **Bash com `cat`/`head`/`tail`/`ls`/`find`/`grep`.** Tem Read, Glob
  e Grep dedicados — mais barato, melhor permissão, output mais
  limpo. Bash só pra shell-only (git, npm, docker, scripts).
- **Reread após Edit/Write.** Tool já validaria erro. Re-ler só pra
  "confirmar visualmente" é queima dupla.
- **Re-ler arquivo já lido na sessão.** Confie no contexto atual. Se
  duvidar do estado, leia só o range que mudou.
- **Criar `.md` de plano/análise sem ser pedido.** Plano vive na
  conversa (ou em `TodoWrite`). Arquivo intermediário vira lixo na
  próxima sessão e custa Read futuro.
- **Rodar build/test que não valida a mudança.** Se a mudança é
  doc/comentário/refactor sem efeito runtime, pular.
- **`git status` / `git diff` redundante.** Se já rodou no início do
  turno e não editou nada desde, confia no estado conhecido.
- **Loop de leitura A→B→A.** Investigação que pula entre 5+ arquivos
  pra entender 2 = sintoma de delegação ruim. Para, formula a
  pergunta inteira, delega pra subagent (`Explore`/`Plan`).
- **Sleep longo entre passos.** Cache do prompt expira em ~5min.
  Sleeps de 5-10min são pior dos mundos: você espera E paga cache
  miss. Fica em curto (< 5min) ou commit em longo de verdade
  (20min+).
- **MCP tools caros sem necessidade.** Screenshot / browser /
  computer-use têm payload pesado. Priorize Read/Grep/Bash quando o
  problema não é genuinamente visual ou de runtime UI.
- **Comentários no código que descrevem o "o quê".** Já regra de
  `CONVENTIONS.md` — tokens de comentário inútil são lidos toda vez
  que o agente lê o arquivo.

## Quando rodar a skill `polish` por motivo de token

A skill `polish` tem categorias com efeito direto em token:

- Comentários verbosos sem valor
- Docs stale/duplicadas em `.claude/docs/`
- Logs em hot paths poluindo console
- Onboarding duplicado entre CLAUDE.md e .claude/docs/

Quando o agente notar contexto pesado em sessões recentes, sugerir
rodar `polish` priorizando essas categorias — payback direto.
