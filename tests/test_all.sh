#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# Portfolio — Test Suite — Test Suite Complète
# Vérifie chaque faille, la cohérence des credentials,
# et l'absence de mots interdits dans le code source.
#
# Usage:
#   chmod +x tests/test_all.sh
#   cd portfolio/
#   ./tests/test_all.sh
#
# Pour tester contre un site déployé :
#   SITE_URL=https://massimomassetti.pages.dev ./tests/test_all.sh
# ═══════════════════════════════════════════════════════════

set -uo pipefail

# ─── Config ───
SITE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SITE_URL="${SITE_URL:-}"  # Vide = tests locaux sur fichiers
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# ─── Credentials attendus ───
CRED_PRINCIPAL_USER="root"
CRED_PRINCIPAL_PASS="Gr1zzly!Pr0d_2026"
CRED_ADMIN_USER="admin"
CRED_ADMIN_PASS="@dminC0ns0le_01"
CRED_DEPLOY_USER="deploy"
CRED_DEPLOY_PASS="D3pl0y_K3y#staging"
SSH_HOST_PLACEHOLDER="[IP_DU_VPS]"

# ─── Colors ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}✓${NC} $1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { echo -e "  ${RED}✗${NC} $1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; WARN_COUNT=$((WARN_COUNT+1)); }
header() { echo -e "\n${CYAN}${BOLD}═══ $1 ═══${NC}"; }

# ═══════════════ TEST 1: FICHIERS REQUIS ═══════════════
header "TEST 1: Structure des fichiers"

REQUIRED_FILES=(
    "index.html"
    ".env"
    "robots.txt"
    ".git/config"
    ".git/HEAD"
    "admin/index.html"
    "admin/messages.html"
    "backup/site_backup.sql.bak"
    "assets/css/style.css"
    "assets/js/main.js"
    "assets/js/net-activity.js"
    "assets/data/widget-data.json"
    "functions/api/file.js"
    "functions/_middleware.js"
)

for f in "${REQUIRED_FILES[@]}"; do
    if [ -f "$SITE_DIR/$f" ]; then
        pass "$f exists"
    else
        fail "$f MISSING"
    fi
done

# ═══════════════ TEST 2: FAILLE 1 — .env ═══════════════
header "TEST 2: Faille 1 — .env exposé"

ENV_FILE="$SITE_DIR/.env"
if [ -f "$ENV_FILE" ]; then
    if grep -q "SSH_HOST=" "$ENV_FILE"; then
        pass ".env contains SSH_HOST"
    else
        fail ".env missing SSH_HOST"
    fi
    if grep -q "SSH_USER=root" "$ENV_FILE"; then
        pass ".env contains SSH_USER=root"
    else
        fail ".env missing SSH_USER=root"
    fi
    if grep -q "$CRED_PRINCIPAL_PASS" "$ENV_FILE"; then
        pass ".env contains principal password"
    else
        fail ".env missing principal password"
    fi
    if grep -q "Cursor AI" "$ENV_FILE"; then
        pass ".env has credible AI-generated comment"
    else
        warn ".env missing AI comment (less realistic)"
    fi
fi

# ═══════════════ TEST 3: FAILLE 2 — Admin Panel ═══════════════
header "TEST 3: Faille 2 — Admin Panel"

ADMIN_FILE="$SITE_DIR/admin/index.html"
if [ -f "$ADMIN_FILE" ]; then
    if grep -q "$CRED_ADMIN_USER" "$ADMIN_FILE" && grep -q "$CRED_ADMIN_PASS" "$ADMIN_FILE"; then
        pass "Admin panel contains admin credentials in JS"
    else
        fail "Admin panel missing credentials"
    fi
    if grep -q "TODO" "$ADMIN_FILE"; then
        pass "Admin panel has TODO comments (realistic)"
    else
        warn "Admin panel missing TODO comments"
    fi
    if grep -q "ssh" "$ADMIN_FILE" || grep -q "SSH" "$ADMIN_FILE"; then
        pass "Admin panel reveals SSH connection info"
    else
        fail "Admin panel doesn't show SSH info after login"
    fi
