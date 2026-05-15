# project_map — Índice

Docs compactos mapeando o projeto pra IA ler antes de mexer. Cada doc
tem 50-150 linhas e cobre uma área específica.

Veja [_GUIDE.md](_GUIDE.md) pra entender o formato dos docs.

## Docs nesta pasta

> Preencha esta tabela conforme criar docs. Mantenha em ordem
> alfabética. Uma linha = um doc.

| Doc | O que cobre |
|---|---|
| _(vazio — popule conforme criar)_ | _(descrição curta)_ |

## Convenções

- Doc é GPS pra encontrar código, não tutorial.
- Sempre referenciar `file:line`. Sem isso vira prosa inútil.
- Tabela > parágrafo.
- Cross-link em vez de duplicar info.
- 50-150 linhas por doc. Maior = divide.

## Como começar (projeto novo)

Os primeiros docs a criar costumam ser:

1. **Um para cada "camada arquitetural" principal.** Ex.: `core.md`
   (boot, entry, lifecycle), `data.md` (modelos / fontes de verdade),
   `ui.md` (renderização / componentes).
2. **Um por sub-domínio com lógica não-trivial.** Ex.: num jogo —
   `combat.md`, `save.md`. Numa API — `auth.md`, `billing.md`.
3. **Conforme aparecer**: mecânicas novas viram `mechanics_N.md`.

## Catálogo arquivo → doc

> Esta tabela alimenta o hook `.claude/hooks/check-sync-project-map.sh`,
> que dispara reminder pra rodar a skill `sync-project-map` quando você
> edita um arquivo coberto. Mantenha em sync com o hook.

| Path padrão | Doc associado |
|---|---|
| _(adicionar conforme criar docs)_ | _(doc.md)_ |
