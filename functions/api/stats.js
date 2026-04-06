/**
 * Cloudflare Pages Function — Widget Stats Proxy
 * Proxies real HYDRA stats through Cloudflare Tunnel.
 *
 * Route: GET /api/stats
 *
 * IMPORTANT: Remplace TUNNEL_URL par l'URL permanente du tunnel.
 * Pour obtenir l'URL : sur la console GCP SSH, lance:
 *   sudo journalctl -u cloudflared | grep "trycloudflare.com" | tail -1
 */

const TUNNEL_URL = "https://golden-gentle-agricultural-wellington.trycloudflare.com";

export async function onRequestGet(context) {
    // Si le tunnel n'est pas configuré, retourner une erreur claire
    if (TUNNEL_URL === "__TUNNEL_URL__") {
        return new Response(JSON.stringify({
            error: "tunnel_not_configured",
            hint: "Replace __TUNNEL_URL__ in functions/api/stats.js"
        }), {
            status: 503,
            headers: { "Content-Type": "application/json" },
        });
    }

    const target = TUNNEL_URL.replace(/\/$/, "") + "/widget-stats";

    try {
        const response = await fetch(target, {
            headers: { "Accept": "application/json" },
        });

        if (!response.ok) {
            throw new Error("upstream_" + response.status);
        }

        const data = await response.json();

        return new Response(JSON.stringify(data), {
            headers: {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Cache-Control": "public, max-age=30",
            },
        });

    } catch (error) {
        // Retourner l'erreur exacte (pas de fallback random)
        return new Response(JSON.stringify({
            error: error.message,
            target: target,
        }), {
            status: 502,
            headers: {
                "Content-Type": "application/json",
                "Cache-Control": "no-cache",
            },
        });
    }
}