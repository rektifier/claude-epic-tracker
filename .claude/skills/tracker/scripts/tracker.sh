#!/bin/bash
# Tracker workflow - main router script
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
TODAY=$(date +%Y-%m-%d)

# ============================================================
# UTILITIES
# ============================================================

slugify() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-'
}

get_next_id() {
    local type=$1
    local count=0
    case $type in
        epic)   count=$(ls -d tracker/epics/EPIC-* 2>/dev/null | wc -l) ;;
        feat)   count=$(find tracker/epics -type d -name "FEAT-*" 2>/dev/null | wc -l) ;;
        us)     count=$(find tracker/epics -name "US-*.md" 2>/dev/null | wc -l) ;;
        bug)    count=$(ls tracker/bugs/BUG-*.md 2>/dev/null | wc -l) ;;
    esac
    printf "%03d" $((count + 1))
}

get_item_type() {
    local id="$1"
    case "$id" in
        EPIC-*) echo "epic" ;;
        FEAT-*) echo "feature" ;;
        US-*)   echo "story" ;;
        BUG-*)  echo "bug" ;;
        *)      echo "unknown" ;;
    esac
}

validate_status_transition() {
    local item_type="$1"
    local current="$2"
    local new="$3"

    # Same status is always allowed
    [ "$current" = "$new" ] && return 0

    case "$item_type" in
        epic|feature)
            # Valid: draft → active → done
            case "$current→$new" in
                "draft→active"|"active→done") return 0 ;;
            esac
            ;;
        story)
            # Valid: todo → in-progress → review → done
            case "$current→$new" in
                "todo→in-progress"|"in-progress→review"|"review→done") return 0 ;;
            esac
            ;;
        bug)
            # Valid: new → confirmed → in-progress → resolved
            case "$current→$new" in
                "new→confirmed"|"confirmed→in-progress"|"in-progress→resolved") return 0 ;;
            esac
            ;;
    esac

    return 1
}


# ============================================================
# STATUS / LIST
# ============================================================

cmd_status() {
    echo "=== Project Backlog ==="
    echo ""

    for epic_dir in tracker/epics/EPIC-*/; do
        [ -d "$epic_dir" ] || continue

        local epic_file="$epic_dir/epic.md"
        local epic_title=$(head -1 "$epic_file" 2>/dev/null | sed 's/# EPIC: //')
        local epic_status=$(grep "^- status:" "$epic_file" 2>/dev/null | cut -d: -f2 | tr -d ' ')

        echo "$epic_title [$epic_status]"

        for feat_dir in "$epic_dir"features/FEAT-*/; do
            [ -d "$feat_dir" ] || continue

            local feat_file="$feat_dir/feature.md"
            local feat_title=$(head -1 "$feat_file" 2>/dev/null | sed 's/# FEATURE: //')
            local feat_status=$(grep "^- status:" "$feat_file" 2>/dev/null | cut -d: -f2 | tr -d ' ')

            echo "├── $feat_title [$feat_status]"

            for story_file in "$feat_dir"user-stories/US-*.md; do
                [ -f "$story_file" ] || continue
                local story_title=$(head -1 "$story_file" | sed 's/# USER STORY: //')
                local story_status=$(grep "^- status:" "$story_file" | cut -d: -f2 | tr -d ' ')
                echo "│   └── $story_title [$story_status]"
            done
        done
        echo ""
    done

    if ls tracker/bugs/BUG-*.md >/dev/null 2>&1; then
        echo "=== Bugs ==="
        for bug_file in tracker/bugs/BUG-*.md; do
            local bug_title=$(head -1 "$bug_file" | sed 's/# BUG: //')
            local bug_status=$(grep "^- status:" "$bug_file" | cut -d: -f2 | tr -d ' ')
            local severity=$(grep "^- severity:" "$bug_file" | cut -d: -f2 | tr -d ' ')
            echo "$bug_title [$bug_status] ($severity)"
        done
    fi
}

