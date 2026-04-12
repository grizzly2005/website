/**
 * Portfolio — Main Script
 * Generated with Cursor AI assistance
 */

document.addEventListener('DOMContentLoaded', () => {
    initNav();
    initScrollReveal();
    initContactForm();
});

// ═══════════════ NAV SCROLL EFFECT ═══════════════
function initNav() {
    const nav = document.getElementById('nav');
    if (!nav) return;

    let lastScroll = 0;
    window.addEventListener('scroll', () => {
        const current = window.scrollY;
        if (current > 50) {
            nav.classList.add('scrolled');
        } else {
            nav.classList.remove('scrolled');
        }
        lastScroll = current;
    }, { passive: true });
}

// ═══════════════ SCROLL REVEAL ═══════════════
function initScrollReveal() {
    const elements = document.querySelectorAll('[data-reveal]');
    if (!elements.length) return;

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('revealed');
                observer.unobserve(entry.target);
            }
        });
    }, {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    });

    elements.forEach(el => observer.observe(el));
}

// ═══════════════ CONTACT FORM ═══════════════

function initContactForm() {
    const form = document.getElementById('contact-form');
    if (!form) return;

    form.addEventListener('submit', async (e) => {
        e.preventDefault();

        const name = document.getElementById('name').value.trim();
        const email = document.getElementById('email').value.trim();
        const message = document.getElementById('message').value.trim();
        const status = document.getElementById('form-status');
        const btn = form.querySelector('button[type="submit"]');

        if (!name || !email || !message) return;

        btn.disabled = true;
        btn.textContent = 'Sending...';
        if (status) { status.textContent = ''; status.style.color = ''; }

        try {
            const res = await fetch('https://api.web3forms.com/submit', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    access_key: '66fe09bd-6a0d-4b36-b594-25007de5e01f',
                    subject: '[Portfolio] Message from ' + name,
                    from_name: name,
                    replyto: email,
                    message: message,
                }),
            });

            const text = await res.text();
            let data;
            try { data = JSON.parse(text); } catch (p) {
                throw new Error('Server error (' + res.status + ')');
            }

            if (data.success) {
                if (status) {
                    status.textContent = '> Message sent successfully';
                    status.style.color = '#00ff88';
                }
                form.reset();
            } else {
                throw new Error(data.message || 'Send failed');
            }
        } catch (err) {
            if (status) {
                status.textContent = '> Error: ' + err.message;
                status.style.color = '#ff3b5c';
            }
        } finally {
            btn.disabled = false;
            btn.textContent = 'Send Message';
            setTimeout(function() { if (status) status.textContent = ''; }, 5000);
        }
    });
}
        } catch (err) {
            if (status) {
                status.textContent = '> Error: ' + err.message;
                status.style.color = '#ff3b5c';
            }
        } finally {
            btn.disabled = false;
            btn.textContent = 'Send Message';
            setTimeout(() => {
                if (status) status.textContent = '';
            }, 5000);
        }
    });
}

// ═══════════════ SMOOTH SCROLL ═══════════════
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            e.preventDefault();
            target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    });
});