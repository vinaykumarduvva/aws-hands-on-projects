/**
 * AWS Handy Book — Interactive Reference Guide
 * Main Application JavaScript
 */

// ===== THEME MANAGEMENT =====
const themeToggle = document.getElementById('themeToggle');
const html = document.documentElement;

function getStoredTheme() {
  return localStorage.getItem('aws-handy-theme') || 'dark';
}

function setTheme(theme) {
  html.setAttribute('data-theme', theme);
  localStorage.setItem('aws-handy-theme', theme);
}

// Initialize theme
setTheme(getStoredTheme());

themeToggle.addEventListener('click', () => {
  const current = html.getAttribute('data-theme');
  setTheme(current === 'dark' ? 'light' : 'dark');
});

// ===== MOBILE NAVIGATION =====
const mobileToggle = document.getElementById('mobileToggle');
const navLinks = document.getElementById('navLinks');

mobileToggle.addEventListener('click', () => {
  navLinks.classList.toggle('mobile-open');
  mobileToggle.textContent = navLinks.classList.contains('mobile-open') ? '✕' : '☰';
});

// Close mobile menu on link click
navLinks.querySelectorAll('a').forEach(link => {
  link.addEventListener('click', () => {
    navLinks.classList.remove('mobile-open');
    mobileToggle.textContent = '☰';
  });
});

// ===== NAVBAR SCROLL BEHAVIOR =====
const navbar = document.getElementById('navbar');
let lastScroll = 0;

window.addEventListener('scroll', () => {
  const currentScroll = window.scrollY;
  if (currentScroll > 50) {
    navbar.classList.add('scrolled');
  } else {
    navbar.classList.remove('scrolled');
  }
  lastScroll = currentScroll;
});

// Active nav link highlighting
const sections = document.querySelectorAll('section[id]');
const navItems = navLinks.querySelectorAll('a');

function highlightNavOnScroll() {
  const scrollY = window.scrollY + 100;
  sections.forEach(section => {
    const top = section.offsetTop;
    const height = section.offsetHeight;
    const id = section.getAttribute('id');
    if (scrollY >= top && scrollY < top + height) {
      navItems.forEach(a => {
        a.classList.remove('active');
        if (a.getAttribute('href') === '#' + id) {
          a.classList.add('active');
        }
      });
    }
  });
}
window.addEventListener('scroll', highlightNavOnScroll);

// ===== BACK TO TOP BUTTON =====
const backToTop = document.getElementById('backToTop');
window.addEventListener('scroll', () => {
  if (window.scrollY > 500) {
    backToTop.classList.add('visible');
  } else {
    backToTop.classList.remove('visible');
  }
});
backToTop.addEventListener('click', () => {
  window.scrollTo({ top: 0, behavior: 'smooth' });
});

// ===== HERO PARTICLES =====
function createParticles() {
  const container = document.getElementById('heroParticles');
  if (!container) return;
  for (let i = 0; i < 20; i++) {
    const particle = document.createElement('div');
    particle.className = 'particle';
    const size = Math.random() * 8 + 3;
    particle.style.width = size + 'px';
    particle.style.height = size + 'px';
    particle.style.left = Math.random() * 100 + '%';
    particle.style.top = Math.random() * 100 + '%';
    particle.style.animationDelay = Math.random() * 10 + 's';
    particle.style.animationDuration = (Math.random() * 10 + 10) + 's';
    if (Math.random() > 0.5) {
      particle.style.background = 'rgba(37, 99, 235, 0.2)';
    }
    container.appendChild(particle);
  }
}
createParticles();

// ===== ANIMATED COUNTERS =====
function animateCounter(el, target, duration = 1500) {
  let start = 0;
  const step = target / (duration / 16);
  const timer = setInterval(() => {
    start += step;
    if (start >= target) {
      el.textContent = target;
      clearInterval(timer);
    } else {
      el.textContent = Math.floor(start);
    }
  }, 16);
}

// Count services and code examples
let totalServices = 0;
let totalCodeExamples = 0;
if (typeof AWS_CATEGORIES !== 'undefined') {
  AWS_CATEGORIES.forEach(cat => {
    totalServices += cat.count;
    cat.services.forEach(s => {
      totalCodeExamples += s.codeBlocks.length;
    });
  });
}

// Start counter animations when hero is in view
const heroObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      animateCounter(document.getElementById('counterServices'), totalServices);
      animateCounter(document.getElementById('counterCategories'), AWS_CATEGORIES.length);
      animateCounter(document.getElementById('counterExamples'), totalCodeExamples);
      heroObserver.disconnect();
    }
  });
}, { threshold: 0.3 });
heroObserver.observe(document.getElementById('hero'));

