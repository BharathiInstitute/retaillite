/* ============================================
   TULASI STORES Website — Main JavaScript
   ============================================ */

document.addEventListener('DOMContentLoaded', () => {
  initNavbar();
  initScrollAnimations();
  initFAQ();
  initGalleryTabs();
  initLightbox();
  initScrollTop();
  initMobileNav();
  initSmoothScroll();
  initDevAppLinks();
});

/* --- Navbar scroll effect --- */
function initNavbar() {
  const navbar = document.querySelector('.navbar');
  if (!navbar) return;

  window.addEventListener('scroll', () => {
    if (window.scrollY > 50) {
      navbar.classList.add('scrolled');
      navbar.style.boxShadow = '0 1px 3px rgba(0,0,0,0.1)';
    } else {
      navbar.classList.remove('scrolled');
      navbar.style.boxShadow = 'none';
    }
  });
}

/* --- Mobile Navigation --- */
function initMobileNav() {
  const toggle = document.querySelector('.navbar-toggle');
  const mobileNav = document.querySelector('.navbar-mobile');
  if (!toggle || !mobileNav) return;

  function closeMobileMenu() {
    mobileNav.classList.remove('active');
    toggle.classList.remove('active');
    document.body.style.overflow = '';
  }

  toggle.addEventListener('click', () => {
    const isOpen = mobileNav.classList.toggle('active');
    toggle.classList.toggle('active');
    // Lock body scroll when menu is open
    document.body.style.overflow = isOpen ? 'hidden' : '';
  });

  // Close on link click
  mobileNav.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', closeMobileMenu);
  });

  // Close on clicking outside
  document.addEventListener('click', (e) => {
    if (mobileNav.classList.contains('active') &&
        !mobileNav.contains(e.target) &&
        !toggle.contains(e.target)) {
      closeMobileMenu();
    }
  });

  // Close on Escape key
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && mobileNav.classList.contains('active')) {
      closeMobileMenu();
    }
  });
}

/* --- Scroll Animations (Intersection Observer) --- */
function initScrollAnimations() {
  const elements = document.querySelectorAll('.animate-on-scroll');
  if (!elements.length) return;

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.1, rootMargin: '0px 0px -50px 0px' });

  elements.forEach(el => observer.observe(el));
}

/* --- FAQ Accordion --- */
function initFAQ() {
  const faqItems = document.querySelectorAll('.faq-item');
  faqItems.forEach(item => {
    const question = item.querySelector('.faq-question');
    if (!question) return;
    question.addEventListener('click', () => {
      const isOpen = item.classList.contains('active');
      // Close all
      faqItems.forEach(i => i.classList.remove('active'));
      // Toggle current
      if (!isOpen) item.classList.add('active');
    });
  });
}

/* --- Gallery Filter Tabs --- */
function initGalleryTabs() {
  const tabs = document.querySelectorAll('.gallery-tab');
  const items = document.querySelectorAll('.gallery-item');
  if (!tabs.length || !items.length) return;

  tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      tabs.forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      const filter = tab.dataset.filter;

      items.forEach(item => {
        if (filter === 'all' || item.dataset.category === filter) {
          item.style.display = '';
        } else {
          item.style.display = 'none';
        }
      });
    });
  });
}

/* --- Lightbox --- */
function initLightbox() {
  const lightbox = document.querySelector('.lightbox');
  if (!lightbox) return;
  const lightboxImg = lightbox.querySelector('img');
  const closeBtn = lightbox.querySelector('.lightbox-close');

  document.querySelectorAll('.gallery-item img').forEach(img => {
    img.addEventListener('click', () => {
      lightboxImg.src = img.src;
      lightbox.classList.add('active');
      document.body.style.overflow = 'hidden';
    });
  });

  const closeLightbox = () => {
    lightbox.classList.remove('active');
    document.body.style.overflow = '';
  };

  if (closeBtn) closeBtn.addEventListener('click', closeLightbox);
  lightbox.addEventListener('click', (e) => {
    if (e.target === lightbox) closeLightbox();
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeLightbox();
  });
}

