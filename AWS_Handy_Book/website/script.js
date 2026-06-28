/**
 * AWS Handy Book — Interactive Reference Guide
 * Main Application JavaScript
 */

// ===== SMOOTH SCROLL HELPER =====
// Accounts for fixed navbar height (64px + 16px buffer)
const SCROLL_OFFSET = 80;

function smoothScrollTo(elementId) {
  const el = document.getElementById(elementId);
  if (!el) return;
  const top = el.getBoundingClientRect().top + window.scrollY - SCROLL_OFFSET;
  window.scrollTo({ top, behavior: 'smooth' });
}

// Intercept all anchor links for smooth scroll with offset
document.addEventListener('click', (e) => {
  const link = e.target.closest('a[href^="#"]');
  if (!link) return;
  const href = link.getAttribute('href');
  if (href === '#') {
    e.preventDefault();
    window.scrollTo({ top: 0, behavior: 'smooth' });
    return;
  }
  const targetId = href.slice(1);
  if (targetId) {
    e.preventDefault();
    smoothScrollTo(targetId);
  }
});

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

window.addEventListener('scroll', () => {
  if (window.scrollY > 50) {
    navbar.classList.add('scrolled');
  } else {
    navbar.classList.remove('scrolled');
  }
}, { passive: true });

// Active nav link highlighting
const sections = document.querySelectorAll('section[id]');
const navItems = navLinks.querySelectorAll('a');

function highlightNavOnScroll() {
  const scrollY = window.scrollY + SCROLL_OFFSET + 20;

  // Check if footer is visible (user scrolled near bottom)
  const footer = document.getElementById('footer');
  const footerTop = footer ? footer.offsetTop : Infinity;
  const isAtFooter = scrollY >= footerTop;

  if (isAtFooter) {
    navItems.forEach(a => {
      a.classList.remove('active');
      if (a.getAttribute('href') === '#footer') {
        a.classList.add('active');
      }
    });
    return;
  }

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
window.addEventListener('scroll', highlightNavOnScroll, { passive: true });

// ===== BACK TO TOP BUTTON =====
const backToTop = document.getElementById('backToTop');
window.addEventListener('scroll', () => {
  if (window.scrollY > 500) {
    backToTop.classList.add('visible');
  } else {
    backToTop.classList.remove('visible');
  }
}, { passive: true });
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
    // Mix teal and orange particles for cloud theme
    if (Math.random() > 0.5) {
      particle.style.background = 'rgba(255, 153, 0, 0.2)';
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
}, { threshold: 0.08, rootMargin: '0px 0px -30px 0px' });

document.querySelectorAll('.reveal, .stagger').forEach(el => {
  revealObserver.observe(el);
});

