# project_zero — Template base pra novos projetos

> **TL;DR humano:**
>
> 1. Copia esta pasta pra raiz do seu projeto novo
> 2. Abre uma sessão com seu agente (Claude Code, Cursor, Cline, etc.)
> 3. Diz: "Leia o `project_zero/README.md` e configure este projeto."
> 4. O agente roda o setup guiado em 8 passos (~5-15 min).
>
> Atalho automático: `bash project_zero/setup.sh` cobre o trivial.
> Depois, `bash validate.sh` confere se tudo ficou em pé.
>
> Windows: usar Git Bash (já vem com Git for Windows).
>
> O resto deste README é instrução **pra IA** que aplica o template.

Pasta-ponte que carrega para um projeto novo o conjunto mínimo de
**docs, skills, hooks e padrões de coordenação** que valeu a pena
extrair de projetos anteriores (referência inicial: IsoDead TD).

Objetivo: **não começar do zero**. Quando abrir um projeto novo, copie
esta pasta pra raiz dele, abra uma sessão com o agente e mande
"configure este projeto a partir do `project_zero/README.md`". O agente
faz o setup guiado.

---

## Como aplicar este template (instruções pro AGENTE)

> Esta seção é lida pelo agente quando o usuário pede "leia o
> `project_zero/README.md` e configure". Siga os passos NA ORDEM. Não pule
> os passos 1 e 6 — são os mais delicados.

### Passo 1 — Detectar o agente e o arquivo de instruções do projeto destino

A IA que aplica este template pode não ser a mesma que vai trabalhar no
projeto depois. Cada agente lê instruções de arquivos diferentes —
descubra qual é o do projeto destino ANTES de copiar qualquer coisa.

#### Como detectar (comandos concretos)

Rode estes Globs **na raiz do projeto destino**, em ordem:

```text
Glob: CLAUDE.md
Glob: .cursorrules
Glob: .cursor/rules/*.mdc
Glob: .clinerules
Glob: .windsurfrules
Glob: .aider.conf.yml
Glob: CONVENTIONS.md
Glob: .github/copilot-instructions.md
Glob: AGENTS.md
```

Mapeamento do que cada um significa:

| Match | Agente | Tipo |
|---|---|---|
| `CLAUDE.md` | Claude Code | Arquivo único |
| `.cursorrules` | Cursor (formato legacy) | Arquivo único |
| `.cursor/rules/*.mdc` | Cursor (formato novo, modular) | Pasta com 1+ arquivos `.mdc` |
| `.clinerules` | Cline | Arquivo único |
| `.windsurfrules` | Windsurf | Arquivo único |
| `.aider.conf.yml` + `CONVENTIONS.md` | Aider | Config + doc separados |
| `.github/copilot-instructions.md` | GitHub Copilot | Arquivo único |
| `AGENTS.md` | Codex CLI / OpenAI / genérico | Arquivo único |

#### Política de decisão

**Se achou ZERO arquivos:**

Pergunte ao usuário com bloco fechado:

```text
Não detectei arquivo de instruções no projeto. Qual agente você usa?

1. Claude Code → crio CLAUDE.md
2. Cursor → crio .cursor/rules/project.mdc
3. Cline → crio .clinerules
4. Windsurf → crio .windsurfrules
5. Aider → crio CONVENTIONS.md
6. GitHub Copilot → crio .github/copilot-instructions.md
7. Outro / não sei → crio CLAUDE.md como default
```

**Se achou UM arquivo:**

Ele é o ponto de entrada. Anote o path absoluto. Vai ser **estendido
no Passo 5**, NÃO sobrescrito. Mostre ao usuário pra confirmar:

```text
Detectei <path>. Vou estender este arquivo no Passo 5. Confirma?
```

**Se achou VÁRIOS:**

Liste todos e pergunte qual é o canonical. Não duplique instruções:

```text
Detectei vários arquivos de instruções:
- CLAUDE.md (320 linhas)
- .cursorrules (45 linhas)

Qual é o canonical? (Só vou estender um. Os outros podem virar
stubs com 1 linha apontando pro canonical.)
```

