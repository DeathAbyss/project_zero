---
name: polish
description: |
  Audita qualidade estrutural do código — funções duplicadas, boilerplate
  copiado entre módulos, arquivos enormes, acoplamento implícito,
  traduções parciais, dead code, TODOs antigos, naming inconsistente,
  comentários stale, imports não usados, strings escapando do i18n,
  assets quebrados, i18n keys mortas. Foco em ESTRUTURA, não em dados
  duplicados (isso é da `dry-pass`).

  Modo de uso é REATIVO. NÃO roda proativamente. Triggers manuais:
  "polish pass", "passa o polish", "audita qualidade do código",
  "varre código pra refatorar", "o que dá pra limpar?", "polish do
  projeto", "limpa o código".

  Fluxo: skill varre, RELATA com a lista priorizada de achados (sem
  mudar nada), espera o usuário escolher o que atacar. Só então
  implementa o fix do que ele autorizou. Nunca refatora sem aprovação —
  consolidação errada é pior que código bagunçado.
---

# Polish Pass

Codebase cresce em rajadas — feature nova entra, módulos se parecem,
helpers se repetem, i18n acumula chave fantasma, comentário fica stale.
Esta skill é a varredura periódica de QUALIDADE estrutural: pega os
sinais que `dry-pass` (dados) não cobre.

## Quando rodar

**Sob demanda apenas.** Não tem trigger automático.

Bons momentos:
- Final de uma fase do roadmap (acumula débito de polish)
- Antes de uma refatoração grande (mapeia o terreno)
- Quando o usuário se incomodar com algo ("isso aqui tá tudo igual")
- Sessão ociosa entre features

**Não rodar:**
- Durante feature ativa (atrapalha foco)
- Com working tree sujo de mudanças não commitadas pesadas

## Relação com outras skills

| Skill | Foco |
|---|---|
| **polish** (esta) | Estrutura de código: funções, arquivos, módulos, i18n incompleto, dead code |
| `dry-pass` | Dados/valores espalhados: magic numbers, parallel arrays, hardcoded em vez de config |
| `sync-project-map` | Docs de project_map em sync com código |

Se o achado for sobre VALOR repetido, é território da `dry-pass` —
flagar e remeter, não atacar aqui.

## O que procurar

### 1. Funções duplicadas ou quase-duplicadas

Funções com lógica praticamente idêntica espalhadas em arquivos
diferentes. **Avaliar se de fato são a mesma coisa antes de
consolidar** — duas funções que parecem iguais mas evoluem em
direções diferentes vão divergir e quebrar.

Como pegar:
- `Grep` por nomes que se repetem entre arquivos.
- Comparar corpo das funções com o mesmo nome em arquivos diferentes
  — diff curto = candidato forte.
- Funções privadas reaparecendo em múltiplos módulos são o sinal
  mais comum.

Cuidado: assinatura igual mas comportamento intencionalmente diferente
NÃO consolidar — só flagar pra revisão.

### 2. Candidatos a módulo `utils/` centralizado

Helpers puros (sem dep de state) que aparecem em N lugares e
deveriam viver num módulo central.

Categorias típicas:
- Formatação numérica: `formatCurrency`, `formatNumber`, `formatPercent`
- Formatação de tempo: `formatDuration`, `formatRelative`, `formatDate`
- Formatação de texto: `truncate`, `capitalize`, `pluralize`
- Cores e paleta: `hexToRgb`, `lightenColor`, `mixColor`
- Math util: `clamp`, `lerp`, `smoothstep`, `wrap`

Cuidado: pure functions only. Helper que precisa de state não vai
pra utils — fica como método ou helper de domínio.

### 3. Módulos com boilerplate idêntico

Modais e overlays seguem padrão similar (backdrop, painel central,
título, botões fechar/confirmar). Quando 3+ módulos têm o mesmo
esqueleto, vale extrair componente.

Cuidado: NÃO extrair se as instâncias evoluem em direções diferentes.
Componente compartilhado vira gambiarra com 10 props opcionais. Só
extrair quando o esqueleto é genuinamente o mesmo.

### 4. Arquivos > 800 linhas

Acima de 800 vira sinal forte pra dividir, mas sem refator forçado —
flagar e analisar.

Como pegar (adapte o glob à extensão da stack):
```bash
find <SRC_ROOT> -name "*.<ext>" -exec wc -l {} + | sort -rn | head -20
```

