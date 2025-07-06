# Git Repository Manager

A Bash-based interactive tool to manage Git repositories, users, branches, and remotes with authentication and file-level operations. Designed for local use with personal access to GitHub remotes using PATs.

---

## Features

### User Management
- Register with secure password (hashed with SHA256)
- Login and maintain user session
- Stores user data and repositories in a structured directory

### Repository Management
- Create, list, delete, and clone repositories
- Automatically initializes Git with an initial commit
- Supports GitHub cloning via personal access token (PAT)

### Branch Management
- Create and delete branches
- List and switch between branches
- Merge branches
- Create branches from specific commits

### File Management
- Add, update, view, and delete files in a branch
- List all files tracked by Git in a repository

### Commit & Versioning
- Stage and commit changes with messages
- View commit history with graphs
- Restore to previous commits
- View specific commit details

### Remote Operations
- Add or update GitHub remotes using PAT
- Push/pull from GitHub
- Track new branches from remote
- List remotes

### Utilities
- View Git status
- Show diffs (staged/unstaged)
- Stash and pop changes
- Hard reset to HEAD

---

## Project Structure

- main.sh # Entry point and main menu logic
- users.db # User credentials (username:hashed_password)
- user_data/ # Directory storing user-specific repositories
- repo_manage.sh # Repository-level operations
- branch_manage.sh # Branch, file, and versioning operations
- remote_manage.sh # GitHub remote and network sync functions
- commit_manage.sh # Commit staging and history handling

---

## Prerequisites

- Git must be installed and configured
- Bash (Unix-based system recommended)
- Internet connection for remote operations
- GitHub Personal Access Token (PAT) for push/pull/clone

---

## How to Run

1. Open terminal and give execute permission:
    ```bash
    chmod +x main.sh
    ```

2. Run the main script:
    ```bash
    ./main.sh
    ```

---

## GitHub Remote Authentication

When prompted for GitHub operations:
- Enter your **GitHub username**
- Use a **Personal Access Token (PAT)** instead of your password

You can generate a PAT from GitHub by visiting:  
[https://github.com/settings/tokens](https://github.com/settings/tokens)

---

## Notes

- Each user has their own isolated repository space inside `user_data/`
- Passwords are hashed using `sha256sum`, but not salted — use in trusted environments only
- No external dependencies used besides Git and Bash

---
