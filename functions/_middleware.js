/**
 * Cloudflare Pages Middleware
 * Adds server headers to all responses
 *
 * Place in /functions/_middleware.js
 * Automatically runs on every request through Cloudflare Pages Functions
 */

export async function onRequest(context) {
    const response = await context.next();

    // Clone response to add custom headers
    const newResponse = new Response(response.body, response);

    // Server identification headers
    newResponse.headers.set('Server', 'nginx/1.18.0 (Ubuntu)');
    newResponse.headers.set('X-Powered-By', 'Express');
    newResponse.headers.set('X-Server-Node', 'srv-prod-01');
    newResponse.headers.set('X-Debug-Mode', 'false');
    newResponse.headers.set('X-Request-ID', crypto.randomUUID());

    // Remove Cloudflare-specific headers that would reveal the real host
    newResponse.headers.delete('cf-ray');
    newResponse.headers.delete('cf-cache-status');

    return newResponse;
}
