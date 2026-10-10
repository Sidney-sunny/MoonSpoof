import { spoof_compare, spoof_analyze, spoof_batch_scan } from './moonspoof.js';

// Pre-defined presets for Pair Comparison
const PRESETS = {
  paypal: {
    a: 'paypal',
    b: 'p\u0430ypal', // Cyrillic Small Letter A (U+0430)
  },
  apple: {
    a: 'apple',
    b: 'appIe', // Latin Capital Letter I (U+0049) -> UTS #39 maps to 'l'
  },
  micro: {
    a: 'micro',
    b: '\u03BCicro', // Greek Small Letter Mu (U+03BC) -> UTS #39 maps to 'u'
  },
  invisible: {
    a: 'admin',
    b: 'admin\u200B', // Zero-Width Space (U+200B)
  },
  clean: {
    a: 'google',
    b: 'goog1e', // Digit 1 -> UTS #39 maps to 'l'
  },
};

// Attack scenario dataset for Batch Collision Scanner
const ATTACK_SCENARIO_LIST = [
  // Financial spoofing
  'paypal',
  'p\u0430ypal',
  'paypa1',
  'stripe',
  'str\u0456pe',
  'coinbase',
  'co\u0456nbase',
  'binance',
  'b\u0456nance',
  // Cloud & Developer platforms
  'github',
  'githu\u044C',
  'docker',
  'd\u043Ecker',
  'amazon',
  'am\u0430zon',
  'cloudflare',
  'cloudfl\u0430re',
  // Administrative & Security
  'admin',
  '\u0430dmin',
  'admin\u200B',
  'root',
  'r\u043E\u043Et',
  'support',
  'supp\u043Ert',
  'billing',
  'b\u0456lling',
  'security',
  'secur\u0456ty',
  // Big tech & Brands
  'apple',
  'appIe',
  '\u0430pple',
  'google',
  'goog1e',
  'microsoft',
  'rnicrosoft',
  'netflix',
  'netfl\u0456x',
  // Clean legitimate usernames
  'engineering',
  'infrastructure',
  'developer_zone',
  'system_operator',
  'core_kernel',
  'database_replica',
  'frontend_lead',
  'backend_service',
  'telemetry_node',
  'cluster_agent',
  'network_switch',
  'proxy_gateway',
  'quantum_secure',
  'moonbit_engine'
].join('\n');

// Risk color styling helper
function getRiskStyles(level) {
  switch (level) {
    case 'Critical':
      return {
        pillBg: 'bg-rose-950/70 border-rose-800 text-rose-400',
        dot: 'bg-rose-500',
        text: 'text-rose-400',
      };
    case 'High':
      return {
        pillBg: 'bg-orange-950/70 border-orange-800 text-orange-400',
        dot: 'bg-orange-500',
        text: 'text-orange-400',
      };
    case 'Medium':
      return {
        pillBg: 'bg-amber-950/70 border-amber-800 text-amber-400',
        dot: 'bg-amber-500',
        text: 'text-amber-400',
      };
    case 'Low':
      return {
        pillBg: 'bg-sky-950/70 border-sky-800 text-sky-400',
        dot: 'bg-sky-500',
        text: 'text-sky-400',
      };
    case 'Safe':
    default:
      return {
        pillBg: 'bg-emerald-950/70 border-emerald-800 text-emerald-400',
        dot: 'bg-emerald-500',
        text: 'text-emerald-400',
      };
  }
}

// ==================== TAB NAVIGATION ====================
function initTabs() {
  const tabs = document.querySelectorAll('.tab-btn');
  const panes = {
    compare: document.getElementById('pane-compare'),
    scanner: document.getElementById('pane-scanner'),
    inspector: document.getElementById('pane-inspector'),
  };

  tabs.forEach(btn => {
    btn.addEventListener('click', () => {
      const target = btn.dataset.tab;
      tabs.forEach(b => {
        b.classList.remove('active', 'text-white', 'bg-obsidian-700', 'shadow-sm');
        b.classList.add('text-obsidian-400');
      });
      btn.classList.add('active', 'text-white', 'bg-obsidian-700', 'shadow-sm');
      btn.classList.remove('text-obsidian-400');

      Object.keys(panes).forEach(k => {
        if (k === target) {
          panes[k].classList.remove('hidden');
        } else {
          panes[k].classList.add('hidden');
        }
      });
    });
  });
}

