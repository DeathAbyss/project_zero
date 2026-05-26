---
name: dry-pass
description: |
  Varre o projeto procurando informação duplicada e código que poderia
  consolidar em uma única fonte de verdade. Foco no problema clássico
  "tem essa info em 3 lugares, toda vez que mudo tenho que mudar em
  todos" — magic numbers repetidos, parallel data structures,
  copy-pasted logic, fórmulas que aparecem em 2+ arquivos sem dependência
  uma da outra, hardcoded values que deveriam vir de uma config central,
  i18n keys com texto inline duplicado, etc.

  Modo de uso é REATIVO. NÃO roda proativamente. Triggers manuais:
  "DRY pass", "varre o código procurando duplicação", "consolida
  fontes", "audita o projeto", "otimiza/polish o código",
  "encontra info replicada", "single source of truth pass".

  Fluxo: skill varre, RELATA com a lista priorizada de violações
  encontradas (sem mudar nada), espera o usuário escolher o que
  atacar. Só então implementa o fix. Nunca refatora sem aprovação —
  consolidar uma duplicação errada é pior que ter duplicação.
---

# DRY Pass

Quando o codebase tem informação espalhada em vários arquivos sem uma
fonte de verdade clara, mudanças viram bug-magnet: o agente atualiza
um lugar, esquece os outros, e a UI/lógica fica inconsistente. Esta
skill é o sweep periódico que cata essas armadilhas antes do bug.

## Quando rodar

**Sob demanda apenas.** Não há trigger automático — é audit, não
reflexo. Rodar quando:

- Usuário pede explicitamente ("varre", "DRY pass", "audita")
- Depois de uma fase grande de features (acumula débito)
- Antes de refatorações maiores (limpa o terreno)
- Quando o usuário se queixa "tive que mudar em 3 lugares"

**Não rodar:**

- Durante implementação de feature ativa (atrapalha foco)
- Com mudanças não commitadas pesadas no working tree (risco de
  perder trabalho na refatoração)

## O que procurar

### 1. Magic numbers / strings repetidos

Mesmo valor literal aparece em N arquivos sem constante exportada.

```text
// BAD — 30 e 5000 espalhados em vários arquivos
if (retries < 5) { sleep(30); ... }
const timeout = 5000;
const maxAttempts = 5;

// GOOD — uma constante central
import { MAX_RETRIES, RETRY_DELAY_MS } from "<constants module>"
```

Como pegar:
- `Grep` por valores numéricos suspeitos (timeouts, limites, retries,
  percentages) que aparecem em 3+ arquivos
- Strings/cores/IDs que repetem viram constante de domínio
- Strings de IDs que aparecem em código fora do módulo de dados viram
  constantes

### 2. Parallel data structures

Duas listas que precisam ser mantidas sincronizadas manualmente.

```js
// BAD — ORDER e items dessincronizam
export const ITEMS = { a: {...}, b: {...} };
export const ITEMS_ORDER = ['a', 'b'];   // pode esquecer aqui

// GOOD — derivar do mesmo source
export const ITEMS = { ... };
export const ITEMS_ORDER = Object.keys(ITEMS);
```

Como pegar:
- `Grep` por arrays exportados que listam IDs e procurar o objeto
  correspondente — checar se a array é derivável
- Switch statements grandes que listam IDs vs arquivo de dados — se
  os ids são iguais, talvez o switch deva iterar a tabela
- Validations que enumeram tipos vs a lista canonical

### 3. Copy-pasted logic blocks

Mesma lógica em 2+ funções com pequenas variações que poderiam
parametrizar.

```js
// BAD — duas funções 90% iguais
function drawA(ctx, x, y, level) { /* 30 linhas */ }
function drawB(ctx, x, y, level) { /* 30 linhas, 3 diferentes */ }

// GOOD
function drawItem(ctx, x, y, level, spec) { ... }
```

Como pegar:
- `Grep` por nomes de função em pares
- Procurar por padrões "if type === X { ... } else if type === Y { ... }"
  com blocos longos
- Funções em arquivos diferentes que fazem coisas similares

### 4. Hardcoded values que deveriam vir de config

Valores inline em arquivos de runtime quando deveriam vir de uma
tabela canonical.

```text
// BAD — limite hardcoded espalhado
if (attempts === 30) lockAccount();

// GOOD — vem da config
if (attempts === config.maxAttempts) lockAccount();
```

Como pegar:
- Valores que aparecem em arquivos de config — `Grep` o valor numérico
  fora desses arquivos
- Comparações que usam números literais

### 5. i18n keys com texto duplicado

Mesma string em 3 keys de i18n diferentes (escapou da consolidação).

Como pegar:
- Ler o arquivo de strings e procurar valores idênticos em
  chaves diferentes — talvez intencional (contextos diferentes), mas
  vale flagar pra o usuário decidir

### 6. Cálculos repetidos

Mesma fórmula expressa em 2+ lugares.

```text
// BAD — fórmula repetida em 3 lugares
const total = amount * (1 + taxRate) - discount;
const subtotal = entry.amount * (1 + entry.taxRate) - entry.discount;

// GOOD — função em utils
import { computeTotal } from "<utils module>";
```

Como pegar:
- Operações matemáticas com nomes de variáveis específicos do domínio
  repetidas em arquivos diferentes
- Ratios e percentages calculados inline

## Como o output é apresentado

A skill NÃO refatora cegamente. Saída esperada:

```text
DRY Pass — N violações encontradas:

🔴 ALTO IMPACTO (consolidar primeiro)
1. [arquivo: ...]: <descrição da duplicação>
   Arquivos afetados: A, B, C
   Sugestão: <onde consolidar>
   Risco: <baixo/médio/alto> + porquê

🟡 MÉDIO
...

🟢 BAIXO (cosmético / pode adiar)
...
```

Cada item tem:
- Localização exata (arquivo + linhas se possível)
- Quantos lugares são afetados
- Sugestão concreta (não vago "deve melhorar")
- Avaliação de risco — refatorar mexe em fluxo crítico? mexe em
  save/persistência? muda comportamento observável?

Depois disso, **espera o usuário escolher** quais itens atacar. Só
então implementa o fix do que ele autorizou. Refatoração com pressa
quebra muito mais do que duplicação convive.

## Princípios de execução

- **Uma consolidação por vez.** Nunca empacotar 5 refactors num
  commit só. Quebra atribuição de bug, dificulta revert.
- **Verificar antes/depois.** Pra fixes que mudam comportamento
  observável, rodar o projeto e checar que continua funcionando como
  antes da refatoração.
- **Não consolidar duplicação intencional.** Algumas duplicações estão
  lá de propósito. Antes de mexer, ler comentários e MEMORY pra ver
  se é "duplicado conscientemente".
- **Manter contratos públicos.** Funções exportadas usadas em N
  lugares — preservar a assinatura ou fazer migration sweep completa.
- **i18n: mexeu em strings, mexeu em todos os idiomas.** Sem exceção.

## Áreas de atenção específicas do projeto

> Lista viva. Adicionar conforme descobrir hotspots de duplicação.

- _(vazio — popule conforme rodar a skill e descobrir padrões)_

## Conclusão da skill

Ao terminar a passada, sempre:

1. Listar o que foi consolidado (com arquivos e linhas afetados)
2. Listar o que foi flagado mas NÃO atacado (com motivo)
3. Recomendar próxima passada — quando rodar de novo (depois de N
   features novas, depois de fase do roadmap, etc)
