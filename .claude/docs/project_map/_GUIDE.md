# Guia — como escrever docs em `project_map/`

Este guia descreve o formato dos docs compactos que vivem nesta pasta.
Otimizados pra **IA ler em poucos tokens**, não pra humano absorver em
prosa.

## Princípio

Doc é GPS, não tutorial. Existe pra responder:
- "Onde está X?"
- "Quem chama Y?"
- "Qual é o valor de Z?"
- "Que arquivo eu leio se preciso mexer em W?"

Se não responde uma dessas, está fora do escopo.

## Formato

### Tamanho

50-150 linhas por doc. Se passar de 200, dividir. Se ficar < 30, talvez
não justifique doc próprio — anexar a outro.

### Estrutura mínima

```markdown
# <nome do doc> — <área do projeto>

> Frase única sobre o que esse doc cobre.

## Arquivos principais

| Arquivo | Função |
|---|---|
| [parser.ext](relative/path/parser.ext) | Faz X |
| [handler.ext](relative/path/handler.ext:42) | Faz Y (entry em :42) |

## Símbolos exportados / API pública

| Símbolo | Onde | Uso |
|---|---|---|
| `computeX()` | [parser.ext:55](relative/path/parser.ext:55) | Chamada pelos consumidores Y e Z |

## Valores numéricos relevantes

| Constante | Valor | Onde |
|---|---|---|
| `MAX_RETRIES` | 5 | [parser.ext:12](relative/path/parser.ext:12) |

## Fluxo principal

1. Quem chama primeiro
2. O que acontece
3. Para onde vai

## Cross-links

- Para detalhe de A, ver [a.md](a.md)
- Para detalhe de B, ver [b.md](b.md)
```

### Regras duras

Regras canônicas de doc compacto vivem em
[`.claude/docs/CONVENTIONS.md`](../CONVENTIONS.md) (seção "Regras pra docs
compactos"). Não duplicar aqui — single source of truth.

Resumo do que se aplica neste contexto:
`file:line` em tudo, tabela > parágrafo, sem exemplos de código,
sem prosa longa, cross-link > duplicar.

## Como nomear o doc

Nome curto, em inglês, lowercase, descritivo:

- ✅ `auth.md`, `routing.md`, `payments.md`, `cache.md`
- ❌ `auth-system-explained.md`, `THE_AUTH_FLOW.md`

Numerados quando há vários do mesmo tipo (módulos plug-and-play,
domínios paralelos): `domain_1.md`, `domain_2.md`.

## Como manter

A skill `sync-project-map` (se ativada) varre os docs depois de cada
edit em arquivo coberto pelo catálogo e relata drift. Veja
[.claude/skills/sync-project-map/SKILL.md](../../.claude/skills/sync-project-map/SKILL.md).

## Quando criar doc novo

- Área inteira nova no projeto sem cobertura
- Arquivo grande (> 500 linhas) tocado em 3+ sessões sem doc
- Mecânica nova que toca 4+ arquivos (vira `mechanics_N.md`)

## Quando NÃO criar doc

- Arquivo de configuração lido 1× e nunca mais
- Helper trivial (`utils/format.ext` 30 linhas — vai numa linha de
  `utils.md`, não doc próprio)
- Coisa que muda toda semana (drift garantido > valor do doc)
