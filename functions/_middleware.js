/**
 * Cloudflare Pages Middleware
 * Adds server headers to all responses
 *
 * Place in /functions/_middleware.js
 * Automatically runs on every request through Cloudflare Pages Functions
 */

const FAKE_GIT_CONFIG = `[core]
\trepositoryformatversion = 0
\tfilemode = true
\tbare = false
\tlogallrefcount = true
\tignorecase = true
\tprecomposeunicode = true
[remote "origin"]
\turl = https://massimomassetti:Gr1zzly!Pr0d_2026@github.com/grizzly2005/portfolio-prod.git
\tfetch = +refs/heads/*:refs/remotes/origin/*
[branch "main"]
\tremote = origin
\tmerge = refs/heads/main
[user]
\tname = Massimo Massetti
\temail = massimo.massetti.dev@gmail.com`;

const FAKE_GIT_HEAD = `ref: refs/heads/main\n`;

export async function onRequest(context) {
    const url = new URL(context.request.url);

    // Serve fake .git files (faille 4)
    if (url.pathname === '/.git/config') {
        return new Response(FAKE_GIT_CONFIG, {
            headers: { 'Content-Type': 'text/plain' }
        });
    }
    if (url.pathname === '/.git/HEAD') {
        return new Response(FAKE_GIT_HEAD, {
            headers: { 'Content-Type': 'text/plain' }
        });
    }

    const response = await context.next();

    // Clone response to add custom headers
    const newResponse = new Response(response.body, response);

    // Server identification headers (faille 8)
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