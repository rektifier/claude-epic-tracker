# Tracker Commands Reference

## Command Syntax

```
/tracker <action> [args]
```

## Actions

### status
Show hierarchical backlog view with all items and statuses.

```
/tracker status
```

### list
List items, optionally filtered by status.

```
/tracker list              # All items
/tracker list active       # Only active
/tracker list todo         # Only todo
/tracker list in-progress  # Only in-progress
```

### new
Create work items.

```
/tracker new epic "Title"
/tracker new feature EPIC-XXX "Title"
/tracker new story FEAT-XXX "Title"
/tracker new bug "Title"
```

### update
Update item fields.

```
/tracker update ID field value
```

Common updates:
```
/tracker update EPIC-001 status active
/tracker update FEAT-001 owner anna
/tracker update US-001 status in-progress
/tracker update US-001 assignee bob
/tracker update BUG-001 severity high
/tracker update BUG-001 status confirmed
```

## Status Values

| Type | Valid Statuses |
|------|----------------|
| Epic | draft, active, done |
| Feature | draft, active, done |
| User Story | todo, in-progress, review, done |
| Bug | new, confirmed, in-progress, resolved |

## Examples

### Start a new project
```
/tracker new epic "User Management System"
/tracker new feature EPIC-001 "Authentication"
/tracker new story FEAT-001 "Login form"
/tracker new story FEAT-001 "Password reset"
/tracker status
```

### Work on a bug
```
/tracker new bug "Login fails on Safari"
/tracker update BUG-001 severity high
/tracker update BUG-001 assignee dev-name
/tracker update BUG-001 status in-progress
```