#### Edge case: monorepo

Se a raiz tem pastas como `packages/`, `apps/`, `services/` (Lerna,
Turbo, Nx, Yarn Workspaces), pergunte ao usuário se o template aplica
em:

1. **Raiz do monorepo** (rules globais) — default na maioria dos casos
2. **Uma pasta específica** (ex.: `packages/web/`)
3. **Cada pasta** (raro, e custoso de manter)

Anote a escolha. Todos os paths subsequentes serão relativos a essa
raiz escolhida.

#### Output do Passo 1

Anote em sua memória/contexto (não precisa escrever arquivo):

```text
AGENT_TYPE      = <Claude Code | Cursor | Cline | ...>
INSTRUCTION_FILE = <path absoluto ou relativo do arquivo escolhido>
PROJECT_ROOT    = <raiz onde aplicar — pode ser monorepo subpath>
```

Esses 3 valores são usados em todos os passos seguintes.

### Passo 2 — Inventariar o projeto destino

Antes de qualquer copy/paste, leia o estado real:

- Existe `.claude/skills/`, `.claude/hooks/`, `docs/project_map/`?
- Qual a stack? (Node? Python? Rust? Game engine? Web puro?)
- Qual a plataforma alvo? (CLI, web, mobile, desktop, biblioteca)
- Tem build step? Tem testes? Como roda local?

Se algo não for claro pelo conteúdo do repo, **pergunte ao usuário em
bloco único**. Não chute valores pra colocar no arquivo de instruções.

### Passo 3 — Perguntar o que o usuário quer ativar

Apresente as 8 skills disponíveis e pergunte quais ativar pro projeto
novo:

| Skill | Reativa/Proativa | Quando vale a pena |
|---|---|---|
| `roadmap-review` | Sob demanda | Sempre vale — sparring de planejamento, agnóstico |
| `dry-pass` | Sob demanda | Codebase > algumas centenas de linhas com risco de duplicação |
| `polish` | Sob demanda | Codebase em crescimento contínuo (3+ fases) |
| `sync-project-map` | Automática (via hook) | Só se for criar `docs/project_map/` |
| `code-review-and-quality` | Sob demanda | Sempre vale antes de merge — review multi-axis |
| `deprecation-and-migration` | Sob demanda | Quando vai sunsetar API/feature/código legado |
| `browser-testing-with-devtools` | Sob demanda | Só pra projetos com UI browser (Chrome DevTools MCP) |
| `task-retrospect` | Sob demanda | Fechamento consciente de task — varre git + sugere ações |

Pergunte também se quer:
- Hook `check-sync-project-map.sh` (depende da skill `sync-project-map`)
- Hook `check-session-lock.sh` (depende de `SESSION_LOCK.md`)
- Hook `on-stop-check.sh` (lembrete de fechamento no fim do turno)
- `SESSION_LOCK.md` (se o usuário trabalha em sessões paralelas)
- `memory/_PATTERNS.md` (referência de como organizar auto-memory)
- **Mapeamento inicial agora ou depois** (ver Passo 6) — default
  recomendado é **depois**, incremental.

### Passo 4 — Coletar valores pra placeholders

Os arquivos template usam estes placeholders. Substitua TODOS antes de
escrever no projeto destino:

| Placeholder | O que é | Exemplo |
|---|---|---|
| `{{PROJECT_NAME}}` | Nome humano do projeto | "IsoDead TD" |
| `{{PROJECT_DESCRIPTION}}` | 1 frase descrevendo o projeto | "Tower defense isométrico em HTML5 Canvas" |
| `{{STACK}}` | Linguagem + framework principal | "JavaScript ES modules + Canvas 2D" |
| `{{PLATFORM}}` | Onde roda | "Web + PWA + Electron + Capacitor" |
| `{{SRC_ROOT}}` | Pasta raiz do código fonte | `src/`, `lib/`, `app/` |
| `{{RUN_COMMAND}}` | Comando pra rodar local | `python -m http.server 8080` |
| `{{TEST_COMMAND}}` | Comando pra rodar testes (ou "nenhum") | `npm test` |
| `{{LANGUAGE}}` | Idioma do usuário pra UI default | "pt-BR" |
| `{{USER_LOCALE}}` | Idioma em que o agente conversa | "pt-BR" |