fi

# ═══════════════ TEST 4: FAILLE 3 — XSS + JWT ═══════════════
header "TEST 4: Faille 3 — XSS & JWT Cookie"

MSG_FILE="$SITE_DIR/admin/messages.html"
if [ -f "$MSG_FILE" ]; then
    if grep -q "innerHTML" "$MSG_FILE"; then
        pass "messages.html uses innerHTML (XSS vulnerable)"
    else
        fail "messages.html doesn't use innerHTML"
    fi
    if grep -q "admin_session=" "$MSG_FILE"; then
        pass "messages.html sets admin_session cookie"
    else
        fail "messages.html missing JWT cookie"
    fi
    if grep -q "eyJ" "$MSG_FILE"; then
        pass "JWT token present in cookie value"
    else
        fail "JWT token missing"
    fi
    # Verify JWT contains deploy creds
    JWT_PAYLOAD=$(grep -o 'eyJ[A-Za-z0-9_-]*\.eyJ[A-Za-z0-9_-]*' "$MSG_FILE" | head -1 | cut -d. -f2)
    if [ -n "$JWT_PAYLOAD" ]; then
        # Add padding and decode
        PADDED="${JWT_PAYLOAD}==="
        DECODED=$(echo "$PADDED" | base64 -d 2>/dev/null || echo "")
        if echo "$DECODED" | grep -q "$CRED_DEPLOY_USER"; then
            pass "JWT payload contains deploy username"
        else
            warn "JWT payload doesn't contain expected deploy username (check base64 encoding)"
        fi
    fi
    # Check no auth required
    if ! grep -q "sessionStorage\|authenticated\|login" "$MSG_FILE"; then
        pass "messages.html has no auth check (accessible directly)"
    else
        warn "messages.html might have auth — verify it's accessible without login"
    fi
fi

# ═══════════════ TEST 5: FAILLE 4 — .git/config ═══════════════
header "TEST 5: Faille 4 — .git/config"

GIT_CONFIG="$SITE_DIR/.git/config"
if [ -f "$GIT_CONFIG" ]; then
    if grep -q "$CRED_PRINCIPAL_PASS" "$GIT_CONFIG"; then
        pass ".git/config contains principal password in remote URL"
    else
        fail ".git/config missing password in remote URL"
    fi
    if grep -q "massimomassetti\|grizzly2005" "$GIT_CONFIG"; then
        pass ".git/config contains realistic username"
    else
        warn ".git/config missing username"
    fi
    if grep -q "github.com" "$GIT_CONFIG"; then
        pass ".git/config has GitHub remote"
    else
        fail ".git/config missing remote"
    fi
fi

GIT_HEAD="$SITE_DIR/.git/HEAD"
if [ -f "$GIT_HEAD" ]; then
    if grep -q "ref: refs/heads/main" "$GIT_HEAD"; then
        pass ".git/HEAD points to main branch"
    else
        warn ".git/HEAD doesn't point to main"
    fi
fi

# ═══════════════ TEST 6: FAILLE 5 — Directory Traversal Worker ═══════════════
header "TEST 6: Faille 5 — Directory Traversal (Worker)"

WORKER_FILE="$SITE_DIR/functions/api/file.js"
if [ -f "$WORKER_FILE" ]; then
    if grep -q "/etc/passwd" "$WORKER_FILE"; then
        pass "Worker contains fake /etc/passwd"
    else
        fail "Worker missing /etc/passwd response"
    fi
    if grep -q "/etc/shadow" "$WORKER_FILE"; then
        pass "Worker contains fake /etc/shadow"
    else
        fail "Worker missing /etc/shadow response"
    fi
    if grep -q "massimo" "$WORKER_FILE"; then
        pass "Fake passwd/shadow contains massimo user"
    else
        warn "Fake system files missing massimo user"
    fi
    if grep -q 'resolveTraversal\|\.\./' "$WORKER_FILE"; then
        pass "Worker handles path traversal sequences"
    else
        fail "Worker doesn't process ../ sequences"
    fi
fi

# ═══════════════ TEST 7: FAILLE 6 — Backup SQL ═══════════════
header "TEST 7: Faille 6 — Backup SQL"

