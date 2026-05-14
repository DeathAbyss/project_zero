# Padrões de auto-memory

Referência rápida pra como organizar `MEMORY.md` e arquivos de memória
em projetos novos. Tipos de memória que valem a pena salvar, anti-padrões
a evitar, e estrutura mínima.

> **Não é um arquivo de memória.** É documentação do *sistema* de
> memória. O agente lê isso quando precisa decidir "salvo isso ou
> não?".

## Onde vive

A auto-memory **user-level** (mantida pelo agente em qualquer projeto)
fica em `~/.claude/projects/<encoded-path>/memory/`. Cada arquivo é uma
memória, com frontmatter (`name`, `description`, `type`).

`MEMORY.md` é o índice — uma linha por memória, formato:

```markdown
- [Title](file.md) — one-line hook
```

## Os 4 tipos

### 1. `user` — sobre o usuário

Role, expertise, preferências de comunicação. Ajuda a tailorizar
explicações ao perfil.

Bom exemplo:
> _user_role.md_: "Senior dev backend Go/Python; cuidando do frontend
> React por necessidade — frame explicações de frontend com analogia a
> backend."

Mau exemplo:
> "Usuário pediu pra eu rodar testes."  ← isso é state da conversa,
> não traço durável.

### 2. `feedback` — guidance sobre como trabalhar

Correções ("não faça X") **e** confirmações ("X foi a escolha certa").
Inclua **Por que** e **Como aplicar**.

Bom exemplo:
> _feedback_testing.md_:
> "Tests de integração tocam DB real, nunca mock.
> **Por que**: incidente Q3 onde mock divergiu do prod e migration quebrou.
> **Como aplicar**: ao criar test novo em qualquer pacote, conferir se a
> dep é DB. Se for, usar a fixture de DB do conftest."

### 3. `project` — contexto do trabalho em curso

Quem está fazendo o quê, por quê, até quando. Decai rápido — mantenha
atualizado.

**Sempre converter datas relativas pra absolutas** ("quinta" → "2026-03-05").

Bom exemplo:
> _project_freeze.md_: "Merge freeze a partir de 2026-03-05 para release
> mobile.
> **Por que**: cut da release branch.
> **Como aplicar**: PRs não-críticos agendados após essa data, flagar."

### 4. `reference` — onde achar info fora do código

Linear, Slack, Grafana, Notion, etc.

Bom exemplo:
> _ref_grafana.md_: "grafana.internal/d/api-latency é o dashboard de
> oncall — checar se mexer em request-path."

## O que NUNCA salvar

- Code patterns, convenções, paths, estrutura. → Lê o código.
- Git history, autores de commit. → Usa `git log/blame`.
- Fix recipes específicos. → Tá no commit / no PR.
- Algo já em `CLAUDE.md`.
- Estado efêmero da conversa atual.

**Vale para o usuário também**: se ele pede pra "salvar lista de PRs",
pergunte o que foi **surpreendente** sobre a lista — esse é o pedaço
que merece memória.

## Estrutura de cada arquivo

```markdown
---
name: <nome curto>
description: <1 linha — vai ser lida pelo agente pra decidir relevância>
type: <user | feedback | project | reference>
---

<conteúdo>

Para feedback/project, terminar com:

**Por que**: <razão concreta>
**Como aplicar**: <quando/onde isso se aplica>
```

## Manutenção

- `MEMORY.md` é índice. Linha curta, sem conteúdo. Conteúdo vai no arquivo.
- 200+ linhas de `MEMORY.md` corta no parser. Mantenha conciso.
- Memórias erradas saem da memória. Edite/delete em vez de empilhar.
- Antes de agir baseado numa memória que cita arquivo/função: confirmar
  que ainda existe.

## Quando usar memória vs. plan/task

- **Plan**: alinhamento de approach antes de implementar (conversa
  atual)
- **Task list**: passos da implementação (conversa atual)
- **Memória**: traço durável que vale entre conversas

Se vai usar só uma vez, plan/task. Se vale guardar pra próxima vez,
memória.
