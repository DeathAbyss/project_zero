# Security Notes

Arquivos sensíveis a NÃO ler / NÃO editar / NÃO commitar. Lista viva —
adicione conforme descobrir.

Referenciado pelo `CLAUDE.md` na seção "Regras duras". IA deve
consultar antes de qualquer operação em arquivo que pareça sensível.

## Arquivos sensíveis (defaults — adapte ao projeto)

| Path / Pattern | Tipo | Política |
|---|---|---|
| `.env`, `.env.*` (exceto `.env.example`) | Variáveis de ambiente com secrets | **NÃO ler** sem permissão explícita. **NÃO commitar** (deve estar em `.gitignore`). |
| `*.key`, `*.pem`, `*.p12`, `*.pfx` | Chaves privadas | NÃO ler, NÃO commitar |
| `credentials/`, `secrets/`, `.secrets/` | Pastas de secrets | NÃO ler, NÃO commitar |
| `*.sqlite`, `*.db`, `*.sqlite3` | Banco local de dev (pode conter dado pessoal) | NÃO ler conteúdo binário. Pode usar comandos do projeto pra interagir. |
| `node_modules/`, `vendor/`, `target/`, `.venv/` | Dependências externas | NÃO editar (pode ler pra entender API) |
| `dist/`, `build/`, `out/` | Output gerado | NÃO editar (gerado por build) |
| `.git/` | Estado do git | NÃO editar diretamente (usar comandos `git`) |

## Padrões a NUNCA escrever em código

- API keys hardcoded
- Tokens (bearer, OAuth, JWT)
- Senhas em plaintext
- URLs / IPs de produção em string literal (devem vir de env var ou config)
- Endpoints privados / internos
- Strings que parecem identificadores pessoais (CPF, e-mail real, telefone)

## Se descobrir secret comprometido em código ou git history

1. **Não tentar "limpar" sozinho** com `git filter-branch` ou similar.
2. **Avisar o usuário IMEDIATAMENTE**, parando a task atual.
3. Listar onde apareceu (arquivo:linha, hash do commit se relevante).
4. Sugerir rotação manual da credencial (o usuário faz, não o agente).

## Quando o usuário precisar de credenciais

- Pedir pro usuário — não procurar/inferir no projeto.
- Usar placeholder ou env var em código (nunca o valor real).
- Se for pra testar, pedir credenciais de **dev/staging**, não prod.
- Nunca salvar credenciais em comentário, doc, ou commit message.

## Específicos do projeto

> Liste aqui arquivos/padrões sensíveis específicos deste projeto que
> não cabem nas categorias acima.

- _(vazio — adicione conforme aprender o projeto)_