SQL_FILE="$SITE_DIR/backup/site_backup.sql.bak"
if [ -f "$SQL_FILE" ]; then
    if grep -q "ssh_password" "$SQL_FILE"; then
        pass "SQL dump contains ssh_password key"
    else
        fail "SQL dump missing ssh_password"
    fi
    if grep -q "$CRED_PRINCIPAL_PASS" "$SQL_FILE"; then
        pass "SQL dump contains principal password value"
    else
        fail "SQL dump missing principal password"
    fi
    if grep -q "MySQL dump" "$SQL_FILE"; then
        pass "SQL dump has realistic MySQL header"
    else
        warn "SQL dump missing MySQL header"
    fi
    if grep -q "2026-03-28" "$SQL_FILE"; then
        pass "SQL dump has consistent date (Mar 28)"
    else
        warn "SQL dump date not synchronized"
    fi
fi

# ═══════════════ TEST 8: FAILLE 7 — robots.txt ═══════════════
header "TEST 8: Faille 7 — robots.txt"

ROBOTS_FILE="$SITE_DIR/robots.txt"
if [ -f "$ROBOTS_FILE" ]; then
    if grep -q "Disallow: /admin/" "$ROBOTS_FILE"; then
        pass "robots.txt disallows /admin/"
    else
        fail "robots.txt missing /admin/ disallow"
    fi
    if grep -q "Disallow: /backup/" "$ROBOTS_FILE"; then
        pass "robots.txt disallows /backup/"
    else
        fail "robots.txt missing /backup/"
    fi
    if grep -q "Disallow: /.env" "$ROBOTS_FILE"; then
        pass "robots.txt disallows .env"
    else
        warn "robots.txt missing .env disallow"
    fi
fi

# ═══════════════ TEST 9: FAILLE 8 — Headers (Worker) ═══════════════
header "TEST 9: Faille 8 — HTTP Headers (Worker)"

MW_FILE="$SITE_DIR/functions/_middleware.js"
if [ -f "$MW_FILE" ]; then
    if grep -q "nginx" "$MW_FILE"; then
        pass "Middleware sets nginx Server header"
    else
        fail "Middleware missing Server header"
    fi
    if grep -q "X-Powered-By" "$MW_FILE"; then
        pass "Middleware sets X-Powered-By header"
    else
        fail "Middleware missing X-Powered-By"
    fi
    if grep -q "X-Debug-Mode" "$MW_FILE"; then
        pass "Middleware sets X-Debug-Mode header"
    else
        warn "Middleware missing X-Debug-Mode"
    fi
    if grep -q "srv-prod-01" "$MW_FILE"; then
        pass "Middleware reveals server hostname"
    else
        warn "Middleware missing hostname"
    fi
fi

# ═══════════════ TEST 10: CREDENTIAL CONSISTENCY ═══════════════
header "TEST 10: Credential Consistency"

# Check principal password appears in all expected files
PRINCIPAL_LOCATIONS=(".env" ".git/config" "backup/site_backup.sql.bak")
for f in "${PRINCIPAL_LOCATIONS[@]}"; do
    filepath="$SITE_DIR/$f"
    if [ -f "$filepath" ]; then
        if grep -q "$CRED_PRINCIPAL_PASS" "$filepath"; then
            pass "Principal password found in $f"
        else
            fail "Principal password MISSING from $f"
        fi
    fi
done

# Check admin creds only in admin panel
if grep -rq "$CRED_ADMIN_PASS" "$SITE_DIR/admin/"; then
    pass "Admin password found in /admin/"
else
    fail "Admin password missing from /admin/"
fi

# Check deploy creds only in JWT
if grep -q "$CRED_DEPLOY_PASS" "$SITE_DIR/admin/messages.html" 2>/dev/null || \
   grep -q "D3pl0y" "$SITE_DIR/admin/messages.html" 2>/dev/null; then
    pass "Deploy password encoded in JWT cookie"
else
    warn "Deploy password not found in messages.html (may be base64 encoded — manual check)"
fi