// ===== SCROLL REVEAL ANIMATIONS =====
const revealObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('visible');
    }
  });
}, { threshold: 0.1, rootMargin: '0px 0px -40px 0px' });

document.querySelectorAll('.reveal, .stagger').forEach(el => {
  revealObserver.observe(el);
});

// ===== CATEGORY NAVIGATION (OVERVIEW SECTION) =====
function renderCategoryNav() {
  const container = document.getElementById('categoryNav');
  if (!container || typeof AWS_CATEGORIES === 'undefined') return;

  AWS_CATEGORIES.forEach((cat, idx) => {
    const pill = document.createElement('button');
    pill.className = 'category-pill';
    pill.innerHTML = `
      <span class="cat-icon">${cat.icon}</span>
      ${cat.name}
      <span class="cat-count">${cat.count}</span>
    `;
    pill.addEventListener('click', () => {
      // Scroll to reference section and filter
      document.getElementById('reference').scrollIntoView({ behavior: 'smooth' });
      setTimeout(() => {
        filterByCategory(cat.name);
      }, 600);
    });
    container.appendChild(pill);
  });
}
renderCategoryNav();

// ===== RENDER SERVICES (REFERENCE BOOK) =====
let currentFilter = 'all';
let currentCategoryFilter = null;
let currentSearch = '';

function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

function renderServiceCard(service) {
  const diffClass = service.difficulty;
  const diffLabel = diffClass.charAt(0).toUpperCase() + diffClass.slice(1);
  const diffEmoji = diffClass === 'beginner' ? '🟢' : diffClass === 'intermediate' ? '🟡' : '🔴';

  let codeBlocksHtml = '';
  service.codeBlocks.forEach(cb => {
    codeBlocksHtml += `
      <div class="code-block">
        <span class="code-label">${escapeHtml(cb.lang)}</span>
        <code>${escapeHtml(cb.code)}</code>
      </div>
    `;
  });

  let archHtml = '';
  if (service.architecture) {
    archHtml = `<div class="architecture-flow">🏗️ <strong>Architecture:</strong> ${escapeHtml(service.architecture)}</div>`;
  }

  let capsList = service.coreCapabilities.map(c => `<li>${escapeHtml(c)}</li>`).join('');
  let scenariosList = service.scenarios.map(s => `<li>${escapeHtml(s)}</li>`).join('');
  let considerationsList = service.considerations.map(c => `<li>${escapeHtml(c)}</li>`).join('');

  let relatedHtml = '';
  if (service.related.length > 0) {
    const tags = service.related.map(r => `<span class="related-tag">${escapeHtml(r)}</span>`).join('');
    relatedHtml = `
      <div class="service-section">
        <div class="service-section-title"><span class="icon">🔗</span> Related Services / Prerequisites</div>
        <div class="related-tags">${tags}</div>
      </div>
    `;
  }

  let nextStepHtml = '';
  if (service.nextStep) {
    nextStepHtml = `
      <div class="service-next-step">
        <strong>🚀 Next Step:</strong> ${escapeHtml(service.nextStep)}
      </div>
    `;
  }

  return `
    <div class="service-card" data-service="${service.number}" data-difficulty="${service.difficulty}">
      <div class="service-card-header" onclick="toggleService(this)">
        <div class="service-number">${service.number}</div>
        <div class="service-title">
          <h3>${escapeHtml(service.title)}</h3>
          <div class="service-subtitle">${escapeHtml(service.rationale)}</div>
        </div>
        <span class="service-badge ${diffClass}">${diffEmoji} ${diffLabel}</span>
        <span class="dropdown-arrow">▼</span>
      </div>
      <div class="service-card-body">
        <div class="service-content">
          <div class="service-definition">
            <span class="def-label">💡 Definition:</span> ${escapeHtml(service.definition)}
          </div>

          ${capsList ? `
          <div class="service-section">
            <div class="service-section-title"><span class="icon">⚙️</span> Core Capabilities & Uses</div>
            <ul>${capsList}</ul>
          </div>` : ''}

          ${scenariosList ? `
          <div class="service-section">
            <div class="service-section-title"><span class="icon">🎯</span> Common Scenarios</div>
            <ul>${scenariosList}</ul>
          </div>` : ''}

          ${(codeBlocksHtml || archHtml) ? `
          <div class="service-section">
            <div class="service-section-title"><span class="icon">💻</span> Quick Examples</div>
            ${codeBlocksHtml}
            ${archHtml}
          </div>` : ''}

          ${considerationsList ? `
          <div class="service-section">
            <div class="service-section-title"><span class="icon">⚠️</span> Key Concepts & Considerations</div>
            <ul>${considerationsList}</ul>
          </div>` : ''}

          ${relatedHtml}
          ${nextStepHtml}
        </div>
      </div>
    </div>
  `;
}

