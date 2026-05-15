# project_zero — Template base pra novos projetos

> **TL;DR humano:**
>
> 1. Copia esta pasta pra raiz do seu projeto novo
> 2. Abre uma sessão com seu agente (Claude Code, Cursor, Cline, etc.)
> 3. Diz: "Leia o `project_zero/README.md`."
> 4. O agente auto-detecta tudo, aplica o template, e te pergunta SÓ o
>    que não conseguir derivar (~1 bloco de confirmação, 1-3 min).
>
> Atalho direto: `bash project_zero/setup.sh` (assume Claude Code) ou
> `bash project_zero/setup.sh --agent cursor` pra outros agentes.
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

> **Princípio.** Se o usuário pediu pra ler este README, a intenção é
> APLICAR o template no projeto atual. **Zero perguntas obrigatórias.**
> O agente lê o repo, infere tudo (stack, descrição, run command, etc.)
> a partir do código + manifestos + README do destino, aplica o
> template, e apresenta TUDO num bloco único de confirmação no fim —
> com a fonte de cada valor ao lado. User só corrige o que tiver
> errado, ou diz "ok" pra aceitar defaults.
>
> Pergunta só acontece em **edge cases**:
>
> - Múltiplos arquivos de instrução de agentes diferentes detectados
>   no destino (qual canonical?)
> - Projeto genuinamente vazio onde NENHUMA inferência funciona (raro)
>
> Não pergunta nunca: "quer aplicar?", "onde docs?", "quais skills?",
> "mapear agora?", "como tratar CLAUDE.md existente?". Tudo isso tem
> regra fixa.

### Etapa 1 — Auto-detect (zero perguntas se der)

Roda essas detecções em paralelo. Tudo resolvido por código, sem
perguntar.

**a) Agente alvo** — Glob na raiz do destino:

```text
Glob: CLAUDE.md
Glob: .cursorrules
Glob: .cursor/rules/*.mdc
Glob: .clinerules
Glob: .windsurfrules
Glob: .aider.conf.yml
Glob: .github/copilot-instructions.md
Glob: AGENTS.md
```

| Match | Agente | Flag setup.sh |
|---|---|---|
| `CLAUDE.md` ou nenhum match | Claude Code | `--agent claude` (default) |
| `.cursorrules` ou `.cursor/rules/*.mdc` | Cursor | `--agent cursor` |
| `.clinerules` | Cline | `--agent cline` |
| `.windsurfrules` | Windsurf | `--agent windsurf` |
| `.aider.conf.yml` | Aider | `--agent aider` |
| `.github/copilot-instructions.md` | Copilot | `--agent copilot` |
| `AGENTS.md` | Genérico | `--agent generic` |

Política:

- **1 match** → usa esse agente
- **0 matches** → assume `claude` (default mais comum). Não pergunta.
- **2+ matches diferentes** → ÚNICA situação onde PERGUNTA:
  "Detectei X e Y. Qual é o canonical? (vou mexer só num deles)"

#### Edge case: monorepo

Pastas como `packages/`, `apps/`, `services/` na raiz?

- Default = **raiz do monorepo** (rules globais). Menciona no bloco
  final pra user redirecionar se quiser sub-pasta específica.

**b) Destino fresh ou já tem setup?**

Confere no destino:

- Tem `CLAUDE.md` (ou equivalente do agente detectado)?
- Tem `<NS>/docs/` populado?

Política:

- Nada disso existe → modo **"fresh apply"** (copia tudo)
- Algum existe → modo **"gap-only"** (`copy_if_absent` — só adiciona o
  que falta, não toca o que já tem). Nunca sobrescreve cego.

**c) Stack + run/test commands** — Read em arquivos de manifesto:

| Arquivo encontrado | Linguagem | Run/test inferido de |
|---|---|---|
| `package.json` | JS/Node (TS se tem `tsconfig.json`) | `scripts.dev` ou `scripts.start` / `scripts.test` |
| `Cargo.toml` | Rust | `cargo run` / `cargo test` |
| `pyproject.toml` ou `requirements.txt` | Python | `scripts` (pyproject) ou marcar pra confirmação |
| `go.mod` | Go | `go run .` / `go test ./...` |
| `pom.xml` ou `build.gradle` | Java | `mvn exec:java` / `mvn test` (ou Gradle equivalente) |
| `index.html` puro | Web vanilla | `python -m http.server` ou similar |
| Nenhum dos acima | "Genérico" | Marca pra confirmação no bloco final |

