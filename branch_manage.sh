#!/bin/bash

verify_repo() {
    local repo_path="$1"
    if [ ! -d "$repo_path/.git" ]; then
        echo -e "\n...Error: '$repo_path' is not a valid Git repository...\n"
        return 1
    fi
    return 0
}

list_versions() {
    local repo_path="$1"
    verify_repo "$repo_path" || return
    echo -e "\nCommit History for $(basename "$repo_path"):\n"
    git -C "$repo_path" log --oneline --graph --all --decorate
}

view_version() {
    local repo_path="$1"
    verify_repo "$repo_path" || return

    read -p "Enter commit hash to view: " commit_hash

    if ! git -C "$repo_path" branch --contains "$commit_hash" >/dev/null 2>&1; then
        echo -e "\nError: Commit does not exist in the current branch!\n"
        return
    fi

    git -C "$repo_path" show --stat "$commit_hash"
}

restore_commit() {
    local repo_path="$1"
    verify_repo "$repo_path" || return
    read -p "Enter commit hash to restore: " commit_hash
    git -C "$repo_path" reset --hard "$commit_hash" && echo "Repository restored to commit $commit_hash."
}

create_branch_from_version() {
    local repo_path="$1"
    verify_repo "$repo_path" || return
    read -p "Enter commit hash: " commit_hash
    read -p "Enter new branch name: " branch_name
    git -C "$repo_path" checkout -b "$branch_name" "$commit_hash" && echo "New branch '$branch_name' created from commit $commit_hash."
}

add_file() {
    local repo_path="$1"
    verify_repo "$repo_path" || return

    read -p "Enter file path to add: " file_path
    file_name=$(basename "$file_path")
    dest_path="$repo_path/$file_name"

    if [[ -f "$dest_path" ]]; then
        echo "File '$file_name' already exists in the repository. Please provide another file name."
        return
    fi

    if [[ ! -f "$file_path" ]]; then
        echo "File does not exist. Creating '$file_name'..."
        touch "$dest_path"
        nano "$dest_path"
    else
        mv "$file_path" "$dest_path" || { echo "Error moving the file. Check permissions."; return; }
    fi

    git -C "$repo_path" add "$file_name"
    echo "File '$file_name' staged for commit."
}


list_files() {
    local repo_path="$1"
    verify_repo "$repo_path" || return
    echo -e "\nFiles in repository $(basename "$repo_path"):\n"
    git -C "$repo_path" ls-files
}

update_file() {
    local repo_path="$1"
    verify_repo "$repo_path" || return

    read -p "Enter file name to update: " file_name
    local full_path="$repo_path/$file_name"
    [[ ! -f "$full_path" ]] && { echo "Error: File does not exist in the repository."; return; }

    nano "$full_path"

    git -C "$repo_path" add "$file_name"
    echo "File '$file_name' staged for commit."
}

delete_branch() {
    local repo_path="$1"

    verify_repo "$repo_path" || return

    echo "Available branches:"
    git -C "$repo_path" branch

    read -p "Enter branch name to delete: " branch_name

    if ! git -C "$repo_path" show-ref --verify --quiet "refs/heads/$branch_name"; then
        echo "...Error: Branch '$branch_name' does not exist..."
        return
    fi

    current_branch=$(git -C "$repo_path" rev-parse --abbrev-ref HEAD)
    if [[ "$current_branch" == "$branch_name" ]]; then
        echo "...Error: Cannot delete the current branch. Switch to another branch first..."
        return
    fi

    if git -C "$repo_path" branch --no-merged | grep -q " $branch_name$"; then
        echo "...Branch '$branch_name' is not fully merged..."
        read -p "Do you want to force delete it? (y/n): " confirm
        if [[ "$confirm" == "y" ]]; then
            git -C "$repo_path" branch -D "$branch_name" && echo "Branch '$branch_name' force deleted."
        else
            echo "...Branch '$branch_name' NOT deleted..."
        fi
    else
        echo "...Branch '$branch_name' is fully merged..."
        read -p "Do you want to delete it? (y/n): " confirm
        if [[ "$confirm" == "y" ]]; then
            git -C "$repo_path" branch -d "$branch_name" && echo "Branch '$branch_name' deleted."
        else
            echo "Branch '$branch_name' NOT deleted."
        fi
    fi
}

create_branch() {
    local repo_path="$1"
    verify_repo "$repo_path" || return

    if ! git -C "$repo_path" log --oneline &>/dev/null; then
        echo "No commits found. Creating an initial commit..."

        echo "Initial commit" > "$repo_path/README.md"
        git -C "$repo_path" add README.md
        git -C "$repo_path" commit -m "Initial commit"
    fi

    while true; do
        read -p "Enter new branch name: " branch_name

        if git -C "$repo_path" show-ref --verify --quiet "refs/heads/$branch_name"; then
            echo "...Branch '$branch_name' already exists. Please enter a different name..."
        else
            break
        fi
    done

    git -C "$repo_path" branch "$branch_name" && echo "...Branch '$branch_name' created..."
}

list_branches() {
    local repo_path="$1"
    verify_repo "$repo_path" || return
    echo -e "\nAvailable branches in $(basename "$repo_path"):\n"
    git -C "$repo_path" branch
}

merge_branch() {
    local repo_path="$1"
    verify_repo "$repo_path" || return

    read -p "Enter branch to merge: " branch_name
    git -C "$repo_path" merge "$branch_name" && echo "Branch '$branch_name' merged."
}

show_diffs() {
    local repo_path="$1"
    verify_repo "$repo_path" || return

    echo "Repository Differences:"

    git -C "$repo_path" diff --color || echo "No unstaged changes."

    git -C "$repo_path" diff --staged --color || echo "No staged changes."
}

view_file() {
    local repo_path="$1"
    verify_repo "$repo_path" || return

    read -p "Enter file name to view: " file_name
    [[ ! -f "$repo_path/$file_name" ]] && { echo "Error: File does not exist."; return; }

    echo -e "\nContents of '$file_name':\n"
    cat "$repo_path/$file_name"
}

delete_file() {
    local repo_path="$1"
    verify_repo "$repo_path" || return 1

    read -p "Enter file name to delete: " file_name

    if [[ ! -f "$repo_path/$file_name" ]]; then
        echo "Error: File '$file_name' does not exist." >&2
        return 1
    fi

    local file_status=$(git -C "$repo_path" status --porcelain "$file_name")

    if [[ -n "$file_status" ]]; then
        echo -e "\nWarning: File has uncommitted changes:"
        echo "Status: ${file_status:0:2}"
        git -C "$repo_path" diff -- "$file_name"

        read -p "Are you sure you want to permanently delete this file? (y/n): " confirm
        [[ "$confirm" != "y" ]] && return 0
    else
        read -p "Delete '$file_name'? (y/n): " confirm
        [[ "$confirm" != "y" ]] && return 0
    fi

    if git -C "$repo_path" rm -f "$file_name" >/dev/null 2>&1; then
        echo "File '$file_name' deleted and staged for removal."
    else

        rm -f "$repo_path/$file_name"
        echo "File '$file_name' deleted."
    fi
}