Para cada arquivo grande, identificar **limites lógicos naturais**:
- Métodos privados que poderiam virar módulo separado
- Subseções marcadas por comentário — candidatos óbvios a split
- Classes com responsabilidades misturadas

Cuidado: split por split é ruim. Se o arquivo grande é coeso, mover
métodos pra fora vira indireção sem ganho.

### 5. Acoplamento implícito

Mapear o grafo de imports pra detectar:
- **Imports cíclicos** (A importa B, B importa A) — sintoma de
  responsabilidade mal-dividida
- **God modules** (módulo importado por 30+ arquivos) — sinal de
  agregação demais
- **Acoplamento entre camadas** (UI importando direto de data quando
  deveria passar por sistema)

Cuidado: alguns god modules SÃO legítimos — plumbing transversal.
Não tentar quebrar à força.

### 6. Traduções faltando

Arquivos de i18n com entradas faltando, vazias, ou copy-paste sem
traduzir.

Como pegar:
- Parsear o arquivo de strings e listar entradas onde alguma língua
  está ausente, vazia, ou igual a outra.
- Detectar texto na língua errada (heurística: acentos pt-BR em
  campos en/es; caracteres CJK ausentes em zh).

Regra dura: ao consertar, atualizar em TODOS os idiomas. Faltas
parciais voltam pra lista na próxima passada.

### 7. Dead code

- **Funções exportadas sem importador**.
- **Métodos privados não chamados**.
- **Branches inalcançáveis**.
- **Variáveis declaradas e nunca lidas**.
- **`console.log` esquecido** (debug residual).

Cuidado: hooks/eventos podem parecer não-chamados mas são chamados
via reflection pelo runtime — checar a interface da classe base
antes de marcar.

### 8. TODOs / FIXMEs antigos

Coletar comentários `TODO`, `FIXME`, `HACK`, `XXX`, `WIP` e priorizar.
Muitos viraram esquecidos, alguns já foram resolvidos sem apagar.

Marcar idade aproximada (`git blame` se útil) e classificar:
- 🟢 ainda relevante, ataque agora
- 🟡 ainda relevante, baixa prioridade
- 🔴 stale (já resolvido / contexto perdido) — apagar

### 9. Comentários stale

Comentário descreve estado antigo que não bate com o código atual.

```js
// every 10s
// (mas o def real é 15s agora)
const cadence = def.cadence;
```

Como pegar (heurística — não é exato):
- Comentários com número — comparar com constantes próximas e flagar
  divergência.
- Comentários referenciando flags/funções que não existem mais.

Cuidado: heurística gera falsos positivos. Apresentar pro user
decidir, não corrigir cego.

### 10. Inconsistência de naming

Mesmo conceito com nomes diferentes em lugares diferentes. Confunde
LLM e dev humano.

Cuidado: alguns "duplicatas" são intencionais (convenção do projeto).
Não forçar consolidação dessas.

### 11. Imports não usados

Import/use declaration referenciando símbolo que nunca aparece no
arquivo. Suja diff, infla bundle (em stacks que fazem bundle).

Cuidado: side-effect imports (sem nome, só pra executar o módulo) e
imports de tipos usados só em anotações de tipo são intencionais —
não remover.

### 12. Funções > 100 linhas

Sinal de coesão fraca. A fração real do problema às vezes está em
uma única função monstra dentro de um arquivo razoável.

Cuidado: render/update complexos podem ser legitimamente grandes se
não houver subdivisão clara. Não forçar split — flagar e analisar.

### 13. Strings de UI hardcoded escapando do i18n

Texto visível pro usuário direto no código, sem helper de tradução.

Como pegar:
- Procurar literais com acentos da língua principal em código de UI.
- Botões com label literal em vez de chave i18n.

Cuidado: strings de DEBUG, IDs de elemento, e logs internos NÃO
entram no i18n. Filtrar por contexto.

### 14. Asset references quebradas

Path de arquivo referenciado no código que não existe no filesystem
(renomeado, deletado, movido).

Cuidado: alguns paths são montados em runtime. Esses requerem listar
os IDs possíveis e checar — vale flagar como "verificação manual" se
a construção for dinâmica demais.

### 15. i18n keys mortas

Chave existe no arquivo de strings mas nenhum lookup no código.
Inverso de #6.

