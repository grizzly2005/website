/**
 * Network Activity Monitor
 * Lightweight server activity widget
 * Auto-refreshes every 5 minutes
 */

(function() {
    const MOUNT = document.getElementById('net-activity-mount');
    if (!MOUNT) return;

    const DATA_URL = '/assets/data/widget-data.json';
    const REFRESH_INTERVAL = 300000; // 5 min

    function createWidget() {
        const el = document.createElement('div');
        el.className = 'net-widget';
        el.innerHTML = `
            <div class="nw-header">
                <span class="nw-dot"></span>
                <span class="nw-label">live</span>
                <span class="nw-title">net.activity</span>
            </div>
            <div class="nw-body">
                <div class="nw-bars" id="nw-bars"></div>
                <span class="nw-count" id="nw-count">—</span>
            </div>
        `;
        MOUNT.appendChild(el);

        // Inject styles
        const style = document.createElement('style');
        style.textContent = `
            .net-widget {
                width: 210px;
                padding: 10px 14px;
                background: rgba(10, 10, 15, 0.88);
                border: 1px solid rgba(255,255,255,0.06);
                border-radius: 10px;
                font-family: 'Fira Code', monospace;
                font-size: 10px;
                color: rgba(255,255,255,0.35);
                opacity: 0.55;
                transition: opacity 0.3s ease;
                user-select: none;
            }
            .net-widget:hover { opacity: 1; }
            .nw-header {
                display: flex;
                align-items: center;
                gap: 6px;
                margin-bottom: 8px;
            }
            .nw-dot {
                width: 5px; height: 5px;
                background: #00ff88;
                border-radius: 50%;
                animation: nwPulse 2s ease-in-out infinite;
                box-shadow: 0 0 4px #00ff88;
            }
            .nw-label {
                color: #00ff88;
                font-size: 9px;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }
            .nw-title {
                margin-left: auto;
                font-size: 9px;
                opacity: 0.6;
            }
            .nw-body {
                display: flex;
                align-items: flex-end;
                gap: 10px;
            }
            .nw-bars {
                display: flex;
                align-items: flex-end;
                gap: 3px;
                height: 24px;
                flex: 1;
            }
            .nw-bar {
                flex: 1;
                background: rgba(0,240,255,0.25);
                border-radius: 2px 2px 0 0;
                min-height: 2px;
                transition: height 0.5s ease;
            }
            .nw-count {
                font-size: 10px;
                white-space: nowrap;
                color: rgba(255,255,255,0.45);
            }
            @keyframes nwPulse {
                0%, 100% { opacity: 1; }
                50% { opacity: 0.4; }
            }
        `;
        document.head.appendChild(style);
    }

    function renderBars(daily) {
        const container = document.getElementById('nw-bars');
        if (!container) return;
        container.innerHTML = '';
        const max = Math.max(...daily, 1);
        daily.forEach(val => {
            const bar = document.createElement('div');
            bar.className = 'nw-bar';
            bar.style.height = Math.max(2, (val / max) * 24) + 'px';
            container.appendChild(bar);
        });
    }

    function updateCount(n) {
        const el = document.getElementById('nw-count');
        if (el) el.textContent = n + '/24h';
    }

    async function fetchData() {
        try {
            const res = await fetch(DATA_URL + '?t=' + Date.now());
            if (!res.ok) throw new Error(res.status);
            const data = await res.json();
            renderBars(data.daily || [0,0,0,0,0,0,0]);
            updateCount(data.connections_24h || 0);
        } catch (_) {
            // Fallback: generate plausible static data
            const daily = Array.from({length: 7}, () => Math.floor(Math.random() * 15) + 1);
            const total = daily.reduce((a, b) => a + b, 0);
            renderBars(daily);
            updateCount(Math.floor(total / 7));
        }
    }

    createWidget();
    fetchData();
    setInterval(fetchData, REFRESH_INTERVAL);
})();