// ==================== ZONE A: PAIR COMPARISON ====================
function initCompareZone() {
  const inputA = document.getElementById('input-a');
  const inputB = document.getElementById('input-b');
  const btnSwap = document.getElementById('btn-swap-inputs');
  const presetBtns = document.querySelectorAll('.preset-btn');

  function renderReport(cardSuffix, data) {
    const riskPill = document.getElementById(`risk-pill-${cardSuffix}`);
    const skeleton = document.getElementById(`skeleton-${cardSuffix}`);
    const script = document.getElementById(`script-${cardSuffix}`);
    const restriction = document.getElementById(`restriction-${cardSuffix}`);
    const rulesContainer = document.getElementById(`rules-${cardSuffix}`);

    const styles = getRiskStyles(data.risk_level);
    riskPill.className = `text-[11px] font-mono px-2 py-0.5 rounded border ${styles.pillBg}`;
    riskPill.textContent = data.risk_level;

    skeleton.textContent = data.skeleton || '(empty)';
    script.textContent = data.primary_script || 'Unknown';
    restriction.textContent = data.restriction_level || 'SingleScript';

    rulesContainer.innerHTML = '';
    if (!data.rules_triggered || data.rules_triggered.length === 0) {
      const noneSpan = document.createElement('span');
      noneSpan.className = 'px-2 py-0.5 rounded bg-obsidian-800/60 text-obsidian-400 border border-obsidian-800';
      noneSpan.textContent = 'None';
      rulesContainer.appendChild(noneSpan);
    } else {
      data.rules_triggered.forEach(rule => {
        const tag = document.createElement('span');
        tag.className = 'px-2 py-0.5 rounded bg-rose-950/60 text-rose-400 border border-rose-900/60';
        tag.textContent = rule;
        rulesContainer.appendChild(tag);
      });
    }
  }

  function runCompare() {
    const t0 = performance.now();
    const strA = inputA.value;
    const strB = inputB.value;

    try {
      const rawJson = spoof_compare(strA, strB);
      const res = JSON.parse(rawJson);
      const dt = (performance.now() - t0).toFixed(2);
      document.getElementById('latency-text').textContent = `${dt} ms`;

      renderReport('a', res.a);
      renderReport('b', res.b);

      const banner = document.getElementById('compare-result-banner');
      const dot = document.getElementById('compare-status-dot');
      const title = document.getElementById('compare-status-title');
      const desc = document.getElementById('compare-status-desc');
      const pill = document.getElementById('compare-status-pill');

      if (res.are_confusable) {
        banner.className = 'border rounded-xl p-4 transition flex items-center justify-between bg-rose-950/20 border-rose-900/80';
        dot.className = 'w-3 h-3 rounded-full bg-rose-500 animate-pulse';
        title.className = 'text-sm font-semibold text-rose-300 tracking-wide';
        title.textContent = 'CONFUSABLE EQUIVALENCE CONFIRMED (SPOOF RISK DETECTED)';
        desc.textContent = 'Identifiers resolve to identical UTS #39 Confusable Skeletons and present visual impersonation danger.';
        pill.className = 'text-xs font-mono font-medium px-3 py-1 rounded border bg-rose-950/80 text-rose-300 border-rose-800';
        pill.textContent = 'CONFUSABLE MATCH';
      } else {
        banner.className = 'border rounded-xl p-4 transition flex items-center justify-between bg-obsidian-900 border-obsidian-800';
        dot.className = 'w-3 h-3 rounded-full bg-emerald-500';
        title.className = 'text-sm font-semibold text-white tracking-wide';
        title.textContent = 'DISTINCT IDENTIFIERS (NO SKELETON COLLISION)';
        desc.textContent = 'Identifiers have different UTS #39 skeleton signatures and do not collide under confusable normalization.';
        pill.className = 'text-xs font-mono font-medium px-3 py-1 rounded border bg-obsidian-850 text-emerald-400 border-obsidian-700';
        pill.textContent = 'DISTINCT';
      }
    } catch (err) {
      console.error('Comparison execution error:', err);
    }
  }

  inputA.addEventListener('input', runCompare);
  inputB.addEventListener('input', runCompare);

  btnSwap.addEventListener('click', () => {
    const tmp = inputA.value;
    inputA.value = inputB.value;
    inputB.value = tmp;
    runCompare();
  });

  presetBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const p = PRESETS[btn.dataset.preset];
      if (p) {
        inputA.value = p.a;
        inputB.value = p.b;
        runCompare();
      }
    });
  });

  // Initial trigger
  runCompare();
}

