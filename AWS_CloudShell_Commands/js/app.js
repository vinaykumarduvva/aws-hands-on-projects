
let currentFilter = 'All';
let searchQuery = '';
let myChart = null;

// Theme Toggle Logic
const themeToggleBtn = document.getElementById('theme-toggle');
const htmlEl = document.documentElement;

// Initialize theme from localStorage or system preference
if (localStorage.getItem('theme') === 'light') {
    htmlEl.classList.remove('dark');
} else {
    // Default to dark
    htmlEl.classList.add('dark');
    localStorage.setItem('theme', 'dark');
}

themeToggleBtn.addEventListener('click', () => {
    if (htmlEl.classList.contains('dark')) {
        htmlEl.classList.remove('dark');
        localStorage.setItem('theme', 'light');
    } else {
        htmlEl.classList.add('dark');
        localStorage.setItem('theme', 'dark');
    }
    // Re-render chart to update label colors
    if (myChart) {
        myChart.options.plugins.legend.labels.color = htmlEl.classList.contains('dark') ? '#cbd5e1' : '#475569';
        myChart.update();
    }
});

function getCategoryStyle(category) {
    if (category === 'Beginner') return 'text-emerald-600 dark:text-emerald-400 border-emerald-300 dark:border-emerald-900 bg-emerald-100/50 dark:bg-emerald-950/30';
    if (category === 'Intermediate') return 'text-sky-600 dark:text-sky-400 border-sky-300 dark:border-sky-900 bg-sky-100/50 dark:bg-sky-950/30';
    return 'text-aws-orange border-orange-300 dark:border-orange-900 bg-orange-100/50 dark:bg-orange-950/30';
}

function initChart() {
    const ctx = document.getElementById('serviceChart').getContext('2d');

    const serviceCounts = {};
    commandsData.forEach(cmd => {
        let s = cmd.service;
        if (s === 'CLI Configuration' || s === 'Environment Customization') s = 'General';
        serviceCounts[s] = (serviceCounts[s] || 0) + 1;
    });

    const labels = Object.keys(serviceCounts);
    const data = Object.values(serviceCounts);

    const colors = [
        '#FF9900', '#007EBC', '#10b981', '#8b5cf6', '#f43f5e', 
        '#0ea5e9', '#64748b', '#eab308', '#14b8a6', '#6366f1'
    ];

    Chart.defaults.font.family = "'Inter', sans-serif";

    myChart = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: labels,
            datasets: [{
                data: data,
                backgroundColor: colors,
                borderColor: htmlEl.classList.contains('dark') ? '#1e293b' : '#ffffff',
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
                        color: htmlEl.classList.contains('dark') ? '#cbd5e1' : '#475569'
                    }
                },
                tooltip: {
                    backgroundColor: 'rgba(15, 23, 42, 0.95)',
                    titleColor: '#ffffff',
                    bodyColor: '#e2e8f0',
                    borderColor: '#334155',
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

function updateChartData(filteredCommands) {
    if (!myChart) return;
    const serviceCounts = {};
    filteredCommands.forEach(cmd => {
        let s = cmd.service;
        if (s === 'CLI Configuration' || s === 'Environment Customization') s = 'General';
        serviceCounts[s] = (serviceCounts[s] || 0) + 1;
    });
    myChart.data.labels = Object.keys(serviceCounts);
    myChart.data.datasets[0].data = Object.values(serviceCounts);
    myChart.update();
}

function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => {
        const notify = document.getElementById('copyNotify');
        notify.style.opacity = '1';
        notify.style.transform = 'translateY(0)';
        setTimeout(() => {
            notify.style.opacity = '0';
            notify.style.transform = 'translateY(4px)';
        }, 2500);
    });
}

