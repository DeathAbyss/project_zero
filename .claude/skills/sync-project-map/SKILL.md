---
name: sync-project-map
description: |
  Mantém os docs em `docs/project_map/` em sync com o estado real do
  código. Sempre que o agente modifica um arquivo de produção, esta
  skill é chamada DEPOIS da implementação pra varrer o doc associado e
  atualizar refs `file:line`, símbolos exportados, valores numéricos
  citados, e seções estruturais que ficaram defasadas.

  Triggers: o agente deve invocar esta skill proativamente após editar
  arquivos cobertos pelo catálogo abaixo. O hook
  `.claude/hooks/check-sync-project-map.sh` dispara um reminder
  automaticamente quando isso acontece. Também pode ser chamada
  manualmente: "audita o project_map", "verifica se docs estão em sync",
  "revisa o doc do X", "varre project_map".

  AUTO-EXTENSÃO: se descobrir arquivo NOVO no projeto que não tem doc
  associado, a skill PERGUNTA ao usuário: estende doc existente OU cria
  doc novo. Catálogo aqui precisa ser estendido — senão a próxima
  edição naquele arquivo passa em silêncio.
---

# sync-project-map

> **Nota sobre multiagente.** Se o projeto tem o sub-agente `escriba`
> ativo (existe [`.claude/agents/escriba.md`](../../agents/escriba.md)),
> **ele é o executor desta skill**. O agente principal deve **despachar
> o escriba** em vez de executar este workflow diretamente. Esta
> SKILL.md continua sendo a **documentação canônica** — o escriba a lê
> como referência ao receber a tarefa. Sem escriba ativo (projeto sem
> multiagente), o agente principal invoca esta skill direto.

Mantém `docs/project_map/` vivo. Sem isso o investimento em ter docs
otimizados pra IA vira arquivo morto em poucas semanas.

## Quando rodar

**Reflexo automático** (via hook `check-sync-project-map.sh`):
- Edit em qualquer arquivo do catálogo abaixo.

**Sob demanda** (user fala):
- "audita o project_map"
- "verifica os docs"
- "revisa o doc do X"
- "varre project_map"
- "está em sync?"

**Pula quando**:
- Mudança puramente cosmética (cor, animação, formatação).
- Refactor sem novo símbolo público / sem novo arquivo.
- Comentário ou string i18n só.

## Catálogo arquivo → doc

> Esta tabela é o coração da skill. Cresce com o projeto. Preencha
> conforme criar docs em `docs/project_map/`.

| Path padrão | Doc |
|---|---|
| _(vazio — popule conforme criar docs)_ | _(doc.md)_ |

> **Exemplo (apagar quando popular)**:
>
> | `src/core/*.js` | `core.md` |
> | `src/api/auth.js` | `auth.md` |
> | `src/db/migrations/*.sql` | `database.md` |

## Workflow

### 1. Identifique o que mudou

Pra cada arquivo editado:
- Resolve mapping no catálogo acima.
- Se múltiplos docs (ex: arquivo cobre 2 áreas), checar AMBOS.
- Se sem mapping → ver "Auto-extensão" abaixo.

### 2. Leia o doc + o arquivo real

Pra cada par `(arquivo, doc)`:
- Read `docs/project_map/<doc>.md`.
- Read seções do arquivo real referenciadas no doc (especialmente
  `file:line` citados).

### 3. Verifique drift

Checks na ordem:

**a. Refs `file:line` válidos?**
- Doc cita `[arquivo.js:N](path)` — o conteúdo da linha N ainda bate
  com o que o doc diz?
- Função / classe / const ainda existe naquele número de linha (±5)?

**b. Símbolos exportados batem?**
- Doc menciona `getX()`, `class Y`, `const Z`?
- Esses símbolos ainda existem no arquivo? Ainda estão exportados?
- Renome → atualizar doc.

**c. Valores numéricos citados batem?**
- Doc cita valores específicos?
- Confirma com o def real. Se mudou → atualizar.

**d. Novos exports / seções não documentados?**
- Adicionou função/classe/const novo?
- Vale a pena documentar? (regra: "público" sim, "interno usado em 1
  lugar" não)

**e. Renames de arquivo?**
- Arquivo movido / renomeado → atualizar TODAS as refs no project_map
  (não só o doc principal).

### 4. Reporte achados

Formato compacto pro user:

```text
project_map/<doc>.md:
  - L42 ref `<arquivo>:101` ainda válida ✓
  - L75 cita "rate × 0.6" — bate com source ✓
  - L88 menciona `setX()` mas função foi renomeada pra `applyX()` ⚠️
  - Novo método `Y.copyFrom()` adicionado, doc não menciona ⚠️
```

### 5. Aplique updates aprovados

User confirma → edit nos docs. Manter:
- Compactação (50-150 linhas por doc).
- `file:line` clicáveis.
- Tabelas em vez de prosa.
- Cross-links em vez de duplicação.

### 6. Auto-extensão

Se durante a varredura você descobre:

**a. Arquivo novo no projeto sem mapping no catálogo:**
- Sugerir ao user: estender doc existente OU criar doc novo.
- Pra mecânica nova: convenção é `mechanics_N.md` numerado.
- Pra área nova: doc dedicado (ex: `multiplayer.md`).

**b. Padrão repetido em vários arquivos**:
- Considerar consolidar num doc novo.

**c. Após estender o catálogo**, atualizar:
- Esta SKILL.md (tabela acima).
- `docs/project_map/README.md` (índice).
- `.claude/hooks/check-sync-project-map.sh` (PATTERNS) se for novo
  arquivo fora do path padrão.

## Regras duras

1. **Manter docs compactos** — 50-150 linhas. Doc inflado = IA gasta
   tokens lendo. Se passar muito, dividir.
2. **NÃO duplicar info entre docs** — cross-link em vez de copiar.
3. **`file:line` em tudo** — sem isso o doc vira prosa inútil. Confira
   o número antes de salvar.
4. **Sem exemplos de código** — código real está no fonte. Doc é GPS,
   não tutorial.
5. **Sem prosa explicativa longa** — tabela > parágrafo, sempre.
6. **Update deve mencionar EXATAMENTE o que mudou** — "atualizei doc"
   não basta. Listar arquivo:linha + diff conceitual.

## Coordenação com outras skills

- **dry-pass**: identifica duplicação de DADOS. Não conflita.
- **polish**: identifica code debt. Pode triggerar mudanças que esta
  skill detecta como drift.

## Output esperado

No fim do turno onde a skill rodou, reportar:

```text
sync-project-map:
- Arquivos editados: [lista]
- Docs verificados: [lista]
- Drift encontrado: [N issues]
- Atualizado: [lista de docs com 1-line diff]
- Não tocado: [docs sem drift]
- Auto-extensão: [arquivos novos sem mapping, se houver]
```
