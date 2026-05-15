# CLAUDE.md — {{PROJECT_NAME}}

Notas para sessões futuras. Leia antes de começar a mexer em qualquer coisa.

> **Template aplicado a partir de `project_zero/`**. Mantenha esta nota
> enquanto não houver muitas regras próprias — quando o arquivo crescer
> e ganhar identidade, pode remover.

## Mapa do projeto pra IA — LEIA PRIMEIRO

[`.claude/docs/project_map/`](.claude/docs/project_map/) contém docs compactos
(50-150 linhas cada) mapeando cada área do projeto com `file:line`
references. Otimizados pra IA ler — tabelas densas, sem prosa, sem
exemplos de código (esses ficam no fonte).

**Antes de greppar/explorar, leia o doc relevante** — costuma economizar
5-10 reads. Comece pelo [README.md](.claude/docs/project_map/README.md) (índice).

**Regra de manutenção**: ao mudar mecânica documentada, **atualize o doc
no MESMO turno**. Drift = bug invisível, pior que não ter doc. Doc tem
`file:line` clicáveis — confirme no código real antes de propagar
premissa.

> **Se ainda não populou o `project_map/`**: a skill `sync-project-map`
> ajuda a manter; o `_GUIDE.md` explica o formato.

### Recursos auxiliares pra consultar ANTES de greppar

Dois arquivos compactos que evitam que a IA invente termo ou reverta
decisão sem entender:

- [`.claude/docs/GLOSSARY.md`](.claude/docs/GLOSSARY.md) — vocabulário específico
  do projeto. Antes de pedir definição de um termo do domínio,
  consulte aqui.
- [`.claude/docs/decisions/`](.claude/docs/decisions/) — ADRs leves explicando por
  que escolhas foram feitas. Antes de "melhorar" algo que parece
  arbitrário, confira se tem decisão registrada.

## O que é o projeto

{{PROJECT_DESCRIPTION}}

- **Stack**: {{STACK}}
- **Plataforma alvo**: {{PLATFORM}}
- **Pasta raiz do código**: `{{SRC_ROOT}}`

## Como rodar

```bash
{{RUN_COMMAND}}
```

Testes (se houver):

```bash
{{TEST_COMMAND}}
```

## Regras duras (não quebrar)

> Liste aqui as restrições não-negociáveis do projeto. As 3 primeiras
> vêm do template e valem na maioria dos projetos — remova se não se
> aplicar. Adicione as específicas do seu domínio depois.

1. **Nunca commitar / push / pull / merge / rebase na branch do
   usuário.** O agente NÃO executa `git commit`, `git push`,
   `git pull`, `git merge`, `git rebase`, `git checkout` que troca de
   branch, `git reset --hard`, ou qualquer comando que mexa em estado
   versionado remoto. Stage (`git add`) e leitura (`status`, `diff`,
   `log`) são permitidos. **O usuário faz o commit/push manualmente
   depois de revisar.** Se ele explicitamente pedir "comita", aí sim —
   uma vez, naquele turno. Não interprete "pode seguir" como
   autorização pra commitar.

2. **Toda mudança passa por PR (pull request).** `main` / `master` /
   branch principal NUNCA recebe edit direto. Fluxo obrigatório:

   - **Antes de qualquer Edit/Write**, agente confere a branch atual
     (`git branch --show-current`).
   - Se estiver em `main`/`master`/principal: **PARA e pergunta** ao
     usuário antes de editar. Sugestão: "Tô em `main`. Crio branch
     `feature/<slug>` (ou `fix/<slug>`, `refactor/<slug>`) pra essa
     task?" Espera confirmação. Agente NÃO cria branch sozinho — o
     usuário decide o nome e roda `git checkout -b <branch>`.
   - Se já estiver em branch ≠ principal: trabalha normal.
   - Quando o usuário pedir pra commitar (regra #1 acima), commit
     vai pra branch atual — nunca pra `main`.
   - **PR contra `main` é decisão humana.** Agente pode preparar
     descrição do PR se pedido, mas NUNCA faz `gh pr merge`, merge
     pela UI do GitHub, nem força push pra `main`.
   - **Merge é sempre humano.** Mesmo se o usuário disser "tá pronto,
     pode mergear" — confirma duas vezes antes (rara exceção;
     default é "abre o PR e te aviso").

   Por que: PR é trilha de auditoria. Toda mudança fica visível,
   revisável, reversível. Sem PR = mudança escapa sem revisão = bug
   ou regressão sem rastro de causa.