// ==================== ZONE B: COLLISION SCANNER ====================
let lastScanResult = null;

function initScannerZone() {
  const textarea = document.getElementById('scanner-input');
  const btnLoadMock = document.getElementById('btn-load-mock-batch');
  const btnClear = document.getElementById('btn-clear-batch');
  const btnExportJson = document.getElementById('btn-export-batch-json');
  const btnExportCsv = document.getElementById('btn-export-batch-csv');

  const metricTotal = document.getElementById('metric-total-names');
  const metricGroups = document.getElementById('metric-collision-groups');
  const metricMembers = document.getElementById('metric-colliding-members');
  const metricLatency = document.getElementById('metric-scan-latency');
  const groupCounter = document.getElementById('scanner-group-counter');
  const container = document.getElementById('scanner-groups-container');

  function runScan() {
    const raw = textarea.value.trim();
    if (!raw) {
      metricTotal.textContent = '0';
      metricGroups.textContent = '0';
      metricMembers.textContent = '0';
      metricLatency.textContent = '0 ms';
      groupCounter.textContent = '0 groups detected';
      container.innerHTML = '<div class="py-8 text-center text-xs text-obsidian-500 font-mono">No input provided. Paste identifiers or click "Load Attack Scenario" to run the scan.</div>';
      lastScanResult = null;
      return;
    }

    const t0 = performance.now();
    try {
      const rawJson = spoof_batch_scan(raw);
      const res = JSON.parse(rawJson);
      const dt = (performance.now() - t0).toFixed(2);

      lastScanResult = res;

      let collidingCount = 0;
      res.groups.forEach(g => {
        collidingCount += g.count;
      });

      metricTotal.textContent = res.total_names;
      metricGroups.textContent = res.group_count;
      metricMembers.textContent = collidingCount;
      metricLatency.textContent = `${dt} ms`;
      groupCounter.textContent = `${res.group_count} collision groups detected`;

      container.innerHTML = '';
      if (res.groups.length === 0) {
        container.innerHTML = '<div class="py-8 text-center text-xs text-emerald-400 font-mono bg-emerald-950/20 border border-emerald-900/40 rounded-lg">No collisions found! All identifiers are mutually distinct under UTS #39 skeleton normalization.</div>';
        return;
      }

      res.groups.forEach((group, idx) => {
        const card = document.createElement('div');
        card.className = 'border border-obsidian-800 rounded-lg p-3.5 bg-obsidian-950/60 hover:border-obsidian-700 transition space-y-2';

        const header = document.createElement('div');
        header.className = 'flex items-center justify-between text-xs font-mono';
        header.innerHTML = `
          <div class="flex items-center space-x-2">
            <span class="w-1.5 h-1.5 rounded-full bg-rose-500"></span>
            <span class="text-obsidian-400">Cluster #${idx + 1} Skeleton:</span>
            <span class="text-white font-bold select-all bg-obsidian-850 px-2 py-0.5 rounded border border-obsidian-800">${escapeHtml(group.skeleton)}</span>
          </div>
          <span class="px-2 py-0.5 rounded text-[11px] bg-rose-950/60 text-rose-400 border border-rose-900/60">${group.count} Colliding Identifiers</span>
        `;

        const memberList = document.createElement('div');
        memberList.className = 'flex flex-wrap gap-1.5 pt-1';
        group.members.forEach(m => {
          const pill = document.createElement('span');
          pill.className = 'px-2.5 py-1 rounded text-xs font-mono bg-obsidian-800/90 text-obsidian-200 border border-obsidian-700 select-all';
          pill.textContent = m;
          memberList.appendChild(pill);
        });

        card.appendChild(header);
        card.appendChild(memberList);
        container.appendChild(card);
      });
    } catch (err) {
      console.error('Batch scan error:', err);
    }
  }

  textarea.addEventListener('input', runScan);

  btnLoadMock.addEventListener('click', () => {
    textarea.value = ATTACK_SCENARIO_LIST;
    runScan();
  });

  btnClear.addEventListener('click', () => {
    textarea.value = '';
    runScan();
  });

  btnExportJson.addEventListener('click', () => {
    if (!lastScanResult) return;
    const blob = new Blob([JSON.stringify(lastScanResult, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `moonspoof_collision_report_${Date.now()}.json`;
    a.click();
    URL.revokeObjectURL(url);
  });

  btnExportCsv.addEventListener('click', () => {
    if (!lastScanResult || !lastScanResult.groups) return;
    const rows = [['Skeleton', 'MemberCount', 'CollidingMember']];
    lastScanResult.groups.forEach(g => {
      g.members.forEach(m => {
        rows.push([`"${g.skeleton}"`, g.count, `"${m}"`]);
      });
    });
    const csvContent = rows.map(e => e.join(',')).join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `moonspoof_collision_report_${Date.now()}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  });

  // Load attack scenario by default in background
  textarea.value = ATTACK_SCENARIO_LIST;
  runScan();
}

// ==================== ZONE C: GLYPH INSPECTOR ====================
function initInspectorZone() {
  const input = document.getElementById('inspector-input');
  const riskDot = document.getElementById('inspector-risk-dot');
  const riskTitle = document.getElementById('inspector-risk-title');
  const riskDesc = document.getElementById('inspector-risk-desc');
  const skeletonEl = document.getElementById('inspector-skeleton');
  const scriptEl = document.getElementById('inspector-primary-script');
  const restrictionEl = document.getElementById('inspector-restriction');
  const rulesEl = document.getElementById('inspector-rules');
  const charCountEl = document.getElementById('inspector-char-count');
  const tableBody = document.getElementById('inspector-table-body');

  function runInspect() {
    const val = input.value;
    if (!val) {
      tableBody.innerHTML = '<tr><td colspan="7" class="text-center py-6 text-obsidian-500">Enter an identifier above to inspect glyphs.</td></tr>';
      charCountEl.textContent = '0 codepoints';
      return;
    }

    try {
      const rawJson = spoof_analyze(val);
      const res = JSON.parse(rawJson);

      const styles = getRiskStyles(res.risk_level);
      riskDot.className = `w-3 h-3 rounded-full ${styles.dot}`;
      riskTitle.className = `text-xs font-mono font-bold ${styles.text}`;
      riskTitle.textContent = res.risk_level;

      if (res.risk_level === 'Critical') {
        riskDesc.textContent = 'Critical danger: identifier incorporates invisible format controls or bidirectional spoofing.';
      } else if (res.risk_level === 'High') {
        riskDesc.textContent = 'High danger: mixed-script identifier containing cross-script confusable homoglyphs.';
      } else if (res.risk_level === 'Medium') {
        riskDesc.textContent = 'Medium warning: identifier exhibits mixed scripts or potential confusability.';
      } else if (res.risk_level === 'Low') {
        riskDesc.textContent = 'Low risk: canonical skeleton differs from literal input (e.g. ASCII fullwidth or digraph).';
      } else {
        riskDesc.textContent = 'Safe: strictly single-script with clean, unambiguous glyphs.';
      }

      skeletonEl.textContent = res.skeleton || '(empty)';
      scriptEl.textContent = res.primary_script || 'Unknown';
      restrictionEl.textContent = res.restriction_level || 'SingleScript';
      charCountEl.textContent = `${res.chars.length} codepoints`;

      rulesEl.innerHTML = '';
      if (!res.rules_triggered || res.rules_triggered.length === 0) {
        rulesEl.innerHTML = '<span class="px-2 py-0.5 rounded bg-obsidian-800/60 text-obsidian-400 border border-obsidian-800 text-[11px] font-mono">None</span>';
      } else {
        res.rules_triggered.forEach(rule => {
          const pill = document.createElement('span');
          pill.className = 'px-2 py-0.5 rounded bg-rose-950/60 text-rose-400 border border-rose-900/60 text-[11px] font-mono';
          pill.textContent = rule;
          rulesEl.appendChild(pill);
        });
      }

      tableBody.innerHTML = '';
      res.chars.forEach((c, idx) => {
        const row = document.createElement('tr');
        row.className = 'hover:bg-obsidian-850/60 transition';

        let glyphDisplay = c.char;
        let glyphClass = 'text-white font-medium text-sm';
        if (c.is_invisible) {
          glyphDisplay = '[INVISIBLE]';
          glyphClass = 'text-rose-400 text-[11px] px-1.5 py-0.5 rounded bg-rose-950 border border-rose-900';
        } else if (c.is_bidi) {
          glyphDisplay = '[BIDI_CTRL]';
          glyphClass = 'text-rose-400 text-[11px] px-1.5 py-0.5 rounded bg-rose-950 border border-rose-900';
        }

        const flags = [];
        if (c.is_invisible) {
          flags.push('<span class="px-1.5 py-0.5 rounded bg-rose-950/80 text-rose-400 border border-rose-800 text-[10px]">INVISIBLE</span>');
        }
        if (c.is_bidi) {
          flags.push('<span class="px-1.5 py-0.5 rounded bg-rose-950/80 text-rose-400 border border-rose-800 text-[10px]">BIDI</span>');
        }
        if (c.is_confusable) {
          flags.push('<span class="px-1.5 py-0.5 rounded bg-amber-950/80 text-amber-400 border border-amber-800 text-[10px]">CONFUSABLE</span>');
        }
        if (flags.length === 0) {
          flags.push('<span class="px-1.5 py-0.5 rounded bg-obsidian-800/80 text-obsidian-400 border border-obsidian-700 text-[10px]">CLEAN</span>');
        }

        row.innerHTML = `
          <td class="px-4 py-2.5 text-obsidian-500">${idx}</td>
          <td class="px-4 py-2.5"><span class="${glyphClass}">${escapeHtml(glyphDisplay)}</span></td>
          <td class="px-4 py-2.5 text-white">${escapeHtml(c.hex)}</td>
          <td class="px-4 py-2.5 text-obsidian-400">${c.codepoint}</td>
          <td class="px-4 py-2.5 text-obsidian-200">${escapeHtml(c.script)}</td>
          <td class="px-4 py-2.5 text-white font-bold select-all">${escapeHtml(c.confusable_target)}</td>
          <td class="px-4 py-2.5"><div class="flex flex-wrap gap-1">${flags.join('')}</div></td>
        `;

        tableBody.appendChild(row);
      });
    } catch (err) {
      console.error('Inspector execution error:', err);
    }
  }

  input.addEventListener('input', runInspect);
  runInspect();
}

function escapeHtml(str) {
  if (!str) return '';
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

// ==================== INITIALIZATION ====================
document.addEventListener('DOMContentLoaded', () => {
  initTabs();
  initCompareZone();
  initScannerZone();
  initInspectorZone();
});