Para projetos sem i18n, ignore `{{LANGUAGE}}` (remover seções relacionadas).
Para projetos sem build, ignore `{{TEST_COMMAND}}` (remover).

### Passo 5 — Copiar arquivos + injetar referência no arquivo de instruções

#### 5a. Copiar arquivos do template

Pra cada arquivo do template, faça: (i) Read; (ii) substitua TODOS os
`{{PLACEHOLDERS}}` pelos valores coletados no Passo 4; (iii) escreva
no destino seguindo a tabela abaixo.

##### Arquivos com placeholder (renomeiam, podem mesclar)

| Origem (project_zero) | Destino | Política se já existe no destino |
|---|---|---|
| `CLAUDE.template.md` | `CLAUDE.md` (Claude Code) **OU** arquivo nativo do agente detectado (ver §"Adaptação por agente" abaixo) | **Não sobrescreve.** Vai pra mesclagem do Passo 5b. |
| `docs/project_map/README.template.md` | `docs/project_map/README.md` | Pergunta antes de sobrescrever. |
| `.claude/SESSION_LOCK.template.md` | `.claude/SESSION_LOCK.md` | Mantém o existente se já tem sessões reivindicadas. |
| `.claude/settings.template.json` | `.claude/settings.json` | **Mescla** chaves (não sobrescreve). Específico do Claude Code; outros agentes ignoram. |
| `.gitignore.template` | `.gitignore` | **Mescla por linha** (adiciona o que falta; não duplica linhas existentes). |

##### Arquivos sem placeholder (copiam direto)

| Origem (project_zero) | Destino | Observações |
|---|---|---|
| `SECURITY_NOTES.md` | `SECURITY_NOTES.md` (raiz) | Mescla se já existe (preserva entradas específicas do projeto). |
| `docs/CONVENTIONS.md` | `docs/CONVENTIONS.md` | Single source of truth de regras compartilhadas (formato de docs, etc). Sobrescreve OK — outros docs apontam pra ele. |
| `docs/GLOSSARY.md` | `docs/GLOSSARY.md` | Mescla se já existe. |
| `docs/decisions/README.md` | `docs/decisions/README.md` | Não sobrescreve se já tem índice populado. |
| `docs/decisions/_TEMPLATE.md` | `docs/decisions/_TEMPLATE.md` | Sobrescreve OK (é template). |
| `docs/project_map/_GUIDE.md` | `docs/project_map/_GUIDE.md` | Sobrescreve OK (é guia canônico). |
| `.claude/skills/*/SKILL.md` | `.claude/skills/*/SKILL.md` | Copia tudo. Markdown legível por qualquer LLM. |
| `.claude/agents/*.md` | `.claude/agents/*.md` | Copia tudo. Específico do Claude Code; outros agentes ignoram (não atrapalha). |
| `.claude/hooks/check-sync-project-map.sh` | `.claude/hooks/check-sync-project-map.sh` | Copia. Catálogo `RULES` começa vazio — popula conforme cria docs do `project_map`. |
| `.claude/hooks/check-session-lock.sh` | `.claude/hooks/check-session-lock.sh` | Copia. Avisa quando Edit/Write toca arquivo reivindicado em SESSION_LOCK. |
| `.claude/hooks/on-stop-check.sh` | `.claude/hooks/on-stop-check.sh` | Copia. Stop hook — lembrete de fechamento quando o turno teve mudanças. |
| `memory/_PATTERNS.md` | (não copia pro projeto destino) | É referência user-level. Fica no `project_zero/`. |

##### Adaptação por agente (se NÃO for Claude Code)

`CLAUDE.template.md` foi escrito pra Claude Code. Pra outros agentes,
adapte o destino:

