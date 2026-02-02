---
name: tracker
description: Track epics, features, user stories, and bugs in markdown files. Provides context about work item hierarchy and status workflows, and executes tracker commands.
allowed-tools: Bash, Read, Write
---

# Tracker Skill

Manage project backlogs using markdown files. Work items are stored in a hierarchical directory structure.

## Usage

```
/tracker status              Show backlog tree
/tracker list [filter]       List items (filter: active, todo, done, etc.)

/tracker new epic "Title"
/tracker new feature EPIC-XXX "Title"
/tracker new story FEAT-XXX "Title"
/tracker new bug "Title"

/tracker update ID status VALUE
/tracker update ID assignee NAME
```

## Execution

Route based on first argument in $ARGUMENTS:

| First arg | Action |
|-----------|--------|
| `status` | Show backlog tree |
| `list` | List items with optional filter |
| `new` | Create new item (epic/feature/story/bug) |
| `update` | Update item field |
| (none) | Show usage help |

Run via the tracker script:

```bash
bash .claude/skills/tracker/scripts/tracker.sh $ARGUMENTS
```

After execution:
- Report what was created/changed
- Show file path for new items
- For `new` actions, ask if user wants to add details

---

## Knowledge Base

### Hierarchy

```
EPIC (system/initiative)
  └── FEATURE (user-facing capability)
        └── USER STORY (implementable work)
              └── TASK (sub-work, optional)

BUG (separate track)
```

### Directory Structure

```
tracker/
├── epics/EPIC-XXX-{slug}/
│   ├── epic.md
│   └── features/FEAT-XXX-{slug}/
│       ├── feature.md
│       └── user-stories/US-XXX-{slug}.md
└── bugs/BUG-XXX-{slug}.md
```

### ID Format

Zero-padded 3 digits: `EPIC-001`, `FEAT-001`, `US-001`, `BUG-001`

### Status Flow

| Type | Flow |
|------|------|
| Epic/Feature | draft → active → done |
| User Story | todo → in-progress → review → done |
| Bug | new → confirmed → in-progress → resolved |

### User Story Format

```
As a {role}
I want to {action}
So that {benefit}
```

### Feature Sections

- **WHAT?**: Requirements, Acceptance Criteria
- **HOW?**: GUI/UX Design, Technical Solution

### Linking Rules

- Features reference parent Epic ID
- User Stories reference parent Feature ID
- Parents list children as checkboxes: `- [ ] ID title`

See [references/commands.md](references/commands.md) for full command reference.
