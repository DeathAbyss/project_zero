# CLAUDE.md — {{PROJECT_NAME}}

Notas para sessões futuras. Leia antes de começar a mexer em qualquer
coisa.

## O que é o projeto

{{PROJECT_DESCRIPTION}}

- **Stack**: {{STACK}}
- **Plataforma alvo**: {{PLATFORM}}
- **Pasta raiz do código**: `{{SRC_ROOT}}`

## Como rodar

```bash
{{RUN_COMMAND}}
```

Testes (se houver):

```bash
{{TEST_COMMAND}}
```

## Mapa do projeto pra IA — LEIA PRIMEIRO

Antes de greppar/explorar, leia o doc relevante — costuma economizar
5-10 reads.

- [`.claude/docs/project_map/`](.claude/docs/project_map/) — docs
  compactos (50-150 linhas cada) mapeando cada área do projeto com
  `file:line`. Comece pelo
  [README.md](.claude/docs/project_map/README.md) (índice).
- [`.claude/docs/GLOSSARY.md`](.claude/docs/GLOSSARY.md) — vocabulário
  específico do projeto. Antes de pedir definição de termo do domínio,
  consulte aqui.
- [`.claude/docs/decisions/`](.claude/docs/decisions/) — ADRs leves
  explicando por que escolhas foram feitas. Antes de "melhorar" algo
  que parece arbitrário, confira se tem decisão registrada.

**Regra de manutenção**: ao mudar mecânica documentada, **atualize o
doc no MESMO turno**. Drift = bug invisível, pior que não ter doc. Doc
tem `file:line` clicáveis — confirme no código real antes de propagar
premissa.

## Doutrina pra IA (carrega sob demanda)

Regras fixas que se aplicam a todo projeto. CLAUDE.md aponta pra cá
em vez de duplicar — economiza token por turno.

- [`.claude/docs/CONVENTIONS.md`](.claude/docs/CONVENTIONS.md) — single
  source of truth: docs compactos, estilo de código, output do agente,
  briefing entre agentes.
- [`.claude/docs/01-git.md`](.claude/docs/01-git.md) — regras de git
  (nunca commitar sem pedido, PR obrigatório, branch protegida).
- [`.claude/docs/02-token-efficiency.md`](.claude/docs/02-token-efficiency.md)
  — princípios + anti-padrões + hierarquia de carregamento.
- [`.claude/docs/03-multiagent.md`](.claude/docs/03-multiagent.md) —
  quando despachar sub-agente, Camadas 1/2, briefing mastigado.
- [`.claude/docs/04-task-closure.md`](.claude/docs/04-task-closure.md)
  — checklist antes de declarar concluído.
- [`.claude/docs/SECURITY_NOTES.md`](.claude/docs/SECURITY_NOTES.md) —
  arquivos sensíveis (`.env`, chaves, credenciais) que NÃO tocar.

## Regras duras do projeto (não quebrar)

> Restrições não-negociáveis ESPECÍFICAS deste projeto. As regras
> gerais (git, sensíveis) vivem em `.claude/docs/` linkado acima.
> Acrescente aqui o que é do domínio.

1. **Não criar arquivo `.md` de plano/análise/recap sem ser pedido.**
   Plano vive em `TodoWrite` ou na conversa. Arquivo intermediário
   vira lixo na próxima sessão e custa Read futuro.
2. {{PROJECT_HARD_RULE — preencher ou remover}}. Ex.: "Sem dependências
   externas no runtime"; "Toda string visível passa por i18n"; "Nada
   de SQL inline — só via repository".

## Arquitetura

> Diagrama ASCII ou descrição curta. Ponto de entrada, camadas
> principais, fluxo de dados. Mantenha curto — detalhes ficam em
> `.claude/docs/project_map/`.

{{ARCHITECTURE_SUMMARY — preencher}}

## Gotchas conhecidos

> Coisas que parecem bug mas são intencionais. Coisas que já causaram
> bug e a gente nunca mais quer repetir. Edge cases que não estão
> documentados no código.

{{GOTCHAS — edit conforme descobrir; remova esta linha quando preencher
o primeiro}}

## Como fazer coisas comuns

> Receitas para tarefas recorrentes. Cada receita: onde criar, onde
> registrar (se houver registry), onde adicionar testes, o que validar
> antes de fechar.

{{COMMON_RECIPES — preencher quando padrão emergir; sem preencher,
remova esta seção}}

## Como o usuário trabalha

- Comunica em {{USER_LOCALE}}. UI default em {{LANGUAGE}}.
- Dá liberdade depois do alinhamento inicial — quando ele diz "pode
  seguir" ou "faz o que recomendou", ele espera execução ampla com
  bom senso.
- Antes de projetos/fases grandes, perguntar sobre escopo, tech choice
  e plataforma alvo.

## Skills ativas

Cada skill em [`.claude/skills/`](.claude/skills/) tem seu próprio
`SKILL.md` descrevendo triggers e fluxo. Pra desativar uma skill,
apague seu `SKILL.md`.

## Coordenação de sessões paralelas

Antes de tocar arquivos compartilhados, verifique
[`.claude/SESSION_LOCK.md`](.claude/SESSION_LOCK.md). Reclame uma
sessão paralela com escopo + timestamp antes de começar.
