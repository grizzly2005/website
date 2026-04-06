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

    form.addEventListener('submit', (e) => {
        e.preventDefault();

        const name = document.getElementById('name').value;
        const email = document.getElementById('email').value;
        const message = document.getElementById('message').value;

        if (!name || !email || !message) return;

        // Save message
        const messages = JSON.parse(localStorage.getItem('contactMessages') || '[]');
        messages.push({
            name: name,
            email: email,
            message: message,
            timestamp: new Date().toISOString(),
            read: false
        });
        localStorage.setItem('contactMessages', JSON.stringify(messages));

        // Show confirmation
        const status = document.getElementById('form-status');
        if (status) {
            status.textContent = '> Message sent successfully';
            status.style.color = '#00ff88';
        }

        form.reset();

        // Clear status after 4s
        setTimeout(() => {
            if (status) status.textContent = '';
        }, 4000);
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