function renderCommands() {
    const grid = document.getElementById('commandsGrid');
    grid.innerHTML = '';

    const filteredData = commandsData.filter(cmd => {
        const matchCategory = currentFilter === 'All' || cmd.category === currentFilter;
        const searchLower = searchQuery.toLowerCase();
        const matchSearch = cmd.command.toLowerCase().includes(searchLower) ||
                            cmd.service.toLowerCase().includes(searchLower) ||
                            cmd.purpose.toLowerCase().includes(searchLower);
        return matchCategory && matchSearch;
    });

    updateChartData(filteredData);

    if (filteredData.length === 0) {
        grid.innerHTML = `
            <div class="p-10 text-center border border-slate-300 dark:border-cloud-700 border-dashed rounded-xl bg-slate-50 dark:bg-cloud-900/50">
                <i class="fas fa-search text-3xl text-slate-400 dark:text-slate-600 mb-3"></i>
                <p class="text-slate-500 dark:text-slate-400 font-medium text-sm">No operational commands found matching your criteria.</p>
            </div>
        `;
        return;
    }

    filteredData.forEach((cmd) => {
        const styleClass = getCategoryStyle(cmd.category);

        const details = document.createElement('details');
        details.className = "group bg-white dark:bg-cloud-900/80 border border-slate-200 dark:border-cloud-700 rounded-lg overflow-hidden hover:border-sky-500/30 dark:hover:border-sky-500/30 transition-all duration-200 shadow-sm dark:shadow-none";

        details.innerHTML = `
            <summary class="p-4 cursor-pointer flex flex-col md:flex-row md:items-center justify-between gap-4 list-none outline-none">
                <div class="flex-1">
                    <div class="flex items-center gap-3 mb-2">
                        <span class="text-[10px] font-mono px-2 py-0.5 rounded border ${styleClass} uppercase font-semibold">${cmd.category}</span>
                        <span class="text-xs font-semibold text-slate-600 dark:text-slate-400 uppercase tracking-wider">${cmd.service} &bull; ${cmd.action}</span>
                    </div>
                    <h3 class="font-mono text-sm text-slate-900 dark:text-slate-200 group-hover:text-sky-600 dark:group-hover:text-sky-400 transition-colors break-all md:break-normal">${cmd.command}</h3>
                </div>
                <div class="flex items-center gap-4 shrink-0">
                    <button type="button" onclick="event.preventDefault(); copyToClipboard('${cmd.command.replace(/'/g, "\'")}')" class="p-2 text-slate-500 dark:text-slate-500 hover:text-sky-600 dark:hover:text-sky-400 transition-colors bg-slate-100 dark:bg-cloud-800 hover:bg-slate-200 dark:hover:bg-cloud-700 rounded-md" aria-label="Copy command">
                        <i class="fas fa-copy"></i>
                    </button>
                    <div class="text-slate-500 group-open:rotate-180 transition-transform duration-300">
                        <i class="fas fa-chevron-down"></i>
                    </div>
                </div>
            </summary>

            <div class="p-5 bg-slate-50 dark:bg-cloud-800 border-t border-slate-200 dark:border-cloud-700 text-sm text-slate-700 dark:text-slate-300 space-y-5">
                <div>
                    <span class="text-xs font-bold text-slate-500 uppercase tracking-wider block mb-2">Purpose</span>
                    <p class="leading-relaxed">${cmd.purpose}</p>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                    <div>
                        <span class="text-xs font-bold text-slate-500 uppercase tracking-wider block mb-2">Syntax Breakdown</span>
                        <p class="leading-relaxed bg-white dark:bg-cloud-900 p-3 rounded-lg border border-slate-200 dark:border-cloud-700 text-sm">${cmd.meaning}</p>
                    </div>
                    <div>
                        <span class="text-xs font-bold text-slate-500 uppercase tracking-wider block mb-2">Common Usage</span>
                        <p class="leading-relaxed bg-white dark:bg-cloud-900 p-3 rounded-lg border border-slate-200 dark:border-cloud-700 text-sm">${cmd.usage}</p>
                    </div>
                </div>
                <div class="bg-blue-50 dark:bg-blue-900/20 border-l-4 border-blue-500 p-4 rounded-r-lg text-slate-800 dark:text-slate-300">
                    <span class="font-bold text-blue-600 dark:text-blue-400 uppercase tracking-wider block mb-1 text-xs">Architectural Justification</span>
                    <p class="leading-relaxed text-sm">${cmd.reason}</p>
                </div>
            </div>
        `;
        grid.appendChild(details);
    });
}

function setupFilters() {
    const buttons = document.querySelectorAll('.filter-btn');
    buttons.forEach(btn => {
        btn.addEventListener('click', (e) => {
            buttons.forEach(b => {
                b.className = 'filter-btn px-4 py-2 text-sm font-medium rounded-md transition-colors text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-200 dark:hover:bg-cloud-800 border border-transparent';
            });

            const clicked = e.target;
            clicked.className = 'filter-btn active px-4 py-2 text-sm font-medium rounded-md transition-colors bg-sky-600 dark:bg-cloud-700 text-white shadow-sm';

            currentFilter = clicked.getAttribute('data-filter');
            renderCommands();
        });
    });

    document.getElementById('searchInput').addEventListener('input', (e) => {
        searchQuery = e.target.value;
        renderCommands();
    });
}

document.addEventListener('DOMContentLoaded', () => {
    initChart();
    setupFilters();
    renderCommands();
});