**d) `PROJECT_NAME`** — usa o nome da pasta-raiz do destino como default.

**e) Idioma** — `LANGUAGE` / `USER_LOCALE` = inferir do idioma da conversa
(PT-BR se o user falou em português, senão EN, etc.).

### Etapa 2 — Rodar setup.sh

```bash
bash project_zero/setup.sh --agent <auto-detectado> [destino]
```

O script:

- Copia o template pra `<NS>/...` no destino (docs vão em `<NS>/docs/`)
- Modo gap-only: `copy_if_absent` já só adiciona o que falta
- Reescreve refs `.claude/` → `<NS>/` se non-Claude
- Mescla `.gitignore` (adiciona linhas novas, não duplica)

### Etapa 3 — Gerar arquivo de instruções do agente

Substitui placeholders do `CLAUDE.template.md` com os valores derivados
na Etapa 1 e escreve no arquivo nativo do agente:

| Agente | Destino |
|---|---|
| Claude Code | `CLAUDE.md` |
| Cursor (legacy) | `.cursorrules` |
| Cursor (modular) | `.cursor/rules/project.mdc` (com frontmatter `description: "Project rules"` + `globs: ["**/*"]`) |
| Cline | `.clinerules` |
| Windsurf | `.windsurfrules` |
| Aider | `CONVENTIONS.md` (raiz — Aider lê automático) |
| Copilot | `.github/copilot-instructions.md` |
| Genérico | `AGENTS.md` |

**Se o arquivo já existir no destino**: NÃO sobrescreve, NÃO pergunta.
Regra fixa: **preserva 100% do conteúdo existente** e **anexa o
template no fim**, separado por um divisor visual. Formato exato do
divisor:

```markdown
<!-- ─────────────────────────────────────────── -->
<!-- Conteúdo adicionado por project_zero em YYYY-MM-DD -->
<!-- Preserva o que estava acima. Revise/integre/pode conforme fizer sentido. -->
<!-- ─────────────────────────────────────────── -->
```

Substitui `YYYY-MM-DD` pela data corrente. Depois do divisor, vem o
conteúdo do `CLAUDE.template.md` com placeholders substituídos. Razão:
nunca destrói trabalho do user; sempre adiciona valor; user reorganiza
manual quando quiser.

#### Placeholders pra substituir (TODOS auto-deriváveis)

Princípio: **agente lê o repo e infere; nenhum campo é "sempre
perguntado"**. Tudo vai pro bloco de confirmação final pra user revisar.

| Placeholder | Cascata de derivação |
|---|---|
| `{{PROJECT_NAME}}` | (1) Nome da pasta-raiz do destino; (2) `name` em `package.json`/`Cargo.toml`/`pyproject.toml`/`pom.xml` |
| `{{PROJECT_DESCRIPTION}}` | (1) `description` em `pom.xml`/`package.json`/`Cargo.toml`/`pyproject.toml`; (2) primeira frase do `README.md` do destino após o título; (3) inferir lendo 2-3 arquivos-chave do código. Só **pergunta** se TUDO falhar (projeto greenfield vazio) |
| `{{STACK}}` | Etapa 1c |
| `{{PLATFORM}}` | Inferir do conteúdo (deps web → "web"; `electron` → "desktop"; `react-native` → "mobile"; CLI binary → "CLI"). Ambíguo? Deixa "TBD" e marca pra confirmação. |
| `{{SRC_ROOT}}` | Olhar `src/`, `lib/`, `app/`. Default `src/`. Vazio se raiz é o código. |
| `{{RUN_COMMAND}}` | Etapa 1c |
| `{{TEST_COMMAND}}` | Etapa 1c (`nenhum` se sem testes) |
| `{{LANGUAGE}}`, `{{USER_LOCALE}}` | Etapa 1e |

Pra projetos sem i18n, remove seções relacionadas a `{{LANGUAGE}}`.
Pra projetos sem testes, deixa `{{TEST_COMMAND}}` = `nenhum`.

**Regra de ouro: agente lê e interpreta antes de perguntar.** Se a
informação existe no repo, deriva. Pergunta é último recurso, não
primeiro.

### Etapa 4 — Bloco único de confirmação + report final

Mostra TUDO derivado num bloco, com a fonte ao lado. Resposta vazia
= aceita defaults. User só corrige o que tiver errado.