/* --- Scroll to Top --- */
function initScrollTop() {
  const btn = document.querySelector('.scroll-top');
  if (!btn) return;

  window.addEventListener('scroll', () => {
    btn.classList.toggle('visible', window.scrollY > 500);
  });

  btn.addEventListener('click', () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });
}

/* --- Smooth Scroll for anchor links --- */
function initSmoothScroll() {
  document.querySelectorAll('a[href^="#"]').forEach(a => {
    a.addEventListener('click', (e) => {
      const target = document.querySelector(a.getAttribute('href'));
      if (target) {
        e.preventDefault();
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    });
  });
}

/* --- Language Switcher (placeholder) --- */
function switchLanguage(lang) {
  console.log('Language switched to:', lang);
  // Future: Load translated content
}

/* --- Dev mode: rewrite /app/ links to Flutter dev server --- */
function initDevAppLinks() {
  // In production: /app/ is on the same domain via Firebase hosting — always works.
  // In local dev: Flutter may run on a separate port. This handles that gracefully.
  const isLocal = location.hostname === 'localhost' || location.hostname === '127.0.0.1';
  if (!isLocal) return;

  // If we're already being served from dist/ (preview.ps1), /app/ exists — no rewrite needed.
  // Quick check: try to fetch /app/index.html on the SAME origin.
  fetch('/app/index.html', { method: 'HEAD', mode: 'no-cors' })
    .then(res => {
      if (res.ok || res.type === 'opaque') {
        // /app/ exists on this server (preview mode) — leave links as-is
        console.log('[Tulasi Stores] /app/ found on same origin — production-like mode');
        return;
      }
      rewriteAppLinks();
    })
    .catch(() => {
      // /app/ doesn't exist locally — rewrite to Flutter dev server
      rewriteAppLinks();
    });
}

function rewriteAppLinks() {
  // Layer 2: Try known Flutter dev ports in order
  const candidates = [
    'http://localhost:5050',
    'http://localhost:5000',
    'http://localhost:8080',  // unlikely but covers edge cases
  ].filter(url => url !== location.origin); // skip our own origin

  // Layer 3: Check which port is actually alive before rewriting
  findAliveServer(candidates).then(aliveUrl => {
    if (aliveUrl) {
      console.log('[Tulasi Stores] Flutter dev server found at', aliveUrl);
      document.querySelectorAll('a[href="https://stores.tulasierp.com/app/"], a[href="/app/"], a[href="/app"]').forEach(link => {
        link.href = aliveUrl;
      });
    } else {
      console.warn('[Tulasi Stores] No Flutter dev server found. "Open App" will show a helpful message.');
      document.querySelectorAll('a[href="https://stores.tulasierp.com/app/"], a[href="/app/"], a[href="/app"]').forEach(link => {
        link.addEventListener('click', (e) => {
          e.preventDefault();
          alert(
            'Flutter app is not running.\\n\\n' +
            'Option 1 (recommended):\\n' +
            '  Run: .\\preview.ps1\\n' +
            '  Then open http://localhost:9000\\n\\n' +
            'Option 2 (dev mode):\\n' +
            '  Run: flutter run -d chrome\\n' +
            '  Then click "Open App" again.'
          );
        });
      });
    }
  });
}

function findAliveServer(urls) {
  // Race fetches — return the first one that responds
  if (!urls.length) return Promise.resolve(null);
  return new Promise(resolve => {
    let resolved = false;
    let pending = urls.length;
    urls.forEach(url => {
      fetch(url, { method: 'HEAD', mode: 'no-cors' })
        .then(() => {
          if (!resolved) { resolved = true; resolve(url); }
        })
        .catch(() => {
          pending--;
          if (pending === 0 && !resolved) { resolved = true; resolve(null); }
        });
    });
    // Timeout after 2 seconds
    setTimeout(() => { if (!resolved) { resolved = true; resolve(null); } }, 2000);
  });
}
