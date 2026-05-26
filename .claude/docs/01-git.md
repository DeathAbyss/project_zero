# Git / PR — regras duras

Versão canônica das regras de git do template. `CLAUDE.md` aponta pra
cá em vez de duplicar.

## 1. Agente nunca mexe em estado versionado remoto sem pedido

Agente NÃO executa: `git commit`, `git push`, `git pull`, `git merge`,
`git rebase`, `git checkout` trocando branch, `git reset --hard`, nem
qualquer comando que mexa em estado remoto ou destrutivo.

Permitido sem pedir: `git status`, `git diff`, `git log`, `git add`
(stage).

O usuário comita/push manual depois de revisar. "Pode seguir" ≠
autorização pra commitar — pedido explícito ("comita", "faz o
commit") autoriza UMA vez, naquele turno.

## 2. `main`/`master` nunca recebe edit direto — PR obrigatório

**Antes de qualquer Edit/Write**, agente confere a branch:

```bash
git branch --show-current
```

- Se `main`/`master`/principal → **PARA e pergunta**: "Tô em `main`.
  Crio branch `feature/<slug>` pra essa task?" Espera confirmação. O
  agente NÃO cria branch sozinho — o usuário roda
  `git checkout -b <branch>`.
- Se branch ≠ principal → trabalha normal.
- Commit (quando autorizado pela regra #1) vai pra branch atual.
- PR contra `main` é decisão humana. Agente pode preparar descrição
  se pedido, NUNCA faz `gh pr merge` nem merge pela UI.
- Merge é sempre humano. Mesmo com "tá pronto, pode mergear",
  confirma duas vezes — default é "abre o PR e te aviso".

Razão: PR é trilha de auditoria. Sem PR = mudança escapa sem revisão.

## 3. Commit message

- 1 linha de assunto + corpo opcional. Direto, sem decoração.
- Sem emoji, sem ASCII art.
- Sem rodapé `Co-Authored-By` exceto se o projeto configurou.