function renderAllServices() {
  const container = document.getElementById('servicesContainer');
  if (!container || typeof AWS_CATEGORIES === 'undefined') return;

  let html = '';
  let visibleCount = 0;

  AWS_CATEGORIES.forEach(cat => {
    // Filter by category if set
    if (currentCategoryFilter && cat.name !== currentCategoryFilter) return;

    let catServices = cat.services;

    // Filter by difficulty
    if (currentFilter !== 'all') {
      catServices = catServices.filter(s => s.difficulty === currentFilter);
    }

    // Filter by search
    if (currentSearch) {
      const q = currentSearch.toLowerCase();
      catServices = catServices.filter(s =>
        s.title.toLowerCase().includes(q) ||
        s.definition.toLowerCase().includes(q) ||
        s.difficulty.toLowerCase().includes(q) ||
        cat.name.toLowerCase().includes(q)
      );
    }

    if (catServices.length === 0) return;

    visibleCount += catServices.length;

    html += `
      <div class="category-group reveal" style="margin-bottom: 32px;">
        <h3 style="font-size: 1.3rem; font-weight: 800; margin-bottom: 16px; display: flex; align-items: center; gap: 10px;">
          <span style="font-size: 1.5rem;">${cat.icon}</span>
          ${escapeHtml(cat.name)}
          <span style="font-size: 0.75rem; background: var(--bg-tertiary); padding: 3px 10px; border-radius: 99px; font-weight: 600; color: var(--text-tertiary);">${catServices.length}</span>
        </h3>
        <div class="services-grid">
          ${catServices.map(s => renderServiceCard(s)).join('')}
        </div>
      </div>
    `;
  });

  if (visibleCount === 0) {
    html = `
      <div class="no-results">
        <div class="emoji">🔍</div>
        <p>No services found matching your search. Try a different keyword.</p>
      </div>
    `;
  }

  container.innerHTML = html;

  // Re-observe new reveal elements
  container.querySelectorAll('.reveal').forEach(el => {
    revealObserver.observe(el);
  });
}

// Toggle service dropdown
function toggleService(headerEl) {
  const card = headerEl.closest('.service-card');
  card.classList.toggle('open');
}

// Filter by difficulty
function filterByDifficulty(level, btnEl) {
  currentFilter = level;
  currentCategoryFilter = null;
  
  // Update active state
  document.querySelectorAll('[data-filter]').forEach(b => b.classList.remove('active'));
  if (btnEl) btnEl.classList.add('active');
  
  renderAllServices();
}

// Filter by category (from overview nav)
function filterByCategory(catName) {
  currentCategoryFilter = catName;
  currentFilter = 'all';
  document.querySelectorAll('[data-filter]').forEach(b => b.classList.remove('active'));
  document.querySelector('[data-filter="all"]').classList.add('active');
  renderAllServices();
}

// Search functionality
const searchInput = document.getElementById('searchInput');
let searchDebounce;
searchInput.addEventListener('input', (e) => {
  clearTimeout(searchDebounce);
  searchDebounce = setTimeout(() => {
    currentSearch = e.target.value.trim();
    currentCategoryFilter = null;
    renderAllServices();
  }, 250);
});

// ===== DIFFICULTY COUNTS =====
function updateDifficultyCounts() {
  if (typeof AWS_CATEGORIES === 'undefined') return;
  let beginnerCount = 0, intermediateCount = 0, advancedCount = 0;
  AWS_CATEGORIES.forEach(cat => {
    cat.services.forEach(s => {
      if (s.difficulty === 'beginner') beginnerCount++;
      else if (s.difficulty === 'intermediate') intermediateCount++;
      else if (s.difficulty === 'advanced') advancedCount++;
    });
  });
  document.getElementById('countBeginner').textContent = beginnerCount;
  document.getElementById('countIntermediate').textContent = intermediateCount;
  document.getElementById('countAdvanced').textContent = advancedCount;
  document.getElementById('countAll').textContent = totalServices;
}

// ===== INITIALIZE =====
document.addEventListener('DOMContentLoaded', () => {
  renderAllServices();
  updateDifficultyCounts();
});

// Make functions globally available
window.toggleService = toggleService;
window.filterByDifficulty = filterByDifficulty;
window.filterByCategory = filterByCategory;
