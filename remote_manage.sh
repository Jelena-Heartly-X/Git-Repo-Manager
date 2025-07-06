#!/bin/bash

list_remotes() {
    echo "===== List Remote Repositories ====="
    read -p "Enter repository path: " repo_path

    if [ ! -d "$repo_path/.git" ]; then
        echo "...Error: '$repo_path' is not a Git repository..."
        return
    fi

    echo "...Listing remotes for repository '$repo_path'..."
    git -C "$repo_path" remote -v
}


clone_repository() {
    echo "===== Clone GitHub Repository ====="
    read -p "Enter GitHub repository URL: " repo_url
    read -p "Enter destination folder name: " destination

    read -p "Enter your GitHub username: " github_user
    read -sp "Enter your GitHub Personal Access Token (PAT): " github_token
    echo

    repo_url_with_auth="https://${github_user}:${github_token}@${repo_url#https://}"

    local_dir="${USER_HOME}/${destination}"

    while [ -d "$local_dir" ]; do
        echo " Error: Directory '$destination' already exists."
        read -p "Enter a new repository name: " destination
        local_dir="${USER_HOME}/${destination}"
    done

    if git clone "$repo_url_with_auth" "$local_dir"; then
        echo "Repository cloned successfully into '$local_dir'."
    else
        echo "Failed to clone the repository."
    fi
}

push_repository() {
    echo "===== Push GitHub Repository ====="
    read -p "Enter repository path: " repo_path


    if [ ! -d "$repo_path/.git" ]; then
        echo " Error: '$repo_path' is not a Git repository."
        return
    fi

    read -p "Enter GitHub remote name (e.g., origin): " remote_name


    if ! git -C "$repo_path" remote | grep -q "$remote_name"; then
        echo "Error: Remote '$remote_name' not found."
        return
    fi


    echo " Pushing all branches and tags to GitHub..."
    if git -C "$repo_path" push --all "$remote_name" && git -C "$repo_path" push --tags "$remote_name"; then
        echo "Successfully pushed to GitHub remote '$remote_name'."
    else
        echo "Failed to push to GitHub remote '$remote_name'."
    fi


    current_branch=$(git -C "$repo_path" branch --show-current)
    if ! git -C "$repo_path" rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
        echo "Setting upstream tracking for $current_branch..."
        git -C "$repo_path" branch --set-upstream-to="$remote_name/$current_branch" "$current_branch" || \
        echo "Failed to set upstream tracking."
    fi
}


pull_repository() {
    echo "===== Pull GitHub Repository ====="
    read -p "Enter repository path: " repo_path


    if [ ! -d "$repo_path/.git" ]; then
        echo "Error: '$repo_path' is not a Git repository."
        return
    fi

    read -p "Enter GitHub remote name (e.g., origin): " remote_name

    if ! git -C "$repo_path" remote | grep -q "$remote_name"; then
        echo "Remote '$remote_name' not found. Please add it first."
        return
    fi

    echo "Fetching changes from GitHub..."
    if git -C "$repo_path" fetch --prune "$remote_name"; then
        current_branch=$(git -C "$repo_path" rev-parse --abbrev-ref HEAD)
        echo " Pulling latest changes from branch '$current_branch'..."

        if git -C "$repo_path" pull "$remote_name" "$current_branch"; then
            echo "Successfully pulled from GitHub remote '$remote_name' (branch: '$current_branch')."

            echo "Checking for new branches..."
            remote_branches=$(git -C "$repo_path" branch -r | grep "$remote_name/" | sed "s|$remote_name/||g")

            for branch in $remote_branches; do
                if ! git -C "$repo_path" branch | grep -q "$branch"; then
                    echo " Adding new branch: $branch"
                    git -C "$repo_path" branch --track "$branch" "$remote_name/$branch"
                fi
            done

            echo "All new branches have been added."
        else
            echo " Failed to pull changes from branch '$current_branch'."
        fi
    else
        echo "Failed to fetch changes."
    fi
}

configure_remote() {
    echo "===== Configure GitHub Remote with PAT ====="
    read -p "Enter repository path: " repo_path


    if [ ! -d "$repo_path/.git" ]; then
        echo "Error: '$repo_path' is not a Git repository."
        return
    fi

    read -p "Enter remote name (e.g., origin): " remote_name
    read -p "Enter GitHub repository URL (without PAT): " remote_url


    read -sp "Enter your GitHub PAT: " pat
    echo

    if [[ "$remote_url" == https://* ]]; then
        auth_url="https://$pat@${remote_url#https://}"
    else
        echo "Unsupported remote URL format: $remote_url"
        return
    fi

    if git -C "$repo_path" remote | grep -q "$remote_name"; then
        git -C "$repo_path" remote set-url "$remote_name" "$auth_url"
        echo "Remote '$remote_name' updated with PAT authentication."
    else
        git -C "$repo_path" remote add "$remote_name" "$auth_url"
        echo "Remote '$remote_name' added with PAT authentication."
    fi

    echo "Verifying remote configuration..."
    git -C "$repo_path" remote -v
}
