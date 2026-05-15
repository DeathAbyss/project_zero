# Glossário

Vocabulário específico deste projeto. Cresce conforme termos aparecem
em conversa/código. **Não invente** termos aqui — só registre o que
já existe no projeto.

Reduz token: IA não precisa pedir definição todo turno e não inventa
sinônimos. Quando ler "X" em prompt ou código, consulta aqui.

## Termos

| Termo | Definição | Onde aparece (canonical) |
|---|---|---|
| _(vazio — popule conforme conhecer)_ | _(1-2 frases)_ | _(arquivo:linha)_ |

## Princípios

- **1-2 frases por termo.** Mais que isso vai pra doc específico
  (ex.: `.claude/docs/project_map/X.md`).
- **`file:line` pra exemplo canônico** de uso. Sem isso o termo vira
  vago.
- **Sinônimos viram linha própria** com cross-link pro canonical.
  Ex.: "minion" → ver "enemy".
- **Termos óbvios pra qualquer dev** (HTTP, JSON, REST, etc.) NÃO
  entram. Só termos com significado específico DESTE projeto.
- **Sigla → expandida.** "TD" sozinho não diz nada; "TD (Tower
  Defense)" sim.

## Quando atualizar

- Usuário usou termo que IA não conhecia e teve que perguntar →
  registrar pra próxima vez.
- Termo de domínio aparece em 3+ arquivos → vale glossário.
- Renome de conceito → atualizar TODAS as refs no glossário (não só
  a entrada principal).

## Quando NÃO criar entrada

- Termo usado uma vez e que dificilmente vai voltar.
- Conceito que só existe num arquivo (o comentário no fonte basta).
- Algo já documentado em `.claude/docs/project_map/`.