// ===== CATEGORY NAVIGATION (OVERVIEW SECTION) =====
function renderCategoryNav() {
  const container = document.getElementById('categoryNav');
  if (!container || typeof AWS_CATEGORIES === 'undefined') return;

  AWS_CATEGORIES.forEach((cat) => {
    const pill = document.createElement('button');
    pill.type = 'button';
    pill.className = 'category-pill';
    pill.innerHTML = `
      <span class="cat-icon">${cat.icon}</span>
      ${cat.name}
      <span class="cat-count">${cat.count}</span>
    `;
    pill.addEventListener('click', () => {
      // Smooth scroll to reference section with offset
      smoothScrollTo('reference');
      // Wait for scroll to complete, then filter
      setTimeout(() => {
        filterByCategory(cat.name);
      }, 700);
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
      <div class="category-group reveal">
        <h3 class="category-group-header">
          <span class="category-group-icon">${cat.icon}</span>
          ${escapeHtml(cat.name)}
          <span class="category-group-count">${catServices.length}</span>
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

// ===== CLI COMMANDS DASHBOARD LOGIC =====
let currentCmdFilter = 'All';
let cmdSearchQuery = '';
let cmdChart = null;

function initCmdChart() {
  const canvas = document.getElementById('serviceChart');
  if (!canvas || typeof commandsData === 'undefined') return;
  const ctx = canvas.getContext('2d');

  const serviceCounts = {};
  commandsData.forEach(cmd => {
    let s = cmd.service;
    if (s === 'CLI Configuration' || s === 'Environment Customization') s = 'General';
    serviceCounts[s] = (serviceCounts[s] || 0) + 1;
  });

  const labels = Object.keys(serviceCounts);
  const data = Object.values(serviceCounts);

  const colors = [
    '#ff9900', '#06b6d4', '#16a34a', '#8b5cf6', '#ef4444', 
    '#0ea5e9', '#64748b', '#eab308', '#14b8a6', '#6366f1'
  ];

  const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
  Chart.defaults.font.family = "'Inter', sans-serif";

  cmdChart = new Chart(ctx, {
    type: 'doughnut',
    data: {
      labels: labels,
      datasets: [{
        data: data,
        backgroundColor: colors,
        borderColor: isDark ? '#1a2332' : '#ffffff',
        borderWidth: 2,
        hoverOffset: 4
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          position: 'right',
          labels: {
            font: { size: 11 },
            padding: 15,
            color: isDark ? '#e2e8f0' : '#475569'
          }
        },
        tooltip: {
          backgroundColor: isDark ? 'rgba(15, 23, 42, 0.95)' : 'rgba(255, 255, 255, 0.95)',
          titleColor: isDark ? '#ffffff' : '#0f172a',
          bodyColor: isDark ? '#e2e8f0' : '#475569',
          borderColor: isDark ? '#1e293b' : '#e2e8f0',
          borderWidth: 1,
          padding: 12,
          displayColors: true,
          cornerRadius: 8,
        }
      },
      cutout: '65%'
    }
  });
}

function updateCmdChart(filteredData) {
  if (!cmdChart) return;
  const serviceCounts = {};
  filteredData.forEach(cmd => {
    let s = cmd.service;
    if (s === 'CLI Configuration' || s === 'Environment Customization') s = 'General';
    serviceCounts[s] = (serviceCounts[s] || 0) + 1;
  });
  cmdChart.data.labels = Object.keys(serviceCounts);
  cmdChart.data.datasets[0].data = Object.values(serviceCounts);
  cmdChart.update();
}

function copyCommand(text, btn) {
  navigator.clipboard.writeText(text).then(() => {
    let toast = document.getElementById('copyToast');
    if (!toast) {
      toast = document.createElement('div');
      toast.id = 'copyToast';
      toast.className = 'copy-toast';
      toast.textContent = 'Command copied to clipboard!';
      document.body.appendChild(toast);
    }
    toast.classList.add('show');
    
    // Change button icon temporarily
    const originalHTML = btn.innerHTML;
    btn.innerHTML = '✓';
    
    setTimeout(() => {
      toast.classList.remove('show');
      btn.innerHTML = originalHTML;
    }, 2500);
  });
}

function renderCommands() {
  const grid = document.getElementById('commandsGrid');
  if (!grid || typeof commandsData === 'undefined') return;
  grid.innerHTML = '';

  const filteredData = commandsData.filter(cmd => {
    const matchCategory = currentCmdFilter === 'All' || cmd.category === currentCmdFilter;
    const searchLower = cmdSearchQuery.toLowerCase();
    const matchSearch = cmd.command.toLowerCase().includes(searchLower) ||
                        cmd.service.toLowerCase().includes(searchLower) ||
                        cmd.purpose.toLowerCase().includes(searchLower);
    return matchCategory && matchSearch;
  });

  updateCmdChart(filteredData);

  if (filteredData.length === 0) {
    grid.innerHTML = `
      <div class="no-results" style="padding: 40px; text-align: center; background: var(--bg-card); border-radius: var(--radius-md); border: 1px dashed var(--border-color);">
        <div style="font-size: 2rem; margin-bottom: 10px; color: var(--text-tertiary);">🔍</div>
        <p style="color: var(--text-secondary); font-weight: 500;">No operational commands found matching your criteria.</p>
      </div>
    `;
    return;
  }

  filteredData.forEach((cmd) => {
    const diffClass = cmd.category.toLowerCase();
    const details = document.createElement('details');
    details.className = "cmd-card";

    details.innerHTML = `
      <summary class="cmd-summary">
        <div class="cmd-info">
          <div class="cmd-meta">
            <span class="cmd-category-badge ${diffClass}">${cmd.category}</span>
            <span>${escapeHtml(cmd.service)} &bull; ${escapeHtml(cmd.action)}</span>
          </div>
          <div class="cmd-text">${escapeHtml(cmd.command)}</div>
        </div>
        <div class="cmd-actions">
          <button type="button" class="cmd-copy-btn" aria-label="Copy command" onclick="event.preventDefault(); copyCommand('${cmd.command.replace(/'/g, "\\'")}', this)">
            📋
          </button>
          <div class="cmd-dropdown-arrow">▼</div>
        </div>
      </summary>
      
      <div class="cmd-body">
        <div class="cmd-section">
          <h4>Purpose</h4>
          <p>${escapeHtml(cmd.purpose)}</p>
        </div>
        <div class="cmd-section-grid">
          <div class="cmd-box">
            <h4>Syntax Breakdown</h4>
            <p>${cmd.meaning}</p>
          </div>
          <div class="cmd-box">
            <h4>Common Usage</h4>
            <p>${escapeHtml(cmd.usage)}</p>
          </div>
        </div>
        <div class="cmd-justification">
          <h4>Architectural Justification</h4>
          <p>${cmd.reason}</p>
        </div>
      </div>
    `;
    grid.appendChild(details);
  });
}

function setupCmdFilters() {
  const buttons = document.querySelectorAll('[data-cmd-filter]');
  if (!buttons.length) return;
  
  buttons.forEach(btn => {
    btn.addEventListener('click', (e) => {
      buttons.forEach(b => b.classList.remove('active'));
      const clicked = e.target.closest('button');
      clicked.classList.add('active');
      currentCmdFilter = clicked.getAttribute('data-cmd-filter');
      renderCommands();
    });
  });

  const searchInput = document.getElementById('cmdSearchInput');
  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      cmdSearchQuery = e.target.value;
      renderCommands();
    });
  }
}

// Hook into existing theme toggle to update chart colors
const originalThemeToggle = document.getElementById('themeToggle');
if (originalThemeToggle) {
  originalThemeToggle.addEventListener('click', () => {
    // Wait for the HTML data-theme attribute to update
    setTimeout(() => {
      if (cmdChart) {
        const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
        cmdChart.options.plugins.legend.labels.color = isDark ? '#e2e8f0' : '#475569';
        cmdChart.options.plugins.tooltip.backgroundColor = isDark ? 'rgba(15, 23, 42, 0.95)' : 'rgba(255, 255, 255, 0.95)';
        cmdChart.options.plugins.tooltip.titleColor = isDark ? '#ffffff' : '#0f172a';
        cmdChart.options.plugins.tooltip.bodyColor = isDark ? '#e2e8f0' : '#475569';
        cmdChart.options.plugins.tooltip.borderColor = isDark ? '#1e293b' : '#e2e8f0';
        cmdChart.data.datasets[0].borderColor = isDark ? '#1a2332' : '#ffffff';
        cmdChart.update();
      }
    }, 50);
  });
}

// ===== INITIALIZE =====
document.addEventListener('DOMContentLoaded', () => {
  renderAllServices();
  updateDifficultyCounts();
  
  // Initialize CloudShell Commands
  initCmdChart();
  setupCmdFilters();
  renderCommands();
});

// Make functions globally available
window.toggleService = toggleService;
window.filterByDifficulty = filterByDifficulty;
window.filterByCategory = filterByCategory;
window.copyCommand = copyCommand;