# ═══════════════ TEST 11: ANTI-FORENSICS ═══════════════
header "TEST 11: Anti-Forensics — Forbidden Words"

FORBIDDEN_WORDS=(
    "honeypot" "honey.pot" "lure" "bait" "trap" "decoy"
    "deception" "canary" "tripwire" "planted" "intentional"
    "deliberately" "pdx" "kill.chain"
)

# Only scan source files (not this test script itself, not the blueprint)
SCAN_DIRS=("$SITE_DIR/index.html" "$SITE_DIR/admin" "$SITE_DIR/assets/css" "$SITE_DIR/assets/js" "$SITE_DIR/assets/data" "$SITE_DIR/backup" "$SITE_DIR/robots.txt")
FORENSICS_CLEAN=true

for word in "${FORBIDDEN_WORDS[@]}"; do
    FOUND=""
    for scan_target in "${SCAN_DIRS[@]}"; do
        if [ -e "$scan_target" ]; then
            RESULT=$(grep -rnil "$word" "$scan_target" 2>/dev/null || true)
            if [ -n "$RESULT" ]; then
                FOUND="$RESULT"
            fi
        fi
    done
    if [ -n "$FOUND" ]; then
        fail "FORBIDDEN WORD '$word' found in: $FOUND"
        FORENSICS_CLEAN=false
    fi
done

if [ "$FORENSICS_CLEAN" = true ]; then
    pass "No forbidden words found in source files"
fi

# Check for suspicious variable names
SUSPICIOUS_VARS=("baitCreds" "trapData" "lureContent" "honeypotData" "attackerLog" "fakeVuln")
for var in "${SUSPICIOUS_VARS[@]}"; do
    FOUND=$(grep -rnl "$var" "$SITE_DIR/assets/" "$SITE_DIR/admin/" "$SITE_DIR/index.html" 2>/dev/null || true)
    if [ -n "$FOUND" ]; then
        fail "Suspicious variable '$var' found in: $FOUND"
    fi
done
pass "No suspicious variable names found"

# ═══════════════ TEST 12: XSS VULNERABILITY CHECK ═══════════════
header "TEST 12: XSS Vulnerability Path"

MAIN_JS="$SITE_DIR/assets/js/main.js"
if [ -f "$MAIN_JS" ]; then
    if grep -q "localStorage" "$MAIN_JS"; then
        pass "Contact form stores in localStorage"
    else
        fail "Contact form doesn't use localStorage"
    fi
fi

if [ -f "$MSG_FILE" ]; then
    if grep -q "localStorage.getItem" "$MSG_FILE"; then
        pass "Messages page reads from localStorage"
    else
        fail "Messages page doesn't read localStorage"
    fi
fi

# ═══════════════ TEST 13: WIDGET ═══════════════
header "TEST 13: Widget Network Activity"

WIDGET_JS="$SITE_DIR/assets/js/net-activity.js"
if [ -f "$WIDGET_JS" ]; then
    # Check no forbidden words in widget
    if grep -qi "honeypot\|hydra\|ssh\|attacker\|mitre" "$WIDGET_JS"; then
        fail "Widget contains forbidden/suspicious words"
    else
        pass "Widget clean of forbidden words"
    fi
    if grep -q "net-widget\|nw-bars\|nw-count" "$WIDGET_JS"; then
        pass "Widget has proper CSS class names"
    else
        warn "Widget CSS classes look unusual"
    fi
fi

WIDGET_DATA="$SITE_DIR/assets/data/widget-data.json"
if [ -f "$WIDGET_DATA" ]; then
    if python3 -c "import json; json.load(open('$WIDGET_DATA'))" 2>/dev/null; then
        pass "widget-data.json is valid JSON"
    else
        fail "widget-data.json is invalid JSON"
    fi
fi

# ═══════════════ TEST 14: DATE CONSISTENCY ═══════════════
header "TEST 14: Date Synchronization"