| Agente | Destino | Notas |
|---|---|---|
| Cursor (legacy) | `.cursorrules` | Copia conteúdo como markdown. Sem frontmatter. |
| Cursor (novo, modular) | `.cursor/rules/project.mdc` | Adicione frontmatter YAML mínimo: `description: "Project rules"` + `globs: ["**/*"]`. |
| Cline | `.clinerules` | Copia conteúdo direto. |
| Windsurf | `.windsurfrules` | Copia conteúdo direto. |
| Aider | `CONVENTIONS.md` | Copia. Aider lê automaticamente. |
| GitHub Copilot | `.github/copilot-instructions.md` | Copia. Pode precisar mover seções pra ficar mais curto (Copilot tem limite). |
| Outro / genérico | `AGENTS.md` | Convenção emergente, lida por vários CLIs. |

##### Limitações por agente

| Agente | `.claude/skills/` | `.claude/agents/` | `.claude/hooks/` |
|---|---|---|---|
| Claude Code | Funciona via `/skill-name` | Funciona via Agent tool | Funciona (PostToolUse, etc.) |
| Cursor | Não tem mecanismo direto — referencia no `.cursorrules` como "se eu pedir X, leia `.claude/skills/X/SKILL.md`" | Não tem | Não tem |
| Cline / Windsurf | Mesmo de Cursor | Não tem | Não tem |
| Aider | Mesmo | Não tem | Não tem |

Pra agentes sem mecanismo nativo, o arquivo de instruções (Passo 5b)
serve como **ponte**: lista as skills/agents/hooks como recursos
disponíveis pra IA consultar manualmente.

#### 5b. Mesclar seções no arquivo de instruções (CONFERIR ANTES DE ADICIONAR)

**Princípio**: nunca duplicar seção. Antes de injetar qualquer bloco,
**leia o arquivo de instruções inteiro e confira se uma seção
equivalente já existe**. Política:

- **Não existe** → injeta no fim do arquivo.
- **Existe e é equivalente** (mesmo conteúdo, talvez wording diferente)
  → pula, não duplica.
- **Existe mas está stale ou parcial** → mostra o diff ao usuário e
  pergunta: "manter o atual / substituir pelo do template / mesclar".
  Nunca sobrescreve calado.

Use heurística leve pra detectar equivalente: cabeçalho com palavra-chave
similar ("token", "eficiência", "template base", "project_map", "sessão
paralela"). Se em dúvida, **mostra pro usuário em vez de chutar**.

#### Seções candidatas a injeção

Pra cada uma das seções abaixo, faça a checagem acima:

**a) `## Template base — project_zero`** (NOVA — quase nunca existe)

Aponta pra este template, lista skills/hooks ativos. Modelo:

