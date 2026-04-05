/**
 * Cloudflare Worker — File API endpoint
 * Serves portfolio files (resume, writeups)
 *
 * Deploy: Place in /functions/api/file.js for Cloudflare Pages Functions
 * Route: GET /api/file?name=resume.pdf
 *
 * NOTE: This Worker simulates a vulnerable file server.
 * When the 'name' parameter contains path traversal sequences (../),
 * it serves pre-defined fake system files to simulate a real backend vulnerability.
 *
 * In production on Cloudflare Pages, this file goes in:
 *   /functions/api/file.js
 *
 * For local testing, these responses are mocked in the test scripts.
 */

// Pre-defined fake system files served when traversal is detected
const FAKE_FILES = {
    '/etc/passwd': `root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/usr/sbin/nologin
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
sshd:x:106:65534::/run/sshd:/usr/sbin/nologin
massimo:x:1000:1000:Massimo Massetti,,,:/home/massimo:/bin/bash
admin:x:1001:1001:Admin,,,:/home/admin:/bin/bash
deploy:x:1002:1002:Deploy Bot,,,:/home/deploy:/bin/bash`,

    '/etc/shadow': `root:$6$rONd8KxX$hKWlp4SzOSbVBiCkWmXtitsbpChb.r.U6cKMjL4Q7/X.mpFGdWIM8nGEFh8/l2sH2Pso9l0y9aO1Jlm5u.udL.:19810:0:99999:7:::
daemon:*:19750:0:99999:7:::
bin:*:19750:0:99999:7:::
sys:*:19750:0:99999:7:::
www-data:*:19750:0:99999:7:::
sshd:*:19750:0:99999:7:::
massimo:$6$hT4kL9mN$xK8mN3pQ7rS1tU4vW6xY9zA2bC5dE8fG0hI3jK6nM9oP1qR4sT7uV0wX2yZ5aB8cD:19810:0:99999:7:::
admin:$6$wE3rT6yU$9aB2cD5eF8gH1iJ4kL7mN0oP3qR6sT9uV2wX5yZ8aB1cD4eF7gH0iJ3kL6mN9oP:19810:0:99999:7:::
deploy:$6$qW1eR4tY$2aS5dF8gH1jK4lZ7xC0vB3nM6qW9eR2tY5uI8oP1aS4dF7gH0jK3lZ6xC9vB2nM:19810:0:99999:7:::`,

    '/root/.bash_history': `cd /opt/app
cat .env
systemctl restart nginx
ssh admin@localhost
cat /var/log/auth.log | tail -20
docker ps
apt update && apt upgrade -y
python3 -m src.main
curl http://localhost:9090/health
git pull origin main
nano config/config.yaml`,

    '/etc/hostname': `srv-prod-01`,

    '/etc/os-release': `PRETTY_NAME="Ubuntu 22.04.3 LTS"
NAME="Ubuntu"
VERSION_ID="22.04"
VERSION="22.04.3 LTS (Jammy Jellyfish)"
VERSION_CODENAME=jammy
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=jammy`,
};

// Resolve traversal paths like ../../../etc/passwd → /etc/passwd
function resolveTraversal(name) {
    // Normalize: remove query strings, decode
    let path = decodeURIComponent(name);

    // Check for traversal sequences
    if (!path.includes('..')) return null;

    // Resolve the traversal
    const parts = path.split('/');
    const stack = [];
    for (const part of parts) {
        if (part === '..') {
            stack.pop();
        } else if (part && part !== '.') {
            stack.push(part);
        }
    }
    return '/' + stack.join('/');
}

export async function onRequestGet(context) {
    const url = new URL(context.request.url);
    const name = url.searchParams.get('name');

    if (!name) {
        return new Response(JSON.stringify({ error: 'Missing parameter: name' }), {
            status: 400,
            headers: { 'Content-Type': 'application/json' }
        });
    }

    // Check for path traversal
    const resolved = resolveTraversal(name);
    if (resolved && FAKE_FILES[resolved]) {
        return new Response(FAKE_FILES[resolved], {
            status: 200,
            headers: {
                'Content-Type': 'text/plain',
                'X-Served-By': 'file-api-v1',
            }
        });
    }

    // Legit file request — try to serve from /files/ directory
    try {
        const asset = await context.env.ASSETS.fetch(
            new URL(`/files/${name}`, url.origin)
        );
        if (asset.ok) return asset;
    } catch (_) {}

    return new Response('File not found', {
        status: 404,
        headers: { 'Content-Type': 'text/plain' }
    });
}
