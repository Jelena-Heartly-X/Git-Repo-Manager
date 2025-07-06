#!/bin/bash

source branch_manage.sh
source remote_manage.sh

create_repository() {
    local user_home="$1"
    echo -e "\n"

    while true; do
        read -p "Enter repository name: " repo_name

        if [[ -z "$repo_name" ]]; then
            echo "...Error: Repository name cannot be empty!..." >&2
            continue
        fi

        local repo_path="$user_home/$repo_name"

        if [[ -d "$repo_path" ]]; then
            echo "...Error: Repository '$repo_name' already exists! Please enter a different name..." >&2
        else
            break
        fi
    done

    (
        mkdir -p "$repo_path" || exit 1
        cd "$repo_path" && {
            git init || exit 1
            echo "# $repo_name" > README.md
            git add README.md
            git commit -m "Initial commit"

            if ! git rev-parse --verify --quiet main >/dev/null; then
                git branch -m main
            fi

            echo -e "\nRepository '$repo_name' created at $repo_path"
        }
    )

    if [[ $? -ne 0 ]] || [[ ! -d "$repo_path/.git" ]]; then
        echo -e "\n...Error: Failed to create repository!..." >&2
        [[ -d "$repo_path" ]] && rm -rf "$repo_path"
        return 1
    fi

    sync
    return 0
}


list_repositories() {
    local user_home="$1"

    [[ "$user_home" != */ ]] && user_home="$user_home/"

    echo -e "\n\e[1;34mUser Repositories:\e[0m"
    echo "Checking path: $user_home"

    if [ ! -d "$user_home" ]; then
        echo -e "\e[1;31mError: Path does not exist.\e[0m"
        return
    fi

    local repos=()
    while IFS= read -r -d '' dir; do
        repos+=("$(basename "$(dirname "$dir")")")
    done < <(find "$user_home" -type d -name ".git" -prune -print0)

    if [ ${#repos[@]} -gt 0 ]; then
        echo -e "\e[1;32mRepositories found (${#repos[@]}):\e[0m"
        for repo in "${repos[@]}"; do
            echo "  ➜ $repo"
        done
    else
        echo -e "\e[1;31mNo repositories found.\e[0m"
    fi
}


delete_repository() {
    local user_home="$1"
    echo -e "\n"
    read -p "Enter repository name to delete: " repo_name

    if [[ -z "$repo_name" ]]; then
        echo "Error: Repository name cannot be empty!"
        return 1
    fi

    local repo_path="$user_home/$repo_name"

    if [[ ! -d "$repo_path" ]]; then
        echo "Error: Repository '$repo_name' does not exist!"
        return 1
    fi

    read -p "Are you sure you want to permanently delete '$repo_name'? [y/N] " confirm
    [[ "$confirm" != [yY] ]] && return 0

    (
        rm -rf "$repo_path" && {
            sync
            echo "Repository '$repo_name' deleted successfully."
        }
    ) || {
        echo "Error: Failed to delete repository!"
        return 1
    }
}

manage_branch() {
    local repo_path="$1"
    echo -e "\nAvailable branches in $(basename "$repo_path"):"
    git -C "$repo_path" branch
    read -p "Enter the branch you want to manage: " branch_name

    if ! git -C "$repo_path" rev-parse --verify "$branch_name" >/dev/null 2>&1; then
        echo "...Error: Branch '$branch_name' does not exist..."
        return
    fi

    git -C "$repo_path" checkout "$branch_name"

    if git -C "$repo_path" branch -vv | grep -q '\[gone\]'; then
        echo "...Remote tracking is missing. Reattaching to remote..."
        git -C "$repo_path" branch --set-upstream-to=origin/"$branch_name" "$branch_name" || \
        echo "...Failed to reattach upstream tracking..."
    fi

    while true; do
        echo -e "\nMANAGE BRANCH: $branch_name"
        echo "1. Add File"
        echo "2. List Files in Branch"
        echo "3. Update File"
        echo "4. Delete File"
        echo "5. View File Content"
        echo "6. Exit"
	echo -e "\n"
        read -p "Choose an option: " choice

        case $choice in
            1) add_file "$repo_path" "$branch_name" ;;
            2) list_files "$repo_path" "$branch_name" ;;
            3) update_file "$repo_path" "$branch_name" ;;
            4) delete_file "$repo_path" "$branch_name" ;;
            5) view_file "$repo_path" "$branch_name" ;;
            6) break ;;
            *) echo "Invalid option. Please try again." ;;
        esac
    done
}

manage_repository() {
    local user_home="$1"
    read -p "Enter repository name to manage: " repo_name
    local repo_path="$user_home/$repo_name"

    if [ ! -d "$repo_path" ]; then
        echo "Error: Repository does not exist!"
        return 1
    fi

    while true; do
        echo -e "\nMANAGE REPOSITORY: $(basename "$repo_path")"
        echo "1. Create Branch"
        echo "2. Manage Branch"
        echo "3. List Branches"
        echo "4. Merge Branch"
        echo "5. Delete Branch"
        echo "6. Push"
        echo "7. Pull"
        echo "8. Commit Changes"
        echo "9. Show Diffs"
        echo "10. List Versions (Commits)"
        echo "11. View a Specific Version"
        echo "12. Restore an Older Version"
        echo "13. Create Branch from a Version"
        echo "14. Show Repository Status"
        echo "15. Stash Changes"
        echo "16. pop stashed changes"
        echo "17. Revert Changes (Reset)"
        echo "18. Configure Remote Repository"
	echo "19. List Remote Repositories"
        echo "20. Exit"
	echo -e "\n"
        read -p "Choose an option: " option
        case $option in
            1) create_branch "$repo_path" ;;
            2) manage_branch "$repo_path" ;;
            3) list_branches "$repo_path" ;;
            4) merge_branch "$repo_path" ;;
            5) delete_branch "$repo_path" ;;
            6) push_repository "$repo_path" ;;
            7) pull_repository "$repo_path" ;;
            8) commit_changes "$repo_path" ;;
            9) show_diffs "$repo_path" "" ;;
            10) list_versions "$repo_path" ;;
            11) view_version "$repo_path" ;;
            12) restore_commit "$repo_path" "" ;;
            13) create_branch_from_version "$repo_path" ;;
            14) git -C "$repo_path" status ;;
            15) git -C "$repo_path" stash ;;
	    16)
	        if git -C "$repo_path" stash list | grep -q "stash@"; then
        	    git -C "$repo_path" stash pop
	        else
        	    echo "No stashed changes found."
	        fi
        	;;
            17) git -C "$repo_path" reset --hard HEAD ;;
            18) configure_remote "$repo_path" ;;
	    19) list_remotes "$repo_path" ;;
            20) break ;;
            *) echo "Invalid option, try again!" ;;
        esac
    done
}