3. **Não criar arquivo `.md` de plano/análise/recap sem ser pedido.**
   Plano vive em `TodoWrite` ou na conversa. Arquivo intermediário
   vira lixo na próxima sessão e custa Read futuro.
4. **Não ler / editar / commitar arquivos sensíveis.** Consulte
   [`SECURITY_NOTES.md`](SECURITY_NOTES.md) na raiz — define padrões
   (`.env`, chaves, credenciais, secrets) e política do que NÃO tocar.
   Em dúvida, pergunta antes de ler.
5. **(Convenção do projeto — preencher)**. Ex.: "Sem dependências
   externas no runtime"; "Nada de DOM dentro do canvas"; "Toda string
   visível passa por i18n".

## Arquitetura

> Diagrama ASCII ou descrição curta da arquitetura. Ponto de entrada,
> camadas principais, fluxo de dados. Mantenha curto — detalhes ficam
> em `.claude/docs/project_map/`.

```text
{{SRC_ROOT}}main.* → ...
```

## Gotchas conhecidos

> Coisas que parecem bug mas são intencionais. Coisas que já causaram
> bug e a gente nunca mais quer repetir. Edge cases que não estão
> documentados no código.

1. **(Edit conforme descobrir gotchas reais)**.

## Como fazer coisas comuns

> Receitas para tarefas recorrentes. Exemplos típicos:

### Adicionar nova feature
1. Onde criar o arquivo
2. Onde registrar (se houver registry)
3. Onde adicionar testes
4. O que validar antes de fechar

### Renomear símbolo público
1. Grep do nome antigo no projeto inteiro
2. Atualizar todas as refs
3. Atualizar `.claude/docs/project_map/` se citado

## Estilo de código

- Nomes em inglês no código.
- Arquivos pequenos — se passar de ~400 linhas, considere dividir.
- **Comentários: default é NÃO escrever.** Só quando o "porquê" é
  não-óbvio (gotcha histórico, workaround pra bug específico, hidden
  constraint, edge case que surpreenderia o leitor). Se apagar o
  comentário não confunde ninguém, ele é ruído.
- **Nunca emoji/emote** em comentário, identificador, string de log,
  ou commit message. Acresce zero, custa token, polui diff.
- **Sem divisores ASCII** (`// ============`, `// ----`,
  `// === Render ===`). IDE já mostra estrutura por dobramento e
  navegação por símbolo.
- **Sem JSDoc trivial.** Não documentar parâmetro cujo nome já diz
  tudo. JSDoc só pra API pública com regra/comportamento não-óbvio.
- **Sem TODO órfão.** Se for marcar TODO, inclui contexto (`// TODO:
  X quando Y resolver`) — TODO sem owner/condição vira lixo
  arqueológico.
- **Sem "comentário-tag"** (`// fix bug`, `// new feature`, `// added
  by X`). Use `git blame`/`git log` pra história — comentário não é
  changelog.

## Eficiência de tokens (regras pra agente)

Token é orçamento. Cada mensagem do agente paga 100% do contexto
acumulado da sessão. Estas regras existem pra manter qualidade ao
mesmo tempo que reduz custo — não são "limites duros", são default.

> **Convenções gerais** (compactação, tabela > prosa, `file:line`,
> cross-link, naming, comentários, estilo) vivem em
> [`.claude/docs/CONVENTIONS.md`](.claude/docs/CONVENTIONS.md). Esta seção foca em
> **eficiência de token** especificamente; não duplica.

### Princípios

1. **Read parcial > Read inteiro.** Usa `offset`/`limit` quando souber
   o range. `Grep` antes de `Read` quando procurar símbolo.
   **Obrigatório dar `limit` em arquivo > 1000 linhas** — Read default
   queima 5-20k tokens facilmente.
2. **Subagent pra investigação cara.** Read de 5+ arquivos pra
   responder uma pergunta → delegue pra subagent. Devolve resumo de
   ~500 tokens em vez de 20k de contexto.
3. **Path relativo > absoluto em refs.** `[foo.js:42](src/foo.js:42)`
   é mais curto, mais clicável e mais portátil que
   `D:/.../proj/src/foo.js:42`.

### Hierarquia de carregamento

Onde colocar a informação importa pro custo recorrente:

