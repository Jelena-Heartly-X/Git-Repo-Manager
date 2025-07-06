#!/bin/bash

source repo_manage.sh
source branch_manage.sh
source remote_manage.sh
source commit_manage.sh

USER_DB="users.db"
USER_DATA_DIR="user_data"
CURRENT_USER=""
USER_HOME=""

mkdir -p "$USER_DATA_DIR"


hash_password() { echo -n "$1" | sha256sum | awk '{print $1}'; }

validate_username() {
    local username="$1"
    [[ "$username" =~ ^[a-zA-Z0-9_]{3,20}$ ]]
}

validate_password() {
    local password="$1"
    [[ ${#password} -ge 8 ]] &&
    [[ "$password" =~ [A-Z] ]] &&
    [[ "$password" =~ [a-z] ]] &&
    [[ "$password" =~ [0-9] ]] &&
    [[ "$password" =~ [@#\$%\&\*\!\-\+\_\.] ]]
}

register_user()
{
    echo "===== User Registration ====="

    while true; do
        read -p "Enter a username: " username
        if ! validate_username "$username"; then
            echo "...Invalid username. Use 3-20 alphanumeric characters,underscores (_)..."
        elif grep -q "^$username:" "$USER_DB"; then
            echo "...Username already exists. Try again..."
        else
            break
        fi
    done

    while true; do
        read -s -p "Enter a password: " password; echo
        read -s -p "Confirm password: " confirm_password; echo
        if [ "$password" != "$confirm_password" ]; then
            echo "...Passwords do not match. Try again..."
        elif ! validate_password "$password"; then
            echo "...Password must be at least 8 characters long and contain: 1 uppercase, 1 lowercase, 1 digit, and 1 special character..."
        else
            break
        fi
    done

    echo "$username:$(hash_password "$password")" >> "$USER_DB"
    mkdir -p "$USER_DATA_DIR/$username"
    echo -e "...User '$username' registered successfully...\n"
}

login_user() {
    echo -e "\n===== User Login ====="

    read -p "Enter username: " username

    if ! grep -q "^$username:" "$USER_DB"; then
        echo "...User not found..."
        return 1
    fi

    read -s -p "Enter password: " password; echo

    if ! grep -q "^$username:$(hash_password "$password")$" "$USER_DB"; then
        echo "...Invalid password. Try again..."
        return 1
    fi

    CURRENT_USER="$username"
    USER_HOME="$USER_DATA_DIR/$username"
    mkdir -p "$USER_HOME"

    echo -e "Login successful!\n"
}

[ ! -f "$USER_DB" ] && touch "$USER_DB"

while true; do
    echo "========================="
    echo " GIT REPOSITORY MANAGER"
    echo "========================="
    echo "1. Login"
    echo "2. Register"
    echo "3. Exit"
    echo "========================="
    read -p "Choose an option: " choice
    case "$choice" in
        1) login_user && break ;;
        2) register_user ;;
        3) echo "Exiting..."; exit 0 ;;
        *) echo -e "...Invalid option, try again!..." ;;
    esac
done

while true; do
    echo "====================="
    echo "User: $CURRENT_USER"
    echo "====================="
    echo "1. Create Repository"
    echo "2. Manage Repository"
    echo "3. List Repositories"
    echo "4. Delete Repository"
    echo "5. Clone Repository"
    echo "6. Exit"
    echo "====================="
    read -p "Choose an option: " option
    case "$option" in
        1) create_repository "$USER_HOME" ;;
        2) manage_repository "$USER_HOME" ;;
        3) list_repositories "$USER_HOME" ;;
        4) delete_repository "$USER_HOME" ;;
        5) clone_repository ;;
        6) echo "Exiting..."; exit 0 ;;
        *) echo -e "...Invalid option, try again!..." ;;
    esac
done