Cuidado:
- Algumas chaves são montadas dinamicamente. Procurar pelo padrão e
  considerar essas como vivas.
- Chaves usadas via iteração — não marcar como mortas.

### 16. Comentários verbosos sem valor

Comentário que repete o que o código já diz. Ruído puro — infla
arquivo, gasta tokens de leitura sem adicionar informação.

Critério: se apagar o comentário, alguém lendo o código ainda
entende o que faz? Se sim, comentário é ruído.

Cuidado:
- Comentário que documenta gotcha histórico É valioso — preservar.
- Doc-comment estruturado (JSDoc / Javadoc / docstrings / KDoc) em API
  pública com regra/comportamento não-óbvio é OK.

### 17. Docs stale ou duplicadas

Documentação descrevendo fases já fechadas em detalhe extremo,
session recaps antigos, planejamentos que viraram realidade.

Como pegar:
- Listar `.claude/docs/*.md` com data ou referência a fase explícita.
- Cruzar com `CLAUDE.md` — fase concluída cuja doc detalhada ainda
  existe? candidato a condensar.

Cuidado: NUNCA apagar sem o user explicitamente autorizar. Sugestão
default: mover pra `.claude/docs/archive/` em vez de deletar.

### 18. Logs verbosos em hot paths

`console.log` em código que roda muitas vezes por segundo (update
loop, render, hover, mousemove). Polui logs e faz o agente gastar
tokens lendo log irrelevante.

Cuidado: `console.warn`/`console.error` que disparam só em condição
excepcional NÃO são problema — manter.

### 19. Onboarding duplicado entre CLAUDE.md e .claude/docs/

Setup, estrutura, comandos comuns aparecem em 2-3 lugares. Qualquer
leitura inicial de sessão paga 2-3× pela mesma info.

Estratégia de consolidação:
- `CLAUDE.md` é a fonte canônica pra rules + gotchas.
- `.claude/docs/*.md` deve ser tópico-específico — sem reintrodução de
  setup geral.
- Quando duplicar, deixar `CLAUDE.md` manter + remover de `.claude/docs/` +
  cross-link se relevante.

## Como o output é apresentado

A skill NÃO refatora cega. Saída esperada (uma seção por categoria
com achados):

```text
Polish Pass — N achados em M categorias:

🔴 ALTO IMPACTO (atacar primeiro)
[1] Funções duplicadas
   - _formatDuration em 4 módulos
     → consolidar em <SRC_ROOT>/utils/format.<ext>
     Risco: baixo (helper puro, easy migration)

🟡 MÉDIO
[2] Arquivos > 800 linhas
   - <arquivo X> (1840 linhas)
     Risco: médio

🟢 BAIXO
[3] Imports não usados
   - 7 arquivos com 1-2 imports órfãos cada
     Risco: zero
```

Cada item tem:
- Localização exata (arquivo + linhas onde aplicável)
- Quantos lugares afetados
- Sugestão concreta (não vago)
- Risco da refatoração

Depois disso, **espera o usuário escolher** quais atacar. Só então
implementa o fix do que ele autorizou.

## Princípios de execução

- **Uma consolidação por vez.** Nunca empacotar 5 refactors num
  commit só.
- **Testar runtime após cada fix.** Pra mudanças que tocam UI / persistência /
  fluxo crítico, rodar o projeto e validar comportamento. Checagem
  estática (linter/typecheck/`node --check`/equivalente da stack) NÃO
  substitui execução — não pega erros que dependem de runtime.
- **Se o projeto tem i18n e mexeu em string visível: todos os idiomas.**
  Sem exceção.
- **Não consolidar quando há intenção documentada.** Antes de mexer,
  ler comentários e MEMORY.
- **Manter contratos públicos.** Preservar assinatura ou fazer
  migration sweep completo.

## Áreas de atenção específicas do projeto

> Lista viva. Adicionar conforme descobrir hot spots históricos.

- _(vazio — popule conforme rodar a skill e identificar reincidências)_

## Conclusão da skill

Ao terminar a passada, sempre:

1. **Listar o que foi consolidado** (arquivos e linhas afetados)
2. **Listar o que foi flagado mas NÃO atacado** (com motivo)
3. **Recomendar próxima passada** — quando rodar de novo

Mantém a skill viva: se descobrir uma categoria nova de polish que
faz sentido pro projeto, adicionar à lista numerada acima antes de
fechar a tarefa.