| Canal | Carregamento | Quando usar |
|---|---|---|
| `CLAUDE.md` (este arquivo) | Sempre, todo turno | Regras duras + gotchas que afetam decisões em qualquer tarefa |
| `.claude/docs/project_map/*.md` | Sob demanda, agente lê | Topologia do código por área |
| `.claude/skills/*/SKILL.md` | Só quando invocada | Workflow especializado (audit, refactor, planejamento) |
| `memory/*.md` | Entre sessões | Traço durável sobre usuário/projeto (não state efêmero) |
| Subagent (`Explore`, `Plan`, etc.) | Sob demanda, isolado | Investigação pesada que retornaria resumo |

Regra: **quanto mais alto na tabela, mais cuidadoso com o tamanho**.
`CLAUDE.md` inflado custa toda sessão; skill inflada só custa quando
roda.

### Padrões pro usuário pedir coisas

Quando o usuário escrever pedido (ou quando você ajudar a escrever):

- **Escopo concreto + path** > escopo aberto. "Refactor `Tower.update`
  em `entities/Tower.js`" >> "limpa as torres".
- **Cap de resposta quando aplicável.** "Responda em < 200 palavras",
  "lista os 3 piores", "uma tabela só".
- **Pergunta única > múltipla.** Cada pergunta vira um ramo de
  contexto. 4 perguntas distintas pode justificar 4 turnos enxutos
  em vez de 1 turno gigante.
- **Não cole o CLAUDE.md (ou trecho dele) no prompt.** Já carrega
  automático todo turno. Repetir = pagar duas vezes pelo mesmo
  contexto.

### Anti-padrões caros (evite)

- **Re-explicar contexto a cada turno.** Confie no que já foi
  estabelecido. Se o agente "esqueceu", ele consulta `CLAUDE.md` ou
  memória, não pede pra você repetir.
- **Screenshot sem motivo.** Imagem pesa muito em tokens. Use quando
  o problema é genuinamente visual; caso contrário descreva.
- **Read de arquivo inteiro quando 50 linhas bastam.** Use
  `offset`/`limit` ou `Grep` com `-A`/`-B` pra contexto local.
- **Subagent pra coisa trivial.** Subagent tem overhead de boot —
  não vale a pena pra 1-2 reads. Vale pra investigação 5+ arquivos
  ou tarefa de 3+ steps.
- **Bash com `cat`/`head`/`tail`/`ls`/`find`/`grep`.** Tem Read,
  Glob e Grep dedicados — mais barato, melhor permissão, output mais
  limpo. Bash só pra shell-only (git, npm, docker, scripts).
- **Reread após Edit/Write.** Tool já validaria erro. Re-ler só pra
  "confirmar visualmente" é queima dupla.
- **Re-ler arquivo já lido na sessão.** Confie no contexto atual.
  Se duvidar do estado, leia só o range que mudou.
- **Criar `.md` de plano/análise sem ser pedido.** Plano vive na
  conversa (ou em `TodoWrite`). Arquivo intermediário vira lixo na
  próxima sessão e custa Read futuro.
- **Rodar build/test que não valida a mudança.** Se a mudança é
  doc/comentário/refactor sem efeito runtime, pular. Build/test custa
  tempo + output longo no contexto.
- **`git status` / `git diff` redundante.** Se já rodou no início do
  turno e não editou nada desde, confia no estado conhecido. Re-rodar
  toda vez polui o contexto com output repetido.
- **Loop de leitura A→B→A.** Investigação que pula entre 5+ arquivos
  pra entender 2 = sintoma de delegação ruim. Para, formula a
  pergunta inteira, delega pra subagent (`Explore`/`Plan`).
- **Sleep longo entre passos.** Cache do prompt expira em ~5min.
  Sleeps de 5-10min são pior dos mundos: você espera E paga cache
  miss. Fica em curto (< 5min) ou commit em longo de verdade (20min+).
- **MCP tools caros sem necessidade.** Screenshot / browser /
  computer-use têm payload pesado. Priorize Read/Grep/Bash quando o
  problema não é genuinamente visual ou de runtime UI.
- **Comentários no código que descrevem o "o quê".** Já no estilo
  acima — tokens de comentário inútil são lidos toda vez que o
  agente lê o arquivo.

### Estilo de output do agente

O texto que o agente devolve também é token — e cresce com o histórico
da conversa. Default conservador.

**Importante**: as regras abaixo cortam **ruído** (prefácio, emoji,
banner, confirmação trivial, resumo redundante). Não cortam
**substância**. Resposta técnica continua densa — tabela com
`file:line`, fórmula, edge cases. O que some é o fluff em volta. Se a
resposta exige análise comparativa, traz a análise; se exige
diagrama mental, traz o diagrama. "Direto" não é "lacônico burro".

