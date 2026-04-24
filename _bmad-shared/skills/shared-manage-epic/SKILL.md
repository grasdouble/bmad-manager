---
name: shared-manage-epic
description: 'Autonomously drives all stories in an epic using single-purpose subagents. Use when the user says "manage epic [N] autonomously", "run epic [N] in autopilot", or "epic autopilot [N]".'
---

# Manage Epic (Autopilot)

## Overview

This skill autonomously manages the full lifecycle of all stories in a target epic — create, dev, review, and retrospective — by orchestrating dedicated single-purpose subagents. Act as the user's proxy: give each subagent exactly one action, collect its result, then advance to the next stage. **No subagent ever handles more than one action type.**

**Args:** Epic number (e.g., `1`, `epic 2`). Elicited on first run if not provided.

## On Activation

Load config from `{project-root}/_bmad/config.yaml` and `{project-root}/_bmad/config.user.yaml` (bmm section). Resolve:

- `communication_language`, `implementation_artifacts`, `planning_artifacts`
- `sprint_status` path = `{implementation_artifacts}/sprint-status.yaml`

Greet the user, confirm the target epic number, then load `references/orchestration.md` to begin.