EXPECTED_DATE="2026-03-28"
FILES_TO_CHECK=(".env" "backup/site_backup.sql.bak")
for f in "${FILES_TO_CHECK[@]}"; do
    filepath="$SITE_DIR/$f"
    if [ -f "$filepath" ] && grep -q "$EXPECTED_DATE" "$filepath"; then
        pass "$f contains synchronized date ($EXPECTED_DATE)"
    elif [ -f "$filepath" ]; then
        warn "$f may have inconsistent date"
    fi
done

# Check admin panel for matching date
if grep -q "Mar 28\|2026-03-28\|03-28" "$SITE_DIR/admin/index.html" 2>/dev/null; then
    pass "Admin panel dates match deployment window"
else
    warn "Admin panel dates may not be synchronized"
fi

# ═══════════════ TEST 15: SITE LOADS (HTML VALID) ═══════════════
header "TEST 15: HTML Integrity"

INDEX="$SITE_DIR/index.html"
if [ -f "$INDEX" ]; then
    if grep -q "<!DOCTYPE html>" "$INDEX" && grep -q "</html>" "$INDEX"; then
        pass "index.html has valid HTML structure"
    else
        fail "index.html malformed"
    fi
    if grep -q "Massimo Massetti" "$INDEX"; then
        pass "index.html contains the persona name"
    else
        fail "index.html missing persona name"
    fi
    if grep -q "net-activity-mount" "$INDEX"; then
        pass "index.html has widget mount point"
    else
        fail "index.html missing widget mount"
    fi
    if grep -q "contact-form" "$INDEX"; then
        pass "index.html has contact form (XSS vector)"
    else
        fail "index.html missing contact form"
    fi
fi

# ═══════════════ REMOTE TESTS (if SITE_URL is set) ═══════════════
if [ -n "$SITE_URL" ]; then
    header "TEST 16: Remote HTTP Tests (${SITE_URL})"

    # Test each faille endpoint returns 200
    ENDPOINTS=("/.env" "/robots.txt" "/admin/" "/admin/messages.html" "/backup/site_backup.sql.bak" "/.git/config" "/.git/HEAD")
    for ep in "${ENDPOINTS[@]}"; do
        STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${SITE_URL}${ep}" 2>/dev/null || echo "000")
        if [ "$STATUS" = "200" ]; then
            pass "${ep} → HTTP $STATUS"
        else
            fail "${ep} → HTTP $STATUS (expected 200)"
        fi
    done

    # Test directory traversal
    TRAVERSAL_URL="${SITE_URL}/api/file?name=../../../etc/passwd"
    TRAVERSAL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TRAVERSAL_URL" 2>/dev/null || echo "000")
    if [ "$TRAVERSAL_STATUS" = "200" ]; then
        TRAVERSAL_BODY=$(curl -s "$TRAVERSAL_URL" 2>/dev/null)
        if echo "$TRAVERSAL_BODY" | grep -q "root:x:0:0"; then
            pass "Directory traversal returns fake /etc/passwd"
        else
            fail "Directory traversal returns 200 but wrong content"
        fi
    else
        fail "Directory traversal → HTTP $TRAVERSAL_STATUS (expected 200)"
    fi

    # Test headers
    HEADERS=$(curl -sI "${SITE_URL}/" 2>/dev/null)
    if echo "$HEADERS" | grep -qi "X-Server-Node"; then
        pass "Custom headers present (X-Server-Node)"
    else
        warn "Custom headers not detected (Workers may not be active)"
    fi
fi

# ═══════════════ SUMMARY ═══════════════
echo ""
echo -e "${BOLD}═══════════════════════════════════════${NC}"
echo -e "${BOLD}  RESULTS${NC}"
echo -e "${BOLD}═══════════════════════════════════════${NC}"
echo -e "  ${GREEN}Passed:${NC}  $PASS_COUNT"
echo -e "  ${RED}Failed:${NC}  $FAIL_COUNT"
echo -e "  ${YELLOW}Warnings:${NC} $WARN_COUNT"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}ALL CRITICAL TESTS PASSED${NC}"
    echo -e "  ${DIM}Warnings are non-blocking but should be reviewed.${NC}"
else
    echo -e "  ${RED}${BOLD}$FAIL_COUNT CRITICAL FAILURE(S) — FIX BEFORE DEPLOY${NC}"
fi
echo ""
