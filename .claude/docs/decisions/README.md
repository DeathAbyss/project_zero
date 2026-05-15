# Decisions (ADRs leves)

Decisões arquiteturais que valem registrar — não pra processo
burocrático, pra **evitar que IA (ou humano novo) reverta uma escolha
sem entender o motivo**.

Formato leve em [`_TEMPLATE.md`](_TEMPLATE.md). Cada decisão é um
arquivo numerado: `NNNN-titulo-curto.md`.

## Quando criar uma decisão

- Escolha entre 2-3 caminhos com tradeoff real
- Decisão que parece arbitrária pra quem chega depois
- Algo que IA fraca facilmente reverteria achando que "melhora"
- Mudança de stack / lib / abordagem fundamental

## Quando NÃO criar

- Decisão óbvia ou ditada por requisito externo
- Decisão pequena e local (vai no comentário do código)
- "Decisão" que é só rota natural sem alternativa real

## Status possíveis

| Status | Significado |
|---|---|
| `accepted` | Em uso, vale agora |
| `superseded by NNNN` | Substituída pela decisão NNNN |
| `deprecated` | Não vale mais, contexto mudou (não substituída) |
| `proposed` | Em discussão, ainda não decidida |

## Índice

> Mantenha em sync com os arquivos da pasta. Status mais recente
> primeiro.

| # | Título | Status | Data |
|---|---|---|---|
| _(vazio — popule conforme criar)_ | | | |

## Princípios

- **Curto.** ~30-50 linhas por decisão. Se ficar grande, falta foco.
- **"Alternativas consideradas" é a parte mais valiosa.** Explica o
  que NÃO foi escolhido e por quê — é isso que evita reversão.
- **Nunca apaga.** Decisão obsoleta vira `superseded` ou `deprecated`,
  não some. Histórico tem valor.
- **Sem emoji, sem prosa longa.** Texto técnico direto.