- **Sem emoji/emote** nas respostas. Exceção: o usuário usou primeiro
  e o tom da conversa permite.
- **Sem prefácio.** Não escreva "Entendi seu pedido, vou agora...",
  "Ótima pergunta!", "Claro!". Vai direto pra ação ou pra resposta.
- **Sem banner/header decorativo** em resposta curta. `##` e tabela
  são pra resposta que de fato tem estrutura — pergunta simples ganha
  1-2 frases.
- **Sem confirmação trivial entre passos.** Não pergunta "posso
  prosseguir?" depois de cada step. Se o usuário disse "pode seguir",
  ele já autorizou o escopo.
- **Sem resumo redundante.** Depois de Edit/Write, o diff já apareceu;
  não reescreva o que mudou. Só fala o que NÃO aparece no diff
  (motivo, próximo passo).
- **Sem repetir o que o tool imprimiu.** Output de Bash/Grep já está
  na conversa — não cite linha por linha de novo.
- **Cap natural: 1-2 frases por turno** na maioria dos casos.
  Markdown só quando agrega (3+ itens comparáveis → tabela; 2 itens
  → frase).
- **`AskUserQuestion` > pergunta em texto longo.** Quando há 2-4
  opções discretas, a UI estruturada é mais barata + mais clara que
  parágrafo + lista numerada.
- **`TodoWrite` > narrar passos no texto.** Lista estruturada vale
  mais que "vou fazer X, depois Y, depois Z". Reduz narrativa,
  dá controle ao usuário.
- **Commit messages curtas, sem decoração.** 1 linha de assunto +
  corpo opcional. Sem emoji, sem ASCII art, sem rodapé
  `Co-Authored-By` exceto quando configurado pelo projeto.
- **Português direto + técnico.** Sem suavização ("talvez seria
  interessante..."), sem qualificadores defensivos ("acho que talvez
  possa funcionar"). Diz o que é.

### Quando rodar a skill `polish` por motivo de token

A skill `polish` tem 4 categorias com efeito direto em token:

- #16 (comentários verbosos sem valor)
- #17 (docs stale/duplicadas em `.claude/docs/`)
- #18 (logs em hot paths poluindo console)
- #19 (onboarding duplicado entre CLAUDE.md e .claude/docs/)

Quando o agente notar contexto pesado em sessões recentes, sugerir
rodar `polish` priorizando essas categorias — payback direto.

## Como o usuário trabalha

- Comunica em {{USER_LOCALE}}. Mantenha UI default em {{LANGUAGE}}.
- Dá liberdade depois do alinhamento inicial — quando ele diz "pode
  seguir" ou "faz o que recomendou", ele espera execução ampla com
  bom senso.
- Antes de projetos/fases grandes, perguntar sobre escopo, tech choice
  e plataforma alvo.

## Skills ativas neste projeto

> Liste as skills do `.claude/skills/` que estão ativas. Cada skill
> tem seu próprio `SKILL.md` descrevendo triggers e fluxo.

- `roadmap-review` — sparring de planejamento (reativo/proativo)
- `dry-pass` — caça duplicação (sob demanda)
- `polish` — qualidade estrutural (sob demanda)
- `sync-project-map` — mantém docs em sync (automática via hook)
- `code-review-and-quality` — review multi-axis antes de merge (sob demanda)
- `deprecation-and-migration` — remoção segura de código/API (sob demanda)
- `browser-testing-with-devtools` — testes em browser via DevTools MCP
  (só relevante pra projetos com UI browser)
- `switch-agent-profile` — troca/lista/cria profiles de agentes
  (sob demanda; ver `.claude/agent-profiles/README.md`)
- `cost-report` — relatório de tokens da sessão atual.
  **Auto-trigger**: quando o user iniciar a sessão com "lê o README e
  faz o setup" (ou variantes — "implementa o que o README pede",
  "segue o README"), o agente deve rodar esta skill como ÚLTIMA ação
  do fechamento, antes do summary. Roda sob demanda também
  ("relatório de tokens", "cost report").

## Sub-agentes ativos (multiagente)

Este projeto usa o padrão multi-agente do Claude Code. Cada sub-agente
roda em **contexto isolado** — investigação pesada não polui o
contexto principal, e cada um tem sua especialidade.

### Regra fundamental

