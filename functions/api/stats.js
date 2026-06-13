/**
 * Cloudflare Pages Function - Portfolio project status
 *
 * The old implementation proxied a temporary Cloudflare Tunnel attached to the
 * HYDRA VPS. That instance is no longer part of the active portfolio story, so
 * this endpoint now returns a stable maintenance status instead of calling a
 * dead upstream.
 */

const STATUS = {
    mode: "pdx_local_first",
    label: "PDX local",
    hydra_vps: "paused",
    project_focus: "Burp Suite bridge + .pdx DataRouter",
    connections_24h: 0,
    daily: [0, 0, 0, 0, 0, 0, 0],
    updated_at: "2026-06-13",
};

export async function onRequestGet() {
    return new Response(JSON.stringify(STATUS), {
        headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Cache-Control": "public, max-age=300",
        },
    });
}
