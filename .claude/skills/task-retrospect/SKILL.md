---
name: task-retrospect
description: |
  Skill manual de fechamento consciente da task. Faz varredura do que
  mudou (git status + diff) e devolve lista priorizada de "ações de
  fechamento" pro usuário aprovar antes de declarar a task feita.

  Triggers manuais: "fecha a task", "task-retrospect", "retrospect",
  "varre o que mudou pra fechar", "/task-retrospect".

  NÃO é automática. NÃO substitui o checklist "Antes de fechar a task"
  do CLAUDE.md — complementa a parte de aprendizado e propagação que o
  checklist só lista como bullet genérico.

  Coordenação: o hook `on-stop-check.sh` injeta um lembrete enxuto ao
  fim de turnos com mudança. Esta skill é a versão ATIVA que faz a
  varredura concreta quando o usuário quer ação.
---

# task-retrospect

Skill de fechamento consciente. Roda ao final de task não-trivial pra
verificar propagações que escapam do checklist genérico (memory, ADRs,
deps, i18n, version bump, project_map drift).

## Quando rodar

- Task envolveu 3+ edits ou tocou área crítica
- Surgiu insight surpreendente durante a task
- Mudou dep, config, schema, ou contrato de API
- Hook `on-stop-check.sh` injetou o lembrete e quer ação concreta
- Antes de commitar task grande, pra revisão "fora do diff"

## Quando NÃO rodar

- Edit puramente cosmético (typo, formatação)
- Sessão só de leitura/investigação (sem mudança no working tree)
- Task já fechada e commitada
- Mudança trivial (< 3 linhas em 1 arquivo)

## Workflow

### 1. Coleta o que mudou

```bash
git status --porcelain      # lista arquivos
git diff --stat HEAD        # magnitude por arquivo
git diff --name-only HEAD   # paths puros
```

Categoriza por área:
- `src/` — código de produção
- `.claude/docs/` — documentação
- `package.json` / `requirements.txt` / `Cargo.toml` / `go.mod` — deps
- `.env.example` / config files — configuração
- `tests/` — cobertura
- `CLAUDE.md` / outros agent files — instrução pro agente

### 2. Classifica cada mudança

Pra cada arquivo modificado, marca os atributos abaixo:

| Categoria | Pergunta |
|---|---|
| **project_map** | Path está no catálogo do hook `check-sync-project-map.sh`? Doc afetado existe em `.claude/docs/project_map/`? |
| **memory** | Surgiu insight surpreendente durante a task? Padrão repetido? Gotcha? Decisão não-óbvia que vale traço durável? |
| **ADR** | Decisão arquitetural foi tomada (escolha de lib, padrão, tradeoff)? Vale registrar em `.claude/docs/decisions/`? |
| **deps** | Adicionou dep nova? Removeu? Bumped versão? Implicações de licença/security? |
| **i18n** | Se o projeto tem i18n: adicionou string visível? Cobre todos os idiomas suportados? |
| **version bump** | Algum manifesto do projeto (`package.json`, `pom.xml`, `Cargo.toml`, `pyproject.toml`, `go.mod`, manifest de PWA, etc.) tem version field que a mudança exige bumpar? |
| **CLAUDE.md** | Surgiu gotcha novo / convenção implícita / regra que outra IA repetiria errado? |
| **GLOSSARY** | Introduziu termo de domínio novo que vale registrar? |
| **SECURITY_NOTES** | Tocou arquivo sensível que merece registro? Adicionou padrão a evitar? |

### 3. Devolve lista priorizada

Formato:

```text
## Ações de fechamento

### Prioridade alta (faz agora, baixo custo, alto valor)
- [ ] project_map: .claude/docs/project_map/auth.md cita `token.ext:67`, mudou pra :74
- [ ] deps: lib X adicionada no manifesto — registrar no README?

### Prioridade média (vale considerar antes de commitar)
- [ ] memory: durante a task descobri que abordagem Y resolve a classe de bugs Z (gotcha vale durar)
- [ ] CLAUDE.md: convenção "prefixo `async` pra funções não-bloqueantes" emergiu — documentar?

### Prioridade baixa (geralmente pode pular ou deixar pra depois)
- [ ] i18n: "Login" adicionada em pt-BR.json — verificar en-US.json
- [ ] version bump: package.json em 0.3.2, mudança não-breaking pode ficar pra próxima
```

### 4. Aguarda decisão do usuário

**NÃO aplica nada sozinho.** Lista, pergunta, espera aprovação por item.

Pra cada item aprovado:
- `project_map` drift → despacha sub-agente `escriba` OU invoca skill `sync-project-map`
- `memory` → salva memória nova (sistema auto-memory)
- `ADR` → cria `.claude/docs/decisions/<num>-<slug>.md` baseado em `_TEMPLATE.md`
- `deps` mudança → atualiza README/dependencies section
- `i18n` faltante → completa traduções
- `version bump` → edita campo `version` no arquivo apropriado
- `CLAUDE.md` update → edita seção Gotchas ou Regras duras

## Regras duras

1. **Nunca aplica sem aprovar.** Skill é proposta, não execução.
2. **Sem inflação.** Não inventa propagação se não tem evidência
   concreta no diff.
3. **Prioridade honesta.** "Alta" = clara consequência negativa se
   pular. "Média" = vale considerar mas mundo não acaba. "Baixa" =
   pode ficar pra próxima sessão.
4. **Coordena com `sync-project-map`.** Se detectar drift de doc,
   sugere despachar `escriba` (multiagente ativo) ou rodar a skill
   diretamente.

## Coordenação com outras skills

- **sync-project-map**: foco em `.claude/docs/project_map/` apenas. Esta
  skill chama essa quando detecta drift.
- **polish**: foco em qualidade estrutural. Pode triggerar se
  detectar padrão repetido 3+ vezes.
- **dry-pass**: foco em duplicação de dados. Pode triggerar se
  detectar valor/regra duplicada.
- **code-review-and-quality**: roda ANTES de merge. Esta roda ANTES
  de declarar task fechada. Sequência: task-retrospect → review →
  merge.

## Output esperado

Lista categorizada por prioridade. Sem aplicação. Decisão fica com o
usuário. Após aprovação, executa os itens individuais.
