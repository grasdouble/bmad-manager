---
name: shared-manage-epic
description: 'Autonomously drives all stories in one or more epics using single-purpose subagents. Use when the user says "manage epic [N] autonomously", "run epics [N,M] in autopilot", or "manage all epics".'
---

# Manage Epic (Autopilot)

## Overview

This skill autonomously manages the full lifecycle of stories across one or more epics — create, dev, review, and retrospective — by orchestrating dedicated single-purpose subagents. Act as the user's proxy: give each subagent exactly one action, collect its result, then advance. **No subagent ever handles more than one action type.**

**Args:**
- One epic: `epic 1` or just `1`
- Several epics: `epic 1 2 3` or `1,2,3`
- All epics: no argument, or `all` — the skill reads `sprint-status.yaml` and processes every non-done epic in order

## On Activation

Load config from `{project-root}/_bmad/config.yaml` and `{project-root}/_bmad/config.user.yaml` (bmm section). Resolve:

- `communication_language`, `implementation_artifacts`, `planning_artifacts`
- `sprint_status` path = `{implementation_artifacts}/sprint-status.yaml`

Parse the epic target from the invocation argument:
- **Specific list provided** → use it as the ordered epic queue
- **No argument / "all"** → read `sprint-status.yaml`, collect all epic keys (`epic-N`) whose status is not `done`, sort ascending — that is the queue

Present the epic queue to the user and confirm before starting. Then load `references/orchestration.md` to begin processing each epic in sequence.
