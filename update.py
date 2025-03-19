import os
import re
import subprocess
import argparse
import json
import requests
from typing import Optional

PACKAGE_FILE = "Package.swift"
GITHUB_API_URL = "https://api.github.com"

def get_current_version(package_file: str) -> str:
    """Get the current version from Git tags."""
    try:
        # Get the latest tag that matches vX.Y.Z format
        result = subprocess.run(
            ["git", "tag", "--list", "v*.*.*"],
            capture_output=True,
            text=True,
            check=True
        )
        
        # Parse all version tags and find the latest
        version_tags = result.stdout.strip().split('\n')
        if not version_tags or version_tags == ['']:
            return "0.0.0"  # Initial version if no tags exist
            
        versions = []
        for tag in version_tags:
            match = re.match(r'v(\d+\.\d+\.\d+)', tag)
            if match:
                versions.append(match.group(1))
                
        if not versions:
            return "0.0.0"  # Initial version if no valid version tags
            
        # Sort versions and return the latest
        versions.sort(key=lambda v: [int(x) for x in v.split('.')])
        return versions[-1]
        
    except subprocess.CalledProcessError:
        print("Warning: Could not get version from Git tags")
        return "0.0.0"  # Initial version if git command fails

def run_tests() -> None:
    """Run the Swift package tests."""
    print("Running tests...")
    try:
        subprocess.run(["swift", "test", "-v"], check=True)
        print("✅ All tests passed.")
    except subprocess.CalledProcessError:
        print("❌ Tests failed!")
        raise

def bump_version(version: str, part: str) -> str:
    """Bump the version number."""
    major, minor, patch = map(int, version.split("."))

    if part == "major":
        major += 1
        minor = 0
        patch = 0
    elif part == "minor":
        minor += 1
        patch = 0
    elif part == "patch":
        patch += 1
    else:
        raise ValueError("Invalid part to bump. Choose 'major', 'minor', or 'patch'.")

    return f"{major}.{minor}.{patch}"

def update_package_file(package_file: str, new_version: str) -> None:
    """No need to update Package.swift as versions are managed through Git tags."""
    pass  # This function is now a no-op since we use Git tags for versioning

def get_github_repo() -> tuple[str, str]:
    """Get GitHub repository owner and name from git remote URL."""
    try:
        remote_url = subprocess.check_output(
            ["git", "config", "--get", "remote.origin.url"],
            universal_newlines=True
        ).strip()

        # Handle different GitHub URL formats
        if remote_url.startswith("git@github.com:"):
            path = remote_url.split("git@github.com:")[1]
        elif remote_url.startswith("https://github.com/"):
            path = remote_url.split("https://github.com/")[1]
        else:
            raise ValueError(f"Unsupported GitHub URL format: {remote_url}")

        path = path.replace(".git", "")
        owner, repo = path.split("/")
        return owner, repo
    except subprocess.CalledProcessError:
        raise ValueError("Could not get GitHub repository information")

def create_github_update(version: str, token: Optional[str] = None) -> None:
    """Create a new release on GitHub."""
    if not token:
        # Try to get token from Config.swift
        try:
            import subprocess
            result = subprocess.run(
                ["swift", "-e", "import Foundation; print(Config.githubToken)"],
                capture_output=True,
                text=True,
                check=True
            )
            token = result.stdout.strip()
        except subprocess.CalledProcessError:
            token = os.environ.get("GITHUB_TOKEN")
            if not token:
                raise ValueError("GitHub token not provided. Set GITHUB_TOKEN environment variable or add it to Config.plist.")

    owner, repo = get_github_repo()
    url = f"{GITHUB_API_URL}/repos/{owner}/{repo}/releases"
    
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    data = {
        "tag_name": f"v{version}",
        "target_commitish": "main",
        "name": f"Version {version}",
        "body": f"Release version {version}",
        "draft": False,
        "prerelease": False
    }
    
    response = requests.post(url, headers=headers, json=data)
    if response.status_code != 201:
        raise ValueError(f"Failed to create GitHub release: {response.json()}")
    print(f"🎉 Created GitHub release for version {version}")

def tag_version_in_git(version: str) -> None:
    """Tag the new version in Git and push the tag."""
    tag = f"v{version}"
    print(f"Tagging the new version: {tag}")
    try:
        # Create and push tag
        subprocess.run(["git", "tag", "-a", tag, "-m", f"Version {version}"], check=True)
        subprocess.run(["git", "push", "origin", tag], check=True)
        print(f"🏷️  Version {version} tagged and pushed to Git.")
    except subprocess.CalledProcessError:
        print("❌ Git operations failed!")
        raise

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Create Git tag and GitHub update for Swift package.",
        formatter_class=argparse.RawTextHelpFormatter,
        epilog="""
Examples:
  python update.py patch
  python update.py minor --skip-tests
  python update.py major --skip-github
  python update.py patch --dry-run
        """
    )
    parser.add_argument("part", choices=["major", "minor", "patch"],
                      help="Which part of the version to bump")
    parser.add_argument("--skip-tests", action="store_true",
                      help="Skip running the test suite")
    parser.add_argument("--skip-github", action="store_true",
                      help="Skip GitHub update creation")
    parser.add_argument("--dry-run", action="store_true",
                      help="Show what would be done without making actual changes")
    parser.add_argument("--token", help="GitHub personal access token")
    
    args = parser.parse_args()

    try:
        # Step 1: Get the current version from Git tags
        current_version = get_current_version(PACKAGE_FILE)
        print(f"📎 Current version: {current_version}")

        # Step 2: Calculate new version
        new_version = bump_version(current_version, args.part)
        print(f"🎯 Target version: {new_version}")

        if args.dry_run:
            print("\n🔍 Dry run completed. No changes made.")
            return

        # Step 3: Run tests (unless skipped)
        if not args.skip_tests:
            run_tests()
        else:
            print("⏩ Skipping tests as requested.")

        # Step 4: Stage all changes, commit, and push
        print("📂 Staging all changes...")
        subprocess.run(["git", "add", "."], check=True)
        print("📝 Committing changes...")
        subprocess.run(["git", "commit", "-m", f"Bump version to {new_version}"], check=True)
        print("🚀 Pushing changes to remote...")
        subprocess.run(["git", "push"], check=True)

        # Step 5: Git operations and GitHub update (unless skipped)
        if not args.skip_github:
            tag_version_in_git(new_version)
            create_github_update(new_version, args.token)
        else:
            print("⏩ Skipping Git operations and GitHub update as requested.")

        print(f"\n✅ Version update to {new_version} completed successfully!")

    except Exception as e:
        print(f"\n❌ Error: {str(e)}")
        raise

if __name__ == "__main__":
    main()

# Version Update Options Guide:
# ---------------------------
# 1. Version Parts:
#    - patch: For backwards-compatible bug fixes (1.2.3 -> 1.2.4)
#    - minor: For new features that don't break existing functionality (1.2.3 -> 1.3.0)
#    - major: For changes that break backwards compatibility (1.2.3 -> 2.0.0)
#
# 2. Optional Flags:
#    --skip-tests:   Skip running the test suite before updating (use with caution)
#    --skip-github:  Skip creating Git tags and GitHub update
#    --dry-run:      Preview what would happen without making any actual changes
#    --token:        Provide GitHub personal access token (alternatively use GITHUB_TOKEN env var)
#
# Examples:
#   python update.py patch              # Bump patch version with all checks
#   python update.py minor --skip-tests # Add new feature, skip testing
#   python update.py major --dry-run    # Preview a major version bump
#   python update.py patch --token xyz  # Provide GitHub token directly 