```markdown
## Template base — project_zero

Este projeto usa o template em `D:/Pessoal/project_zero/` como base de
skills, hooks e padrões de coordenação. Antes de tarefas complexas,
considere consultar:

### Skills ativas (em `.claude/skills/`)

- `roadmap-review` — sparring de planejamento. Use pra "planejar X",
  "audita o projeto", "o que tá faltando?".
- `dry-pass` — caça duplicação de dados/lógica. Use sob demanda.
- `polish` — qualidade estrutural. Use sob demanda.
- `sync-project-map` — mantém `docs/project_map/` em sync. Dispara via
  hook depois de cada edit em arquivo coberto.
- `code-review-and-quality` — review multi-axis (correctness,
  readability, architecture, security, performance) antes de merge.
  Use após implementação ou ao revisar código de outro agente/humano.
- `deprecation-and-migration` — remoção segura de código / API /
  feature. Use ao sunsetar sistema, consolidar duplicação, ou
  decidir entre manter ou remover código legado.
- `browser-testing-with-devtools` — testes em browser real via Chrome
  DevTools MCP (DOM, console, network, performance). **Só relevante
  pra projetos com UI browser** — skip em CLI/lib/mobile-native.
- `task-retrospect` — fechamento consciente de task. Varre git status
  + diff e propõe lista priorizada de ações de fechamento (memory,
  ADRs, docs, propagação). Coordena com `on-stop-check.sh`.

### Sub-agentes ativos (em `.claude/agents/`)

- `operador` (Opus) — planejador. Despache em demanda multi-papel ou
  escopo vago. Devolve plano; o principal executa.
- `dev` — implementador. Spec clara → código.
- `analista` — investigador read-only. Audit, causa raiz, mapa de deps.
- `escriba` — mantém docs em sync. NÃO toca código de produção.

### Hooks ativos (em `.claude/hooks/`)

- `check-sync-project-map.sh` — PostToolUse em Edit/Write. Catálogo
  configurado em `.claude/hooks/check-sync-project-map.sh` (array RULES).
- `check-session-lock.sh` — PreToolUse em Edit/Write. Avisa quando
  arquivo está reivindicado em `SESSION_LOCK.md` por outra sessão.
- `on-stop-check.sh` — Stop hook. Injeta lembrete de fechamento quando
  o turno teve mudanças (não substitui o checklist; pareia com
  a skill `task-retrospect`).

### Convenções importadas

- Single source of truth pra regras compartilhadas: `docs/CONVENTIONS.md`
- Auto-memory: ver `D:/Pessoal/project_zero/memory/_PATTERNS.md`
- Doc compacto pra IA: ver `D:/Pessoal/project_zero/docs/project_map/_GUIDE.md`
- Vocabulário do projeto: `docs/GLOSSARY.md` (consulte antes de
  inventar termo)
- Decisões arquiteturais (ADRs): `docs/decisions/` (consulte antes
  de reverter escolha)
- Arquivos sensíveis a não tocar: `SECURITY_NOTES.md` (consulte
  antes de ler arquivo que parece secreto)
- Coordenação de sessões paralelas: ver `.claude/SESSION_LOCK.md`
- Checklist antes de fechar task: ver seção homônima no CLAUDE.md
```

**Adapte a lista** ao que foi efetivamente copiado — se o usuário pulou
o `polish`, não cite. Se mudou paths absolutos pro template (ex.: clone
em outra máquina), ajuste o `D:/Pessoal/project_zero/` pro path real.

**b) `## Eficiência de tokens (regras pra agente)`**

Conteúdo está em [`CLAUDE.template.md`](CLAUDE.template.md) — seção
homônima. Confira se o destino já tem seção com `## Eficiência de
tokens`, `## Token budget`, ou similar. Se sim, perguntar. Se não,
injetar o bloco completo (princípios, hierarquia, padrões, anti-padrões,
gatilho do polish).

**c) `## Mapa do projeto pra IA`**

Conteúdo está em [`CLAUDE.template.md`](CLAUDE.template.md) — seção
homônima. Só faz sentido injetar se `docs/project_map/` foi criado no
Passo 5a. Pula se o destino não tiver a pasta. Se já tem seção com
`## Mapa do projeto`, `## Project map`, ou similar, perguntar.

**d) `## Coordenação de sessões paralelas`**

Conteúdo está em [`CLAUDE.template.md`](CLAUDE.template.md) — seção
homônima. Só injete se `SESSION_LOCK.md` foi criado no Passo 5a. Se
existe seção com `## Sessões paralelas`, `## SESSION_LOCK`, ou
similar, perguntar.

#### Resumo do fluxo de 5b

```text
Pra cada seção candidata (a, b, c, d):
  1. Procura cabeçalho equivalente no arquivo de instruções
  2. Não achou      → injeta no fim
  3. Achou idêntico → pula silencioso
  4. Achou divergente → mostra diff + pergunta usuário
```

No fim, reporta resumido:
```text
Mesclagem concluída:
  - "Template base — project_zero" → injetado (nova)
  - "Eficiência de tokens" → pulado (já existe, equivalente)
  - "Mapa do projeto pra IA" → atualizado (usuário escolheu mesclar)
  - "Coordenação de sessões paralelas" → injetado (nova)
```

### Passo 6 — Mapear o projeto destino (OBRIGATÓRIO)

