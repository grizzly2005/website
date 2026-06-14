/**
 * Cloudflare Pages Middleware
 * Adds server headers to all responses
 *
 * Place in /functions/_middleware.js
 * Automatically runs on every request through Cloudflare Pages Functions
 */

export async function onRequest(context) {
    const url = new URL(context.request.url);

    // Keep legacy static bait paths closed. The current deception story uses
    // controlled API-level decoys only, not public admin, backup, or secret
    // looking files that could be mistaken for real operational exposure.
    if (
        url.pathname === '/.git' ||
        url.pathname.startsWith('/.git/') ||
        url.pathname === '/.wrangler' ||
        url.pathname.startsWith('/.wrangler/') ||
        url.pathname === '/admin' ||
        url.pathname.startsWith('/admin/') ||
        url.pathname === '/backup' ||
        url.pathname.startsWith('/backup/') ||
        url.pathname.endsWith('.bak-theme') ||
        url.pathname === '/.env'
    ) {
        return new Response('Not found', {
            status: 404,
            headers: { 'Content-Type': 'text/plain; charset=utf-8' }
        });
    }

    const response = await context.next();

    // Clone response to add custom headers
    const newResponse = new Response(response.body, response);

    // Keep headers boring and production-like.
    newResponse.headers.set('X-Content-Type-Options', 'nosniff');
    newResponse.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
    newResponse.headers.set('X-Frame-Options', 'SAMEORIGIN');
    newResponse.headers.set('X-Request-ID', crypto.randomUUID());

    // Remove Cloudflare-specific headers that would reveal the real host
    newResponse.headers.delete('cf-ray');
    newResponse.headers.delete('cf-cache-status');

    return newResponse;
}
