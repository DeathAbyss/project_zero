# Antes de fechar a task (checklist)

IA fraca diz "pronto" cedo demais. Antes de declarar uma task como
concluída, confira nesta ordem:

- [ ] **Validou runtime?** Se a mudança é executável, rodou pra ver
      que funciona. Check de sintaxe NÃO substitui execução — não
      pega ReferenceError em closure, não pega edge case. Pra UI,
      abriu o preview e testou o caminho golden + edge cases. Se não
      dá pra testar, fala explícito ("não testei runtime porque X")
      em vez de declarar concluído.
- [ ] **Docs em sync?** Mexeu em arquivo coberto pelo `project_map`?
      O hook deve ter disparado reminder. Despache o sub-agente
      `escriba` (se ativo) ou invoque a skill `sync-project-map`.
- [ ] **GLOSSARY / DECISIONS?** Introduziu termo de domínio novo?
      Tomou decisão não-óbvia? Vale registrar agora — depois esquece.
- [ ] **CLAUDE.md merece update?** Descobriu gotcha novo durante a
      task? Edge case surpreendente? Convenção que não estava
      escrita? Adiciona como gotcha/regra dura.
- [ ] **Branch correta?** `git branch --show-current` — está numa
      branch dedicada (não `main`/`master`)? Se está em `main`,
      mudança escapou da regra dura de git; sinaliza pro usuário pra
      decidir (mover pra branch ou aceitar como erro pontual).
      Ver [`01-git.md`](01-git.md).
- [ ] **Stage limpo?** Fez `git add` só do que faz parte desta task —
      não arrastou `.env`, log, build output, arquivo que ficou de
      fora.
- [ ] **Commit pendente?** NÃO commita você (regra de git #1).
      Sinaliza pro usuário que tem mudanças prontas pra revisão —
      lista enxuta dos arquivos. Commit vai pra branch atual, PR
      fica pra revisão humana.
- [ ] **Resumo enxuto?** 1-2 frases do que mudou + 1 frase do
      próximo passo (se houver). Sem repetir o diff. Sem emoji.
- [ ] **Relatório de tokens?** Se a sessão começou com "lê o README e
      faz o setup" (ou variante), rode a skill `cost-report` ANTES do
      resumo. Devolve quanto a sessão consumiu, separando principal
      e subagentes. Pra outras tasks não roda automaticamente — só
      sob demanda do user.

Se algum item ficou em aberto, **diga isso** em vez de declarar
concluído. "Pronto, fica faltando X" é melhor que "pronto" implícito
que vira bug depois.

## Itens condicionais (só se aplicar ao projeto)

Estes só viram checklist se o projeto tem o recurso. Adicione ao
checklist do projeto em `CLAUDE.md` quando for o caso:

- **i18n**: se o projeto tem i18n e a mudança tocou string visível,
  atualizou TODOS os idiomas suportados. Faltas parciais são bug.
- **Version bump**: se o projeto tem version field em algum manifesto
  (`package.json`, `pom.xml`, `Cargo.toml`, `pyproject.toml`,
  `go.mod`, manifest de PWA, etc.) e a mudança é significativa,
  precisa bump.
- **Migration script**: se o projeto tem schema versionado e a mudança
  altera schema, criou a migration.
- **Lint / formatter**: se o projeto tem lint/format obrigatório, rodou
  e está limpo.
