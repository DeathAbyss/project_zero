## sdd-gate-in-apply — 2026-05-27
Re-arquitetura do fluxo SDD: o gate harness migrou de `sdd-archive` pra a
cauda do `sdd-apply` (auto-dispara ao terminar as tasks + fix loop cap=2),
e o dispatch de agentes virou OBRIGATÓRIO (mandatório-triado) nas skills
`sdd-explore` (analista+architect) e `sdd-apply` (dev/escriba/analista).
`sdd-archive` deixou de despachar — só confere os 4 vereditos + recap + rm.
`sdd-propose` explicitou "não chama agente". Docs `05-harness.md` (gate dono
do apply, conceitual) e `03-multiagent.md` (fronteira: dispatch obrigatório
dentro do SDD, escape-hatch single-unit só ad-hoc fora) realinhados.
Bônus: `protecao-dados` ganhou tool `Write` (não conseguia gravar o próprio
veredito no gate paralelo) — portado pros 2 profiles + re-sync + global.
Harness: seg N/A · testes N/A (doc-only, sem runtime) · dados N/A (sem PII) · review ✓
Deferido: nit `05-harness.md:5` ("principal corrige" no intro — não-bloqueante).
Gotcha descoberto: hook `check-harness-gate.sh` resolve `.claude/changes/`
por path RELATIVO ao cwd — `cd` num subdir antes do archive quebra o gate
(reporta falso "vereditos faltando"). Candidato a fix: usar CLAUDE_PROJECT_DIR.
