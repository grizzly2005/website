/**
 * Cloudflare Pages Function — Contact Form Handler
 * Route: POST /api/contact
 *
 * Uses Web3Forms (free) to forward messages to your email.
 *
 * SETUP:
 *   1. Go to https://web3forms.com — enter massimo.adresse@gmail.com
 *   2. You'll receive an access_key by email
 *   3. In Cloudflare Pages dashboard → Settings → Environment variables
 *      → Add: WEB3FORMS_KEY = your_access_key
 *   4. Redeploy
 */

export async function onRequestPost(context) {
    const headers = {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
    };

    // ── Get API key from env ──
    const apiKey = context.env.WEB3FORMS_KEY;
    if (!apiKey) {
        return new Response(JSON.stringify({
            ok: false,
            error: "Contact form not configured. Set WEB3FORMS_KEY in Cloudflare env.",
        }), { status: 503, headers });
    }

    // ── Parse body ──
    let body;
    try {
        body = await context.request.json();
    } catch {
        return new Response(JSON.stringify({
            ok: false,
            error: "Invalid request body",
        }), { status: 400, headers });
    }

    const { name, email, message } = body;
    if (!name || !email || !message) {
        return new Response(JSON.stringify({
            ok: false,
            error: "Missing fields (name, email, message required)",
        }), { status: 422, headers });
    }

    // ── Basic rate-limit via CF headers ──
    const ip = context.request.headers.get("CF-Connecting-IP") || "unknown";

    // ── Send via Web3Forms ──
    try {
        const res = await fetch("https://api.web3forms.com/submit", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                access_key: apiKey,
                subject: `[Portfolio] Message from ${name}`,
                from_name: name,
                replyto: email,
                message: message,
                // Metadata
                ip: ip,
                source: "portfolio-contact-form",
            }),
        });

        const result = await res.json();

        if (result.success) {
            return new Response(JSON.stringify({ ok: true }), {
                status: 200,
                headers,
            });
        } else {
            return new Response(JSON.stringify({
                ok: false,
                error: result.message || "Web3Forms error",
            }), { status: 502, headers });
        }
    } catch (err) {
        return new Response(JSON.stringify({
            ok: false,
            error: "Failed to send: " + err.message,
        }), { status: 500, headers });
    }
}

// Handle CORS preflight
export async function onRequestOptions() {
    return new Response(null, {
        headers: {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
        },
    });
}