cmd_list() {
    local filter="${1:-}"

    if [ -z "$filter" ]; then
        cmd_status
        return
    fi

    echo "=== Items with status: $filter ==="

    # Search epics
    for epic_dir in tracker/epics/EPIC-*/; do
        [ -d "$epic_dir" ] || continue
        local epic_file="$epic_dir/epic.md"
        local epic_status=$(grep "^- status:" "$epic_file" 2>/dev/null | cut -d: -f2 | tr -d ' ')
        if [ "$epic_status" = "$filter" ]; then
            local epic_title=$(head -1 "$epic_file" | sed 's/# EPIC: //')
            echo "$epic_title [$epic_status]"
        fi

        # Search features
        for feat_dir in "$epic_dir"features/FEAT-*/; do
            [ -d "$feat_dir" ] || continue
            local feat_file="$feat_dir/feature.md"
            local feat_status=$(grep "^- status:" "$feat_file" 2>/dev/null | cut -d: -f2 | tr -d ' ')
            if [ "$feat_status" = "$filter" ]; then
                local feat_title=$(head -1 "$feat_file" | sed 's/# FEATURE: //')
                echo "$feat_title [$feat_status]"
            fi

            # Search user stories
            for story_file in "$feat_dir"user-stories/US-*.md; do
                [ -f "$story_file" ] || continue
                local story_status=$(grep "^- status:" "$story_file" | cut -d: -f2 | tr -d ' ')
                if [ "$story_status" = "$filter" ]; then
                    local story_title=$(head -1 "$story_file" | sed 's/# USER STORY: //')
                    echo "$story_title [$story_status]"
                fi
            done
        done
    done

    # Search bugs
    if ls tracker/bugs/BUG-*.md >/dev/null 2>&1; then
        for bug_file in tracker/bugs/BUG-*.md; do
            local bug_status=$(grep "^- status:" "$bug_file" | cut -d: -f2 | tr -d ' ')
            if [ "$bug_status" = "$filter" ]; then
                local bug_title=$(head -1 "$bug_file" | sed 's/# BUG: //')
                local severity=$(grep "^- severity:" "$bug_file" | cut -d: -f2 | tr -d ' ')
                echo "$bug_title [$bug_status] ($severity)"
            fi
        done
    fi
}

# ============================================================
# NEW
# ============================================================

cmd_new() {
    local type="$1"
    shift

    case "$type" in
        epic)    new_epic "$@" ;;
        feature) new_feature "$@" ;;
        story)   new_story "$@" ;;
        bug)     new_bug "$@" ;;
        *)
            echo "Usage: /tracker new {epic|feature|story|bug} [parent-id] \"Title\""
            exit 1
            ;;
    esac
}

new_epic() {
    local title="$*"
    [ -z "$title" ] && { echo "Error: Title required"; exit 1; }

    local id="EPIC-$(get_next_id epic)"
    local slug=$(slugify "$title")
    local dir="tracker/epics/${id}-${slug}"

    mkdir -p "$dir/features"
    sed -e "s/{EPIC-ID}/$id/g" \
        -e "s/{Title}/$title/g" \
        -e "s/{YYYY-MM-DD}/$TODAY/g" \
        -e "s/{name}/unassigned/g" \
        "$SKILL_DIR/templates/epic-template.md" > "$dir/epic.md"

    echo "✓ Created: $dir/epic.md"
    echo "  ID: $id"
}

new_feature() {
    local epic_id="$1"
    shift
    local title="$*"

    [ -z "$epic_id" ] && { echo "Error: Epic ID required"; exit 1; }
    [ -z "$title" ] && { echo "Error: Title required"; exit 1; }

    local epic_dir=$(ls -d tracker/epics/${epic_id}-* 2>/dev/null | head -1)
    [ -z "$epic_dir" ] && { echo "Error: Epic $epic_id not found"; exit 1; }

    local id="FEAT-$(get_next_id feat)"
    local slug=$(slugify "$title")
    local dir="$epic_dir/features/${id}-${slug}"

    mkdir -p "$dir/user-stories"
    sed -e "s/{FEAT-ID}/$id/g" \
        -e "s/{EPIC-ID}/$epic_id/g" \
        -e "s/{Title}/$title/g" \
        -e "s/{YYYY-MM-DD}/$TODAY/g" \
        -e "s/{name}/unassigned/g" \
        "$SKILL_DIR/templates/feature-template.md" > "$dir/feature.md"

    # Update parent
    sed -i "/^## Features/a - [ ] $id $title" "$epic_dir/epic.md"

    echo "✓ Created: $dir/feature.md"
    echo "  ID: $id"
    echo "  Parent: $epic_id"
}

