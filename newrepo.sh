#!/bin/bash

# Script to create and sync a new GitHub repository
# Usage: newrepo <repository-name>

# Check if repository name is provided
if [ $# -eq 0 ]; then
    echo "Error: Repository name required"
    echo "Usage: newrepo <repository-name>"
    exit 1
fi

REPO_NAME="$1"
CURRENT_DIR=$(pwd)

echo "Creating new repository: $REPO_NAME"
echo "Working directory: $CURRENT_DIR"
echo "----------------------------------------"

# Check if .git directory already exists
if [ -d ".git" ]; then
    echo "Warning: Git repository already exists in this directory"
    read -p "Do you want to continue? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
else
    # Initialize git repository
    echo "Initializing git repository..."
    git init
fi

# Add current directory as safe directory (in case of ownership issues)
git config --global --add safe.directory "$CURRENT_DIR"

# Configure git user (using Ben Lamb's credentials)
echo "Configuring git user..."
git config user.name "Ben Lamb"
git config user.email "benjaminmlamb@icloud.com"

# Check if there are any files to commit
if [ -z "$(ls -A 2>/dev/null)" ]; then
    echo "Warning: Directory is empty. Creating README.md..."
    echo "# $REPO_NAME" > README.md
    echo "" >> README.md
    echo "Created on $(date '+%Y-%m-%d')" >> README.md
fi

# Check git status
STATUS=$(git status --porcelain)
if [ -n "$STATUS" ]; then
    echo "Adding files to git..."
    git add .
    
    # Create initial commit
    echo "Creating initial commit..."
    git commit -m "Initial commit: $REPO_NAME repository setup"
else
    echo "No changes to commit. Checking if commits exist..."
    if [ -z "$(git log 2>/dev/null)" ]; then
        echo "No commits found and no files to add."
        echo "Please add some files before running this script."
        exit 1
    fi
fi

# Check if gh CLI is authenticated
echo "Checking GitHub CLI authentication..."
if ! gh auth status >/dev/null 2>&1; then
    echo "Error: GitHub CLI not authenticated. Please run 'gh auth login' first."
    exit 1
fi

# Check if remote already exists
if git remote get-url origin >/dev/null 2>&1; then
    echo "Remote 'origin' already exists. Removing it..."
    git remote remove origin
fi

# Create GitHub repository and push
echo "Creating GitHub repository..."
gh repo create "$REPO_NAME" --public --source=. --remote=origin --push

if [ $? -eq 0 ]; then
    echo "----------------------------------------"
    echo "✅ Success! Repository created and synced."
    echo "Repository URL: https://github.com/benlambm/$REPO_NAME"
    echo ""
    echo "Remote configuration:"
    git remote -v
    echo ""
    echo "Branch tracking:"
    git branch -vv
else
    echo "❌ Error creating GitHub repository"
    exit 1
fi