Sem `docs/project_map/` populado, as skills, hooks e agentes do
template ficam **letra morta**. Eles dependem do mapa pra funcionar
sem desperdiçar contexto (regras como "consulta o mapa antes de
greppar" pressupõem que o mapa existe). **Este passo NÃO é opcional.**

A varredura inicial pode custar caro em projeto grande — por isso a
estratégia abaixo escala por tamanho.

#### 6a. Classifique o tamanho do projeto destino

Rode `Glob` em `{{SRC_ROOT}}/**/*` pra ter uma noção. Classifique:

| Tamanho | Arquivos em SRC_ROOT | Estratégia |
|---|---|---|
| Greenfield | 0-10 | Mapeia tudo direto. Custa quase nada. |
| Pequeno | 10-30 | Mapeia tudo em 2-3 docs. ~5-10k tokens. |
| Médio | 30-80 | Mapeia por área top-level, priorizando núcleo. ~15-30k. |
| Grande | 80+ | Mapeia incremental por área crítica. Despacha subagent paralelo. ~30-60k inicial; resto orgânico via hook. |

#### 6b. Estratégia por tamanho

**Greenfield / Pequeno:**
- Cria 1-3 docs em `docs/project_map/`
- Popula o catálogo (Passo 6c)
- Fim. Próximos arquivos crescem orgânico via hook.

**Médio:**
- Glob `{{SRC_ROOT}}/*/` pra ver as pastas
- Cria 1 doc por pasta-área
- 50-150 linhas cada (regras em [`docs/CONVENTIONS.md`](docs/CONVENTIONS.md))
- Popula o catálogo

**Grande:**
- Glob `{{SRC_ROOT}}/*/`
- Pergunta usuário: "Quais 3-5 áreas mais críticas?"
- Pra cada área crítica, despacha subagent (Explore/Plan) com
  prompt mastigado: "Lê os arquivos de `{{SRC_ROOT}}/<area>/`, gera
  doc de 50-150 linhas em `docs/project_map/<area>.md` no formato
  de [`docs/project_map/_GUIDE.md`](docs/project_map/_GUIDE.md)."
- Paraleliza 2-3 subagents simultâneos (independentes)
- Áreas não-críticas: marca em `docs/project_map/README.md` como
  "TODO, cresce via hook"
- Popula catálogo só pras áreas mapeadas; novas viram orgânicas

#### 6c. Popula o catálogo (3 lugares — não pula)

Pra cada doc criado, atualiza:

1. [`docs/project_map/README.md`](docs/project_map/README.md) — índice
2. [`.claude/hooks/check-sync-project-map.sh`](.claude/hooks/check-sync-project-map.sh) — array `RULES`
3. [`.claude/skills/sync-project-map/SKILL.md`](.claude/skills/sync-project-map/SKILL.md) — tabela de catálogo

Sem isso, hook não dispara, skill não sabe que o doc existe. As regras
de "consulta o mapa primeiro" nos agentes (analista, dev, escriba)
viram letra morta. **Popular o catálogo é parte do mapeamento, não
trabalho separado.**

#### 6d. Valide com `validate.sh`

Depois de popular, rode na raiz do projeto destino:

```bash
bash validate.sh
```

Confere: docs/project_map/ existe, catálogo populado, hook
registrado, CONVENTIONS.md presente. Se algo falhar, o script aponta.

### Passo 7 — Validar setup

Depois de copiar e injetar a referência, peça pro usuário:

- Confirmar que o arquivo de instruções (CLAUDE.md ou equivalente)
  reflete a realidade do projeto.
- Se ativou `sync-project-map`: confirmar que o catálogo do hook foi
  populado (ou que vai ser depois, incremental).
- Testar uma skill: pedir "`/dry-pass`" ou "`/polish`" e ver se
  dispara.
- Se o agente do destino NÃO é Claude Code: validar que ele consegue
  ler/seguir as skills em markdown via referência no arquivo de
  instruções nativo dele.

### Passo 8 — NÃO copiar este README pro destino

`project_zero/README.md` é meta — instrução de como aplicar o template.
Não tem por que ir junto pro projeto destino. **Pule este arquivo na
cópia.**

---

## Estrutura do template

```text
project_zero/
├── README.md                          # você está aqui — manual de uso
├── CLAUDE.template.md                 # esqueleto do CLAUDE.md
├── SECURITY_NOTES.md                  # arquivos/padrões sensíveis a NÃO tocar
├── .gitignore.template                # defaults sensatos (secrets, build, deps)
├── setup.sh                           # aplica o template num destino (Passo 5 trivial)
├── validate.sh                        # smoke test pós-setup
├── update_template.sh                 # compara template ↔ destino, sem aplicar
├── docs/
│   ├── CONVENTIONS.md                 # single source of truth de regras
│   ├── GLOSSARY.md                    # vocabulário do projeto (cresce orgânico)
│   ├── decisions/
│   │   ├── README.md                  # índice de ADRs leves
│   │   └── _TEMPLATE.md               # esqueleto pra criar decisão nova
│   └── project_map/
│       ├── README.template.md         # índice do project_map (canônico)
│       └── _GUIDE.md                  # como escrever docs compactos pra IA
├── .claude/
│   ├── skills/
│   │   ├── roadmap-review/SKILL.md              # sparring partner reativo + proativo
│   │   ├── dry-pass/SKILL.md                    # caça duplicação de dados/lógica
│   │   ├── polish/SKILL.md                      # qualidade estrutural
│   │   ├── sync-project-map/SKILL.md            # mantém docs em sync
│   │   ├── code-review-and-quality/SKILL.md     # review multi-axis antes de merge
│   │   ├── deprecation-and-migration/SKILL.md   # remoção segura de código / API / feature
│   │   ├── browser-testing-with-devtools/SKILL.md  # testes em browser (Chrome DevTools MCP)
│   │   └── task-retrospect/SKILL.md             # fechamento consciente de task
│   ├── agents/
│   │   ├── operador.md                # planejador Opus (demanda multi-papel)
│   │   ├── dev.md                     # implementador
│   │   ├── analista.md                # investigador read-only
│   │   └── escriba.md                 # mantém docs em sync (não toca código)
│   ├── hooks/
│   │   ├── check-sync-project-map.sh  # PostToolUse — reminder pós-edit
│   │   ├── check-session-lock.sh      # PreToolUse — aviso de arquivo reivindicado
│   │   └── on-stop-check.sh           # Stop — lembrete de fechamento
│   ├── settings.template.json         # registra os hooks acima
│   └── SESSION_LOCK.template.md       # coordenação de sessões paralelas
└── memory/
    └── _PATTERNS.md                   # padrões de auto-memory reutilizáveis
```

---

## Princípios por trás do template

1. **Doc otimizado pra IA, não pra humano.** Tabelas, `file:line`,
   compacto. Sem prosa explicativa. Código é a fonte; doc é GPS.
2. **Skill propõe, usuário escolhe, agente implementa.** Nenhuma skill
   refatora cega — sempre relata antes de mexer.
3. **Hook lembra a IA do que ela esquece.** Hook automático tem o
   custo cognitivo zero pra o usuário. Use pra coisas que drift
   silencioso (docs vs código, i18n, etc).
4. **Memória user-level vs project-level.** Padrões em `memory/` são
   user-level (servem qualquer projeto); regras específicas em
   `CLAUDE.md` são project-level.
5. **Placeholders explícitos.** Nada de "vai descobrindo" — todo
   template diz exatamente o que precisa ser preenchido.

---

## Quando NÃO usar este template

- Projeto descartável de 1 sessão (não vale o overhead)
- Repo onde o usuário não vai usar agente (template é todo agente-first)
- Subdiretório dentro de um projeto que já tem `CLAUDE.md` na raiz
  (CLAUDE.md aninhado é nicho)

---

## Estendendo o template

Quando descobrir um padrão novo que valeria reutilizar em projetos
futuros — uma skill nova, um hook útil, uma seção de `CLAUDE.md` que
sempre repete — **traga pra cá**, não deixe só no projeto onde nasceu.

Critério: se o padrão fizer sentido em 2+ projetos sem mudar quase
nada, é candidato. Se for super-específico do domínio (game, web app,
CLI, etc), pense em uma sub-variante (`project_zero/variants/game/`,
`project_zero/variants/web-app/`) em vez de inflar o tronco.