new_story() {
    local feat_id="$1"
    shift
    local title="$*"

    [ -z "$feat_id" ] && { echo "Error: Feature ID required"; exit 1; }
    [ -z "$title" ] && { echo "Error: Title required"; exit 1; }

    local feat_dir=$(find tracker/epics -type d -name "${feat_id}-*" 2>/dev/null | head -1)
    [ -z "$feat_dir" ] && { echo "Error: Feature $feat_id not found"; exit 1; }

    local id="US-$(get_next_id us)"
    local slug=$(slugify "$title")
    local file="$feat_dir/user-stories/${id}-${slug}.md"

    sed -e "s/{US-ID}/$id/g" \
        -e "s/{FEAT-ID}/$feat_id/g" \
        -e "s/{Title}/$title/g" \
        -e "s/{name}/unassigned/g" \
        "$SKILL_DIR/templates/user-story-template.md" > "$file"

    # Update parent
    sed -i "/^## User Stories/a - [ ] $id $title" "$feat_dir/feature.md"

    echo "✓ Created: $file"
    echo "  ID: $id"
    echo "  Parent: $feat_id"
}

new_bug() {
    local title="$*"
    [ -z "$title" ] && { echo "Error: Title required"; exit 1; }

    local id="BUG-$(get_next_id bug)"
    local slug=$(slugify "$title")

    mkdir -p tracker/bugs
    local file="tracker/bugs/${id}-${slug}.md"

    sed -e "s/{BUG-ID}/$id/g" \
        -e "s/{Title}/$title/g" \
        -e "s/{YYYY-MM-DD}/$TODAY/g" \
        -e "s/{name}/unassigned/g" \
        "$SKILL_DIR/templates/bug-template.md" > "$file"

    echo "✓ Created: $file"
    echo "  ID: $id"
}

# ============================================================
# UPDATE
# ============================================================

cmd_update() {
    local id="$1"
    local field="$2"
    local value="$3"

    [ -z "$id" ] && { echo "Usage: /tracker update ID field value"; exit 1; }
    [ -z "$field" ] && { echo "Usage: /tracker update ID field value"; exit 1; }
    [ -z "$value" ] && { echo "Usage: /tracker update ID field value"; exit 1; }

    # Find the file
    local file=""
    case "$id" in
        EPIC-*) file=$(find tracker/epics -name "epic.md" -path "*${id}*" | head -1) ;;
        FEAT-*) file=$(find tracker/epics -name "feature.md" -path "*${id}*" | head -1) ;;
        US-*)   file=$(find tracker/epics -name "${id}*.md" | head -1) ;;
        BUG-*)  file=$(ls tracker/bugs/${id}*.md 2>/dev/null | head -1) ;;
    esac

    [ -z "$file" ] && { echo "Error: $id not found"; exit 1; }

    # Validate status transitions
    if [ "$field" = "status" ]; then
        local item_type=$(get_item_type "$id")
        local current_status=$(grep "^- status:" "$file" | cut -d: -f2 | tr -d ' ')

        if ! validate_status_transition "$item_type" "$current_status" "$value"; then
            echo "Error: Invalid status transition"
            echo "  Cannot change $item_type from '$current_status' to '$value'"
            case "$item_type" in
                epic|feature)
                    echo "  Valid transitions: draft → active → done" ;;
                story)
                    echo "  Valid transitions: todo → in-progress → review → done" ;;
                bug)
                    echo "  Valid transitions: new → confirmed → in-progress → resolved" ;;
            esac
            exit 1
        fi
    fi

    sed -i "s/^- ${field}:.*$/- ${field}: ${value}/" "$file"
    echo "✓ Updated: $file"
    echo "  $field: $value"
}

# ============================================================
# MAIN ROUTER
# ============================================================

show_help() {
    cat << 'EOF'
Tracker Workflow Commands

Usage: /tracker <action> [args]

Actions:
  status                        Show backlog tree
  list [filter]                 List items (filter by status)

  new epic "Title"              Create epic
  new feature EPIC-XXX "Title"  Create feature under epic
  new story FEAT-XXX "Title"    Create user story under feature
  new bug "Title"               Create bug report

  update ID field value         Update item field
                                e.g., update FEAT-001 status active

Examples:
  /tracker new epic "User Management"
  /tracker new feature EPIC-001 "Login System"
  /tracker new story FEAT-001 "Basic login form"
  /tracker update US-001 status in-progress
  /tracker status
EOF
}

# Main
action="${1:-}"
shift 2>/dev/null || true

case "$action" in
    status) cmd_status ;;
    list)   cmd_list "$@" ;;
    new)    cmd_new "$@" ;;
    update) cmd_update "$@" ;;
    help|--help|-h|"")
            show_help ;;
    *)
            echo "Unknown action: $action"
            echo "Run '/tracker help' for usage"
            exit 1
            ;;
esac
