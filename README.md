# Claude Task Tracker

Markdown-based project backlog management for Claude Code.

[![License: CC0-1.0](https://img.shields.io/badge/License-CC0_1.0-lightgrey.svg)](http://creativecommons.org/publicdomain/zero/1.0/)
[![Claude Code](https://img.shields.io/badge/Claude-Code-blueviolet)](https://claude.ai/code)
[![Bash](https://img.shields.io/badge/Made_with-Bash-1f425f.svg)](https://www.gnu.org/software/bash/)

## Overview

A Claude Code skill for tracking epics, features, user stories, and bugs using plain markdown files. Work items are stored in a hierarchical directory structure that's version-control friendly—no external tools or databases needed.

## Quick Start

1. Copy the `.claude/skills/tracker` directory to your project
2. Start tracking:

```bash
/tracker new epic "User Authentication"
/tracker status
```

## Work Item Hierarchy

```
EPIC (system/initiative)
  └── FEATURE (user-facing capability)
        └── USER STORY (implementable work)

BUG (separate track)
```

| Type | Purpose | Example |
|------|---------|---------|
| Epic | Large initiative or system | "User Authentication System" |
| Feature | User-facing capability | "Login/Logout Flow" |
| User Story | Single implementable unit | "Basic login form" |
| Bug | Defect report | "Login fails on Safari" |

## Commands

### View

| Command | Description |
|---------|-------------|
| `/tracker status` | Show hierarchical backlog tree |
| `/tracker list` | List all items (same as status) |
| `/tracker list [filter]` | List items by status (e.g., `active`, `todo`, `done`) |

### Create

| Command | Description |
|---------|-------------|
| `/tracker new epic "Title"` | Create a new epic |
| `/tracker new feature EPIC-XXX "Title"` | Create feature under an epic |
| `/tracker new story FEAT-XXX "Title"` | Create user story under a feature |
| `/tracker new bug "Title"` | Create a bug report |

### Update

| Command | Description |
|---------|-------------|
| `/tracker update ID field value` | Update any field on an item |

Common fields: `status`, `assignee`, `owner`, `severity`

## Usage Examples

### Create a backlog

```bash
# Create an epic
/tracker new epic "User Management"
# ✓ Created: epics/EPIC-001-user-management/epic.md
#   ID: EPIC-001

# Add a feature to the epic
/tracker new feature EPIC-001 "User Registration"
# ✓ Created: epics/EPIC-001-user-management/features/FEAT-001-user-registration/feature.md
#   ID: FEAT-001
#   Parent: EPIC-001

# Add user stories to the feature
/tracker new story FEAT-001 "Registration form"
# ✓ Created: .../user-stories/US-001-registration-form.md
#   ID: US-001
#   Parent: FEAT-001
```

### View status

```bash
/tracker status
```

```
=== Project Backlog ===

EPIC-001 User Management [draft]
├── FEAT-001 User Registration [draft]
│   └── US-001 Registration form [todo]

=== Bugs ===
BUG-001 Login fails on Safari [new] (high)
```

### Update items

```bash
# Start working on a story
/tracker update US-001 status in-progress

# Mark feature as active
/tracker update FEAT-001 status active

# Assign a bug
/tracker update BUG-001 assignee alice
```

## Status Workflows

| Type | Workflow |
|------|----------|
| Epic | `draft` → `active` → `done` |
| Feature | `draft` → `active` → `done` |
| User Story | `todo` → `in-progress` → `review` → `done` |
| Bug | `new` → `confirmed` → `in-progress` → `resolved` |

## Directory Structure

### Skill files (what you install)

```
.claude/skills/tracker/
├── SKILL.md              # Skill definition
├── scripts/
│   └── tracker.sh        # Main implementation
├── templates/            # Markdown templates
│   ├── epic-template.md
│   ├── feature-template.md
│   ├── user-story-template.md
│   └── bug-template.md
└── references/
    └── commands.md       # Command reference
```

### Backlog files (created at runtime)

```
epics/
├── EPIC-001-user-management/
│   ├── epic.md
│   └── features/
│       └── FEAT-001-user-registration/
│           ├── feature.md
│           └── user-stories/
│               └── US-001-registration-form.md
bugs/
└── BUG-001-login-fails-on-safari.md
```

## Conventions

### ID Format

Zero-padded 3 digits:
- `EPIC-001`, `EPIC-002`, ...
- `FEAT-001`, `FEAT-002`, ...
- `US-001`, `US-002`, ...
- `BUG-001`, `BUG-002`, ...

### User Story Format

```
As a {role}
I want to {action}
So that {benefit}
```

### Linking

- Children reference parent IDs in their metadata
- Parents list children as checkboxes: `- [ ] FEAT-001 Feature Title`

## Requirements

- [Claude Code](https://claude.ai/code)
- Bash
- Standard Unix utilities (sed, grep, find)

## License

[CC0 1.0 Universal](LICENSE) - Public Domain
