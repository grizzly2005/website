#!/bin/bash
# ═══════════════════════════════════════════════════════════
# apply-theme-toggle.sh — Add dark/light mode toggle to portfolio
#
# Usage (from portfolio-site-final/ root):
#   bash apply-theme-toggle.sh
#
# What it does:
#   1. Adds light theme CSS variables after :root block
#   2. Adds .theme-toggle button styles
#   3. Inserts toggle button into nav
#   4. Adds JS to <head> for early theme application (no FOUC)
# ═══════════════════════════════════════════════════════════

set -e

if [ ! -f "index.html" ] || [ ! -f "assets/css/style.css" ]; then
    echo "✗ Run from portfolio-site-final/ root (index.html + assets/css/style.css required)"
    exit 1
fi

# Backup
cp assets/css/style.css assets/css/style.css.bak-theme
cp index.html index.html.bak-theme
echo "✓ Backups created (.bak-theme)"

# ═══════════════════════════════════════
# 1. Inject light theme CSS variables
# ═══════════════════════════════════════
python3 << 'PYEOF'
from pathlib import Path
p = Path("assets/css/style.css")
c = p.read_text()

if "data-theme=\"light\"" in c:
    print("⚠ CSS already contains light theme, skipping")
else:
    light_block = """
/* ═══ Light theme override ═══ */
[data-theme="light"] {
    --bg-primary: #f8f8fb;
    --bg-secondary: #eeeef4;
    --bg-card: #ffffff;
    --bg-card-hover: #f0f0f6;
    --text-primary: #1a1a2e;
    --text-secondary: #4a4a68;
    --text-dim: #8888a0;
    --accent: #0066cc;
    --accent-glow: rgba(0, 102, 204, 0.12);
    --accent-muted: #0099cc;
    --accent-secondary: #6b46c1;
    --green: #00aa55;
}

/* Smooth color transitions on theme switch */
html, body, .nav, .card, a, button, input, textarea {
    transition: background-color 0.25s ease, color 0.25s ease, border-color 0.25s ease;
}

/* Theme toggle button */
.theme-toggle {
    background: transparent;
    border: 1px solid var(--text-dim);
    color: var(--text-secondary);
    width: 34px;
    height: 34px;
    border-radius: 6px;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: 0;
    margin-left: 8px;
    transition: all 0.2s ease;
}
.theme-toggle:hover {
    border-color: var(--accent);
    color: var(--accent);
    background: var(--accent-glow);
}
.theme-toggle svg {
    width: 16px;
    height: 16px;
}
.theme-toggle .icon-sun { display: none; }
.theme-toggle .icon-moon { display: block; }
[data-theme="light"] .theme-toggle .icon-sun { display: block; }
[data-theme="light"] .theme-toggle .icon-moon { display: none; }

/* In light mode, tone down the scanline & grid overlays which look odd on white */
[data-theme="light"] .scanline { opacity: 0.15; }
[data-theme="light"] .grid-bg { opacity: 0.35; }
"""
    # Inject after the first closing brace of :root block
    lines = c.split("\n")
    # Find end of :root { ... }
    in_root = False
    insert_at = None
    for i, line in enumerate(lines):
        if ":root" in line and "{" in line:
            in_root = True
        if in_root and line.strip() == "}":
            insert_at = i + 1
            break

    if insert_at is None:
        print("✗ Could not find :root block end")
    else:
        lines.insert(insert_at, light_block)
        p.write_text("\n".join(lines))
        print("✓ Light theme CSS injected")
PYEOF

# ═══════════════════════════════════════
# 2. Inject theme-toggle button in nav & script in head
# ═══════════════════════════════════════
python3 << 'PYEOF'
from pathlib import Path
p = Path("index.html")
c = p.read_text()

# 2a. Early theme script (prevents flash of wrong theme on load)
early_script = """    <!-- Theme init (must run before <body> renders to avoid flash) -->
    <script>
      (function() {
        var saved = localStorage.getItem('theme');
        var prefersLight = window.matchMedia('(prefers-color-scheme: light)').matches;
        var theme = saved || (prefersLight ? 'light' : 'dark');
        if (theme === 'light') document.documentElement.setAttribute('data-theme', 'light');
      })();
    </script>
"""

# 2b. Toggle button HTML — goes at end of nav-links, before </div>
toggle_btn = """                <button class="theme-toggle" id="themeToggle" aria-label="Toggle theme" title="Toggle theme">
                    <svg class="icon-moon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>
                    <svg class="icon-sun" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41"/></svg>
                </button>
"""

# 2c. Runtime toggle script — just before </body>
runtime_script = """    <script>
      (function() {
        var btn = document.getElementById('themeToggle');
        if (!btn) return;
        btn.addEventListener('click', function() {
          var current = document.documentElement.getAttribute('data-theme');
          var next = current === 'light' ? 'dark' : 'light';
          if (next === 'light') {
            document.documentElement.setAttribute('data-theme', 'light');
          } else {
            document.documentElement.removeAttribute('data-theme');
          }
          localStorage.setItem('theme', next);
        });
      })();
    </script>
"""

changed = False

# Inject early script before closing </head>
if "Theme init" not in c:
    c = c.replace("</head>", early_script + "</head>", 1)
    changed = True
    print("✓ Early theme script injected in <head>")
else:
    print("⚠ Early theme script already present")

# Inject button at end of nav-links div
# Find the nav-links closing </div> that comes right before </nav>
if 'id="themeToggle"' not in c:
    import re
    # Find the last </a> before </div> inside nav-links, then insert button before </div>
    pattern = r'(<div class="nav-links">.*?)(\s*</div>\s*</div>\s*</nav>)'
    m = re.search(pattern, c, re.DOTALL)
    if m:
        before = m.group(1)
        after = m.group(2)
        c = c.replace(m.group(0), before + "\n" + toggle_btn + after, 1)
        changed = True
        print("✓ Theme toggle button injected in nav")
    else:
        print("✗ nav-links block not found — insert button manually")
else:
    print("⚠ Theme toggle button already present")

# Inject runtime script before </body>
if "themeToggle" in c and "btn.addEventListener" not in c:
    c = c.replace("</body>", runtime_script + "</body>", 1)
    changed = True
    print("✓ Runtime toggle script injected before </body>")
elif "btn.addEventListener" in c:
    print("⚠ Runtime script already present")

if changed:
    Path("index.html").write_text(c)
    print("✓ index.html saved")
PYEOF

echo ""
echo "═══════════════════════════════════════════════"
echo "Done. Open index.html in a browser to test."
echo "The toggle button is in the nav, next to LinkedIn icon."
echo ""
echo "If it breaks, restore with:"
echo "  cp assets/css/style.css.bak-theme assets/css/style.css"
echo "  cp index.html.bak-theme index.html"
echo "═══════════════════════════════════════════════"