```text
✓ Setup aplicado.

Agente:    <claude>          ↳ detectei CLAUDE.md
Namespace: <.claude>
Modo:      <fresh-apply | gap-only — adicionei N arquivos novos>
Stack:     <Spring Boot + Java 21>    ↳ pom.xml
Run:       <./mvnw spring-boot:run>   ↳ mvnw + pom.xml
Test:      <./mvnw test>              ↳ mvnw + pom.xml
SRC_ROOT:  <src/main/java/>           ↳ convenção Maven

Placeholders no CLAUDE.md:
  PROJECT_NAME: <SGC>                 ↳ nome da pasta
  PROJECT_DESCRIPTION:
    <Sistema de Gestão de Concessões Florestais — Backend REST Spring Boot>
                                      ↳ pom.xml <description>
  PLATFORM: <web/api>                 ↳ Spring Boot indicia API HTTP
  LANGUAGE/USER_LOCALE: <pt-BR>       ↳ conversa em PT

Arquivo de instruções: CLAUDE.md já existia (19 linhas). Preservei
intacto; anexei conteúdo do template DEPOIS, separado por divisor.

Skills ativadas: todas (8). Pra desativar uma: apaga
  .claude/skills/<nome>/SKILL.md.

Arquivos copiados: <N>
Arquivos pulados (já existiam): <N>

Mapeamento (.claude/docs/project_map/) ficou VAZIO de propósito —
cresce orgânico via hook conforme tu editar áreas concretas. Pra
mapear tudo de uma vez agora, pede: "mapeia o projeto inteiro".

Pra corrigir algum valor: me fala "PROJECT_DESCRIPTION tá errado, é Y".
Pra prosseguir: começa a usar normal.
```

### Quando o template NÃO deve auto-aplicar

- User pediu explicitamente "só leia / só explique / só revise" — aí
  lê e devolve resumo, sem aplicar.
- Destino é o próprio `project_zero/` — não aplique no template.
- User disse "não quero template aqui / cancela" — para imediato.

### Regra dura — onde docs de IA vivem

**Docs do template SEMPRE vão pra `<NS>/docs/` do destino**, onde
`<NS>` é o namespace do agente alvo (`.claude` pra Claude Code,
`.cursor` pra Cursor, etc.).

**NUNCA crie `docs/` solto na raiz** — `docs/` na raiz é território
do usuário (docs humanos, especificações). Se existe, **ignora**: não
mescla, não migra, não invade.

| Cenário no destino | Ação |
|---|---|
| `<NS>/docs/` já existe | Reusa. Adiciona só o que falta. |
| `<NS>/docs/` não existe | Cria e popula. |
| `docs/` na raiz existe (qualquer conteúdo) | Ignora. Não é problema do template. |

O `setup.sh --agent <X>` já reescreve `.claude/` → `<NS>/`
automaticamente.

**Se você (a IA) está prestes a criar `docs/` na raiz do projeto da
pessoa, PARE.** Use o namespace correto. Replicar estrutura em `docs/`
raiz é o bug que essa regra previne.

### Mapeamento do projeto destino (orgânico, NÃO bloqueia setup)

`<NS>/docs/project_map/` é o que faz hooks/skills "consultar o mapa
antes de greppar" funcionarem. Mas é **opcional no setup inicial** —
cresce orgânico:

- Default: project_map/ fica vazio (só `README.md` + `_GUIDE.md`).
- Hook `check-sync-project-map` lembra de atualizar o doc quando user
  edita arquivo do catálogo.
- Pra acelerar (greenfield/pequeno): user pode pedir "mapeia o projeto
  inteiro" depois — aí roda mapeamento batch.

Estratégia de mapeamento por tamanho (greenfield / pequeno / médio /
grande) está em [`.claude/docs/project_map/_GUIDE.md`](.claude/docs/project_map/_GUIDE.md).
O agente lê quando precisar.

### Não copie este README pro destino

`project_zero/README.md` é meta — instrução de como aplicar. Não tem
por que ir junto pro projeto destino. **Pule este arquivo na cópia.**

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
├── .claude/
│   ├── docs/                          # docs de IA — TUDO aqui, NUNCA solto em /docs
│   │   ├── CONVENTIONS.md             # single source of truth de regras
│   │   ├── GLOSSARY.md                # vocabulário do projeto (cresce orgânico)
│   │   ├── decisions/
│   │   │   ├── README.md              # índice de ADRs leves
│   │   │   └── _TEMPLATE.md           # esqueleto pra criar decisão nova
│   │   └── project_map/
│   │       ├── README.template.md     # índice do project_map (canônico)
│   │       └── _GUIDE.md              # como escrever docs compactos pra IA
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
