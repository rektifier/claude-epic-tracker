# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a tracker workflow for Claude Code that manages project backlogs using markdown files. Work items (epics, features, user stories, bugs) are stored as markdown files in a hierarchical directory structure, making them version-control friendly.

## Commands

All project management is done through the `/tracker` skill:

```bash
/tracker status                         # Show hierarchical backlog tree
/tracker list [filter]                  # List items (active, todo, in-progress, done)
/tracker new epic "Title"               # Create epic
/tracker new feature EPIC-XXX "Title"   # Create feature under epic
/tracker new story FEAT-XXX "Title"     # Create user story under feature
/tracker new bug "Title"                # Create bug report
/tracker update ID field value          # Update any field (status, owner, assignee, severity)
```

## Architecture

```
.claude/
└── skills/tracker/
    ├── SKILL.md                       # Skill definition + execution logic
    ├── scripts/tracker.sh             # Main bash implementation
    ├── templates/                     # Markdown templates for each item type
    └── references/commands.md         # Command reference

tracker/                               # Project backlog workspace
├── epics/EPIC-XXX-{slug}/
│   ├── epic.md
│   └── features/FEAT-XXX-{slug}/
│       ├── feature.md
│       └── user-stories/US-XXX-{slug}.md
└── bugs/BUG-XXX-{slug}.md
```

## Work Item Hierarchy

```
EPIC (system/initiative)
  └── FEATURE (user-facing capability)
        └── USER STORY (implementable work)

BUG (separate track)
```

## Status Workflows

| Type | Flow |
|------|------|
| Epic/Feature | draft → active → done |
| User Story | todo → in-progress → review → done |
| Bug | new → confirmed → in-progress → resolved |

## Conventions

- **IDs**: Zero-padded 3 digits (EPIC-001, FEAT-001, US-001, BUG-001)
- **User story format**: "As a {role} / I want to {action} / So that {benefit}"
- **Feature sections**: WHAT (requirements) and HOW (design/solution)
- **Linking**: Children reference parent IDs; parents list children as checkboxes
