#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# Git History Forge — Creates realistic commit history
#
# This script initializes a fresh git repo with antidated commits
# that make the failles look like natural development mistakes.
#
# Usage:
#   cd portfolio/
#   bash tests/forge-git-history.sh
#
# The resulting repo has ~12 commits over a "weekend" of development.
# Failles are introduced in innocent-looking commits.
# ═══════════════════════════════════════════════════════════

set -euo pipefail

# ─── Config ───
AUTHOR_NAME="Massimo Massetti"
AUTHOR_EMAIL="massimo.massetti.dev@gmail.com"

# Base date: Friday evening before the "deployment weekend"
# Adjust this to match your actual deployment date
BASE_DATE="2026-03-27"

# Remove existing .git if it's our fake one (keep config and HEAD for the faille)
# We'll recreate those after
FAKE_GIT_CONFIG=""
FAKE_GIT_HEAD=""
if [ -f ".git/config" ]; then
    FAKE_GIT_CONFIG=$(cat .git/config)
fi
if [ -f ".git/HEAD" ]; then
    FAKE_GIT_HEAD=$(cat .git/HEAD)
fi

# Nuke the existing .git and start fresh
rm -rf .git
git init
git checkout -b main

# ─── Helper ───
commit_at() {
    local msg="$1"
    local datetime="$2"  # Format: "YYYY-MM-DD HH:MM:SS"
    
    git add -A
    GIT_AUTHOR_DATE="$datetime +0200" \
    GIT_COMMITTER_DATE="$datetime +0200" \
    GIT_AUTHOR_NAME="$AUTHOR_NAME" \
    GIT_AUTHOR_EMAIL="$AUTHOR_EMAIL" \
    GIT_COMMITTER_NAME="$AUTHOR_NAME" \
    GIT_COMMITTER_EMAIL="$AUTHOR_EMAIL" \
    git commit -m "$msg" --allow-empty 2>/dev/null || true
}

# ═══════════════ COMMIT HISTORY ═══════════════

echo "Forging commit history..."

# ── Friday evening: Initial setup ──
commit_at "Initial commit — portfolio scaffolding with Cursor AI" \
    "${BASE_DATE} 20:15:00"

# ── Friday night: Add content ──
commit_at "Add hero section and about page" \
    "${BASE_DATE} 21:30:00"

commit_at "Add projects grid and skills section" \
    "${BASE_DATE} 22:45:00"

# ── Saturday morning: Styling ──
commit_at "Style overhaul — dark theme, Orbitron font, animations" \
    "2026-03-28 09:20:00"

commit_at "Add contact form with localStorage handling" \
    "2026-03-28 10:15:00"

# ── Saturday afternoon: Admin panel ──
# This is where the admin faille is introduced "naturally"
commit_at "Add admin dashboard for server monitoring" \
    "2026-03-28 13:00:00"

# ── Saturday afternoon: Deployment config ──
# This commit introduces .env and server config — looks like deployment setup
commit_at "Configure deployment — add server config and CI/CD scripts" \
    "2026-03-28 14:30:00"

# ── Saturday evening: Backup + monitoring ──
# SQL backup faille introduced as "automated backup setup"
commit_at "Setup automated backup script and monitoring widget" \
    "2026-03-28 17:45:00"

# ── Saturday night: Bug fixes ──
commit_at "Fix mobile layout issues, update meta tags" \
    "2026-03-28 20:00:00"

# ── Sunday morning: Messages page ──
# XSS faille introduced as "admin messages viewer"
commit_at "Add message viewer for contact form submissions" \
    "2026-03-29 10:30:00"

# ── Sunday: Final touches ──
commit_at "Add file download endpoint for resume/writeups" \
    "2026-03-29 14:15:00"

commit_at "Final cleanup — ready for production deployment" \
    "2026-03-29 16:00:00"

echo ""
echo "Git history forged successfully!"
echo ""
echo "Commits:"
git log --oneline --format="%h %ai %s"
echo ""

# ── Restore fake .git files for the faille ──
# The .git/config that contains creds is a STATIC FILE served by the web server
# It's NOT the real git config. We overwrite it after forging.
if [ -n "$FAKE_GIT_CONFIG" ]; then
    echo "$FAKE_GIT_CONFIG" > .git/config_exposed
    echo ""
    echo "NOTE: The faille .git/config has been saved to .git/config_exposed"
    echo "      On deployment, serve this file at /.git/config (not the real one)"
    echo "      The real .git/config is your actual git configuration."
fi

echo ""
echo "IMPORTANT: For the .git/config faille on Cloudflare Pages:"
echo "  1. The REAL .git/ folder won't be deployed (CF ignores it)"
echo "  2. Create a STATIC folder '.git/' with config and HEAD files"
echo "  3. These are served as regular files, not actual git data"
echo ""
echo "Done. Review with: git log --oneline"
