## agent-teams-upgrade — 2026-05-27
Habilitou Agent Teams no project_zero: nova skill `sdd-apply` (aplica tasks.md
despachando dev/escriba/analista por tipo), todos os 6 agentes ganharam seção
"Quando teammate" com padrão SendMessage, gate harness virou 3 teammates
paralelos (sdd-archive/sdd-explore), hook `check-teammate-verdict.sh`
(TeammateIdle), source-of-truth portado pra `agent-profiles/`, doutrina
03-multiagent + 05-harness alinhada a Agent Teams. Paralelismo virou default
no sdd-apply (grafo de deps → ramos independentes rodam juntos).
Harness: seg N/A · testes N/A (sem suite pra scripts/docs) · dados N/A (sem PII) · review ✓
Ripple aplicado: sdd-gate-in-apply (change imediata) re-arquitetou o gate de
sdd-archive → cauda do sdd-apply; sdd-apply.SKILL.md foi reescrito nessa change.
Deferido: `check-teammate-verdict.sh:54` path relativo ao cwd (mesmo bug de
`check-harness-gate.sh`; fix via CLAUDE_PROJECT_DIR — spawn_task criado);
duplicação do padrão "orquestrador" entre operador/architect (candidato a
`_shared/` — backlog do proposal.md).
