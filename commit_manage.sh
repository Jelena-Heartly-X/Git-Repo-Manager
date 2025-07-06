commit_changes() {
    local repo_path="$1"
    verify_repo "$repo_path" || return

    git -C "$repo_path" status --short

    if ! git -C "$repo_path" status --short | grep -q '.'; then
        echo "No changes to commit."
        return
    fi

    read -p "Enter commit message: " commit_msg


    if [[ -z "$commit_msg" ]]; then
        echo "Commit message cannot be empty."
        return
    fi

    git -C "$repo_path" commit -m "$commit_msg" && echo "Changes committed."
}