**Sub-agente NÃO pode invocar outro sub-agente** (limitação do Claude
Code). Por isso o padrão é:

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

### Quem usar quando

| Agente | Quando despachar | Custo |
|---|---|---|
| `operador` (Opus) | Demanda multi-papel ou escopo vago. Devolve plano de despacho. | Alto — só pra task complexa |
| `dev` | Spec clara → produz código | Médio |
| `analista` | Investigação read-only, audit, causa raiz | Baixo (só lê) |
| `escriba` | Atualizar docs depois de mudança | Baixo |

### Regra dura de decisão (Camada 1 — filtro rápido)

Antes de chamar `Agent()`, responda:

1. Precisa abrir 4+ arquivos? Sim → considera. 10+? Delega.
2. Tool results vão poluir contexto com lixo? Sim → delega.
3. 2+ investigações paralelas independentes? Sim → delega em paralelo.

Se 2 respostas forem "não", **faz direto** (sem Camada 2).
Se passar o filtro (delega), vai pra Camada 2 abaixo.

### Receita de time por nível (Camada 2 — Fibonacci)

Passou pela Camada 1? Esta tabela define **QUAL time** montar. Escala
não-linear (1, 2, 3, 5, 8) força decisão qualitativa: pergunta "isso é
mais parecido com 3 ou com 5?", não "isso é 4?".

| Nível | Sinal de entrada | Time | Custo estimado |
|---|---|---|---|
| **1** | 1 investigação OU 1 implementação focada, escopo claro, 1 área | 1 subagente (analista OU dev) | ~10k |
| **2** | Investigar antes de implementar, mesma área | analista → principal → dev | ~20k |
| **3** | 2+ áreas independentes, paralelizáveis | 2-3 subagentes em paralelo | ~30-40k |
| **5** | Escopo precisa decomposição, 3+ disciplinas envolvidas | operador planeja → principal despacha conforme plano | ~50-60k |
| **8** | Multi-papel + decisão de escopo + gates entre passos | operador com gates → cadeia + checkpoint humano em pontos críticos | ~70k+ |

**Regra anti-conservadora (importante):**

- Classificou **entre 2 níveis**? Escolhe o **MENOR**. Subir "por
  garantia" infla custo sem ganho de qualidade.
- Default é descer, não subir. Sobre-orquestrar 1 task é pior que
  sub-orquestrar — o segundo se corrige rápido, o primeiro paga já.
- Se durante execução perceber que era nível maior, **re-classifica
  explicitamente** ("essa task é nível 5, não 2 — pivotando pra
  operador") em vez de bancar silenciosamente.

**Sinais de re-classificação durante execução:**

- Nível 1 vira 2 quando: a investigação encontrou que precisa editar.
- Nível 2 vira 3 quando: a edição vai tocar outra área independente.
- Nível 3 vira 5 quando: as áreas têm dependência que exige ordem.
- Nível 5 vira 8 quando: aparece decisão de escopo que precisa
  validação humana antes de seguir.

**Aplicação resumida:**

```
Camada 1 (regra dura) → "faz direto"? → fim
                     → "delega"?       → Camada 2

Camada 2 (Fibonacci)  → classifica nível 1-8
                     → segue receita do nível
                     → re-classifica se surgir sinal
```

### Quando NÃO usar sub-agente

- Edit de 1-2 linhas → principal faz direto.
- Pergunta isolada que cabe em 1 grep → principal faz direto.
- Tarefa já decomposta + escopo claro → pula o operador, vai direto
  pro dev.
- Verificação rápida pós-edit → principal usa Read.

Sub-agente tem boot cost. Vale quando o trade entrega ganho real de
contexto/especialização — não como hábito automático.

### Briefing mastigado pros agentes despachados

Todo `prompt` do `Agent()` deve levar paths com `file:line` quando
possível. Briefing vago força o agente a gastar 10-30k tokens na fase
de localização (Glob + Grep + Read exploratório) antes de chegar no
trabalho real.

**Padrão correto:**

```text
prompt: "Edita `src/auth/Token.js:67` trocando validateSync por
validateAsync. Constraint: respeitar `Token.refresh()` em :120 que
assume retorno síncrono — adapta a chamada."
```

**Padrão errado:**

```text
prompt: "Implementa validação assíncrona no Token"
```

**Quando o principal não sabe os paths ainda**: despache `analista`
primeiro com briefing genérico. Use o **"Briefing pronto pra próxima
etapa"** do output dele direto no prompt do dev/escriba. Isso
amortiza o custo do analista entre múltiplos agentes downstream.

**Paralelizar quando possível**: se o analista entregou paths de
código + paths de doc afetados, despache `dev` e `escriba` no MESMO
turno (`Agent()` em paralelo). Sem briefing mastigado, escriba teria
que esperar o dev — sequencial vira paralelo.

### Fallback: briefing em arquivo (só pra casos pesados)

Quando o briefing pra um agente passa de ~5k tokens (dump de schema,
log gigante, lista enorme de paths), em vez de inflar o `prompt`:

1. Salva em `.claude/tmp/briefing_<task-slug>.md` (gitignored).
2. No prompt: "Lê `.claude/tmp/briefing_<task-slug>.md` ANTES de
   começar. Contém contexto da task."
3. Próxima task sobrescreve o arquivo (não precisa limpar).

Use só pra briefing > 5k. Inline é mais barato pra briefing menor.

### Por que ajuda no token

- **Contexto isolado**: analista lê 10 arquivos, devolve resumo de
  500 tokens. O principal nunca carrega os 10 arquivos.
- **Especialização**: cada um tem system prompt focado, não precisa
  carregar regras gerais que o principal já tem.
- **Paralelização**: 2-3 sub-agentes podem rodar simultâneo em
  investigações independentes.

Trade-off: cada boot custa tokens. Pra task < 3 reads, **não vale**.

## Antes de fechar a task (checklist)

IA fraca diz "pronto" cedo demais. Antes de declarar uma task como
concluída, confira nesta ordem:

- [ ] **Validou runtime?** Se a mudança é executável, rodou pra ver
      que funciona. `node --check` (ou equivalente da stack) pega
      sintaxe, NÃO pega ReferenceError em closure. Pra UI, abriu o
      preview e testou o caminho golden + edge cases. Se não dá pra
      testar, fala explícito ("não testei runtime porque X") em vez
      de declarar concluído.
- [ ] **Docs em sync?** Mexeu em arquivo coberto pelo `project_map`?
      O hook deve ter disparado reminder. Despache o sub-agente
      `escriba` (se ativo) ou invoque a skill `sync-project-map`.
- [ ] **GLOSSARY / DECISIONS?** Introduziu termo de domínio novo?
      Tomou decisão não-óbvia? Vale registrar agora — depois esquece.
- [ ] **i18n nos idiomas suportados?** Se o projeto tem i18n e você
      mexeu em string visível, atualizou TODOS os idiomas. Faltas
      parciais são bug.
- [ ] **CLAUDE.md merece update?** Descobriu gotcha novo durante a
      task? Edge case surpreendente? Convenção que não estava
      escrita? Adiciona como gotcha/regra dura.
- [ ] **Cache / version bump?** Se o projeto tem service worker /
      manifest / version field, mudança significativa pede bump.
- [ ] **Branch correta?** `git branch --show-current` — está numa
      branch dedicada (não `main`/`master`)? Se está em `main`,
      mudança escapou da regra dura #2; sinaliza pro usuário pra
      decidir (mover pra branch ou aceitar como erro pontual).
- [ ] **Stage limpo?** Fez `git add` só do que faz parte desta task —
      não arrastou `.env`, log, build output, arquivo do template
      que ficou de fora.
- [ ] **Commit pendente?** NÃO commita você (regra dura #1).
      Sinaliza pro usuário que tem mudanças prontas pra revisão —
      lista enxuta dos arquivos. Lembrar: commit vai pra branch
      atual, PR fica pra revisão humana (regra dura #2).
- [ ] **Resumo enxuto?** 1-2 frases do que mudou + 1 frase do
      próximo passo (se houver). Sem repetir o diff. Sem emoji.
- [ ] **Relatório de tokens?** Se a sessão começou com "lê o README e
      faz o setup" (ou variante), rode a skill `cost-report` ANTES do
      resumo. Devolve quanto a sessão consumiu, separando principal e
      subagentes. Pra outras tasks não roda automaticamente — só sob
      demanda do user.

Se algum item ficou em aberto, **diga isso** em vez de declarar
concluído. "Pronto, fica faltando X" é melhor que "pronto" implícito
que vira bug depois.

## Coordenação de sessões paralelas

Antes de tocar arquivos compartilhados, verifique
[`.claude/SESSION_LOCK.md`](.claude/SESSION_LOCK.md). Reclame uma
sessão paralela com escopo + timestamp antes de começar.
