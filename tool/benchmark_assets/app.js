(function() {
  'use strict';

  var DATA = window.__BENCHMARK_DATA__ || { baselines: {}, history: [], meta: {} };
  var theme = localStorage.getItem('benchmark-theme') || 'auto';

  var lastRun = DATA.history.length > 0 ? DATA.history[DATA.history.length - 1] : null;
  var prevRun = DATA.history.length > 1 ? DATA.history[DATA.history.length - 2] : null;

  var refs = {
    headerTime: byId('header-time'),
    headerRuns: byId('header-runs'),
    themeToggle: byId('theme-toggle'),
    summary: byId('summary'),
    overview: byId('overview-content'),
    fileCards: byId('file-cards'),
    filter: byId('filter-input'),
    sort: byId('sort-select'),
    showCharts: byId('show-charts-toggle'),
    trends: byId('trends'),
    trendCharts: byId('trend-charts'),
  };

  applyTheme();
  updateThemeButton();
  refs.themeToggle.addEventListener('click', function() {
    theme = theme === 'auto' ? 'dark' : theme === 'dark' ? 'light' : 'auto';
    localStorage.setItem('benchmark-theme', theme);
    applyTheme();
    updateThemeButton();
  });

  if (DATA.meta.generated_at) {
    refs.headerTime.textContent = 'Generated ' + fmtDate(DATA.meta.generated_at);
  }
  refs.headerRuns.textContent = DATA.history.length + ' run' + (DATA.history.length === 1 ? '' : 's');

  refs.filter.addEventListener('input', renderAll);
  refs.sort.addEventListener('change', renderAll);
  refs.showCharts.addEventListener('change', renderAll);

  renderAll();

  function renderAll() {
    renderSummary();
    renderOverview();
    renderDetails();
    renderTrends();
  }

  function renderSummary() {
    if (!lastRun) {
      refs.summary.innerHTML = '<div class="empty">No benchmark data yet. Run benchmarks first.</div>';
      return;
    }

    var total = number(lastRun.total_score);
    var totalDelta = prevRun ? total - number(prevRun.total_score) : null;
    var files = lastRun.files || {};
    var items = latestItems();
    var worst = biggestRegression(items);
    var best = biggestImprovement(items);
    var deltaText = totalDelta === null ? 'No previous run' : signed(totalDelta, 1);
    var deltaTone = totalDelta === null ? 'neutral' : totalDelta >= 0 ? 'good' : 'bad';

    var html = '';
    html += summaryCard({
      label: 'Total score',
      value: total.toFixed(1),
      tone: scoreClass(total),
      meta: scoreStatus(total),
    });
    html += summaryCard({
      label: 'vs previous',
      value: deltaText,
      tone: deltaTone,
      meta: totalDelta === null ? 'Baseline run' : totalDelta >= 0 ? 'Score improved' : 'Score dropped',
    });
    html += summaryCard({
      label: worst ? 'Worst change' : 'Best improvement',
      value: worst ? signed(worst.delta, 1) + '%' : best ? signed(best.delta, 1) + '%' : 'Stable',
      tone: worst ? 'bad' : best ? 'good' : 'neutral',
      meta: shortKey(worst || best),
    });
    html += summaryCard({
      label: 'Coverage',
      value: Object.keys(files).length + ' files',
      tone: 'neutral',
      meta: items.length + ' benchmark items',
    });
    refs.summary.innerHTML = html;
  }

  function renderOverview() {
    if (!lastRun) {
      refs.overview.innerHTML = '<div class="empty">No data.</div>';
      return;
    }

    var items = latestItems();
    var worst = biggestRegression(items);
    var best = biggestImprovement(items);
    var slowest = items.slice().sort(function(a, b) { return b.mean - a.mean; })[0];

    var html = '<div class="overview-grid">';
    html += '<div class="score-history">';
    html += '<div class="overview-label">Total score history</div>';
    html += renderScoreHistory();
    html += '</div>';
    html += '<div class="overview-list">';
    html += overviewRow('Worst regression', worst ? signed(worst.delta, 1) + '%' : 'None', shortKey(worst), worst ? 'bad' : 'neutral');
    html += overviewRow('Best improvement', best ? signed(best.delta, 1) + '%' : 'None', shortKey(best), best ? 'good' : 'neutral');
    html += overviewRow('Slowest item', slowest ? fmtMs(slowest.mean) : 'None', shortKey(slowest), 'neutral');
    html += '</div>';
    html += '</div>';
    refs.overview.innerHTML = html;
  }

  function renderDetails() {
    if (!lastRun) {
      refs.fileCards.innerHTML = '<div class="empty">No data.</div>';
      return;
    }

    var files = lastRun.files || {};
    var filter = filterText();
    var sort = refs.sort.value || 'name';
    var html = '';
    var visibleFileCount = 0;

    Object.keys(files).sort().forEach(function(fid) {
      var fdata = files[fid] || {};
      var items = Object.keys(fdata.items || {}).map(function(name) {
        return toItem(fid, name, fdata.items[name]);
      });

      var filteredItems = items.filter(function(item) {
        return !filter || item.key.toLowerCase().indexOf(filter) >= 0;
      });
      sortItems(filteredItems, sort);

      if (filter && filteredItems.length === 0 && fid.toLowerCase().indexOf(filter) < 0) {
        return;
      }

      visibleFileCount++;
      var fileScore = number(fdata.score, 100);
      var maxMean = Math.max.apply(null, filteredItems.map(function(item) { return item.mean; }).concat([1]));

      html += '<article class="file-card">';
      html += '<div class="file-card-header">';
      html += '<div>';
      html += '<h3>' + esc(fid) + '</h3>';
      html += '<div class="file-meta">weight ' + number(fdata.weight, 1).toFixed(1) + ' &middot; ' + filteredItems.length + ' items</div>';
      html += '</div>';
      html += '<span class="score-badge ' + scoreClass(fileScore) + '">' + fileScore.toFixed(0) + '</span>';
      html += '</div>';

      if (filteredItems.length === 0) {
        html += '<div class="empty small">No matching benchmarks</div>';
      } else {
        html += '<div class="bench-table-wrap">';
        html += '<table class="bench-table">';
        html += '<thead><tr>';
        html += '<th>Benchmark</th><th>Mean</th><th>Median</th><th>P90</th><th>Reference</th><th>Change</th><th>Trend</th><th>Score</th>';
        html += '</tr></thead><tbody>';
        filteredItems.forEach(function(item) {
          var deltaClassName = item.delta === null ? 'neutral' : deltaClass(item.delta);
          var runtimeWidth = Math.max(8, Math.min(100, item.mean / maxMean * 100));
          html += '<tr>';
          html += '<td class="bench-name"><span>' + esc(item.name) + '</span></td>';
          html += '<td class="metric-cell"><span class="metric-value">' + fmtMs(item.mean) + '</span><span class="runtime-bar"><span style="width:' + runtimeWidth.toFixed(0) + '%"></span></span></td>';
          html += '<td>' + fmtMs(item.median) + '</td>';
          html += '<td>' + fmtMs(item.p90) + '</td>';
          html += '<td class="reference-cell">' + referenceHtml(item) + '</td>';
          html += '<td><span class="delta-pill ' + deltaClassName + '">' + deltaLabel(item.delta) + '</span></td>';
          html += '<td class="trend-cell">' + renderSparkline(item.fid, item.name, item.delta) + '</td>';
          html += '<td><span class="score-badge ' + scoreClass(item.score) + '">' + Math.round(item.score) + '</span></td>';
          html += '</tr>';
        });
        html += '</tbody></table></div>';
      }

      html += '</article>';
    });

    refs.fileCards.innerHTML = visibleFileCount === 0
      ? '<div class="empty">No matching files or benchmarks.</div>'
      : html;
  }

  function renderTrends() {
    var show = refs.showCharts.checked;
    refs.trends.style.display = show ? 'block' : 'none';
    if (!show) return;

    if (DATA.history.length < 2) {
      refs.trendCharts.innerHTML = '<div class="empty small">Need 2+ runs to show trend cards.</div>';
      return;
    }

    var filter = filterText();
    var items = collectTrendItems().filter(function(item) {
      return !filter || item.key.toLowerCase().indexOf(filter) >= 0;
    });

    items.sort(function(a, b) {
      return Math.abs(b.delta || 0) - Math.abs(a.delta || 0);
    });

    if (items.length === 0) {
      refs.trendCharts.innerHTML = '<div class="empty small">No trend data available.</div>';
      return;
    }

    refs.trendCharts.innerHTML = items.map(function(item) {
      return '<article class="trend-chart-card ' + deltaClass(item.delta) + '">'
        + '<div class="trend-card-header">'
        + '<div><h4>' + esc(item.fid) + '</h4><p>' + esc(item.name) + '</p></div>'
        + '<span class="delta-pill ' + deltaClass(item.delta) + '">' + signed(item.delta, 1) + '%</span>'
        + '</div>'
        + renderTrendSvg(item.values, item.baseline, 320, 120, true)
        + '<div class="trend-card-footer"><span>First ' + fmtMs(item.values[0]) + '</span><span>Latest ' + fmtMs(item.values[item.values.length - 1]) + '</span></div>'
        + '</article>';
    }).join('');
  }

  function latestItems() {
    if (!lastRun || !lastRun.files) return [];
    var output = [];
    Object.keys(lastRun.files).forEach(function(fid) {
      var items = lastRun.files[fid].items || {};
      Object.keys(items).forEach(function(name) {
        output.push(toItem(fid, name, items[name]));
      });
    });
    return output;
  }

  function collectTrendItems() {
    var keys = {};
    DATA.history.forEach(function(rec) {
      Object.keys(rec.files || {}).forEach(function(fid) {
        var items = rec.files[fid].items || {};
        Object.keys(items).forEach(function(name) {
          keys[fid + ':' + name] = { fid: fid, name: name };
        });
      });
    });

    return Object.keys(keys).map(function(key) {
      var info = keys[key];
      var values = [];
      DATA.history.forEach(function(rec) {
        var file = rec.files && rec.files[info.fid];
        var item = file && file.items && file.items[info.name];
        if (item) values.push(number(item.mean_ms));
      });
      if (values.length < 2) return null;
      var first = values[0];
      var latest = values[values.length - 1];
      var baseline = DATA.baselines[key] || null;
      return {
        key: key,
        fid: info.fid,
        name: info.name,
        values: values,
        baseline: baseline,
        delta: first > 0 ? (latest - first) / first * 100 : 0,
      };
    }).filter(Boolean);
  }

  function toItem(fid, name, raw) {
    raw = raw || {};
    var key = fid + ':' + name;
    var mean = number(raw.mean_ms);
    var baseline = referenceNumber(raw.baseline_ms);
    if (baseline === null) {
      baseline = referenceNumber(DATA.baselines[key]);
    }
    var previous = baseline === null ? previousMeanFor(fid, name) : null;
    var reference = baseline !== null ? baseline : previous;
    return {
      fid: fid,
      name: name,
      key: key,
      mean: mean,
      median: number(raw.median_ms, mean),
      p90: number(raw.p90_ms, mean),
      baseline: baseline,
      reference: reference,
      referenceKind: baseline !== null ? 'baseline' : (previous !== null ? 'previous' : null),
      score: number(raw.score, 100),
      delta: reference && reference > 0 ? (mean - reference) / reference * 100 : null,
    };
  }

  function previousMeanFor(fid, name) {
    for (var i = DATA.history.length - 2; i >= 0; i--) {
      var fd = DATA.history[i].files && DATA.history[i].files[fid];
      var item = fd && fd.items && fd.items[name];
      if (item && item.mean_ms !== undefined && item.mean_ms !== null) {
        return number(item.mean_ms);
      }
    }
    return null;
  }

  function sortItems(items, sort) {
    items.sort(function(a, b) {
      if (sort === 'slowest') return b.mean - a.mean || a.key.localeCompare(b.key);
      if (sort === 'regression') return nullableDelta(b.delta) - nullableDelta(a.delta) || a.key.localeCompare(b.key);
      if (sort === 'score') return a.score - b.score || a.key.localeCompare(b.key);
      return a.name.localeCompare(b.name);
    });
  }

  function nullableDelta(value) {
    return value === null ? -Infinity : value;
  }

  function biggestRegression(items) {
    return items
      .filter(function(item) { return item.delta !== null && item.delta > 0.1; })
      .sort(function(a, b) { return b.delta - a.delta; })[0] || null;
  }

  function biggestImprovement(items) {
    return items
      .filter(function(item) { return item.delta !== null && item.delta < -0.1; })
      .sort(function(a, b) { return a.delta - b.delta; })[0] || null;
  }

  function renderScoreHistory() {
    var values = DATA.history.map(function(run) { return number(run.total_score); });
    if (values.length < 2) {
      return '<div class="empty small">Need 2+ runs for history.</div>';
    }
    return renderTrendSvg(values, null, 640, 160, false);
  }

  function renderSparkline(fid, bench, delta) {
    var values = [];
    DATA.history.forEach(function(rec) {
      var fd = rec.files && rec.files[fid];
      if (fd && fd.items && fd.items[bench]) {
        values.push(number(fd.items[bench].mean_ms));
      }
    });
    if (values.length < 2) return '<span class="muted">-</span>';
    return '<span class="sparkline-wrap ' + deltaClass(delta) + '">' + renderTrendSvg(values, null, 92, 34, false) + '</span>';
  }

  function renderTrendSvg(values, baseline, width, height, withAxis) {
    var padding = withAxis ? 22 : 8;
    var minValue = Math.min.apply(null, values.concat(baseline ? [baseline] : []));
    var maxValue = Math.max.apply(null, values.concat(baseline ? [baseline] : []));
    var range = maxValue - minValue || 1;
    var innerW = width - padding * 2;
    var innerH = height - padding * 2;
    var points = values.map(function(value, index) {
      var x = padding + (values.length === 1 ? innerW : index / (values.length - 1) * innerW);
      var y = padding + (1 - (value - minValue) / range) * innerH;
      return { x: x, y: y, value: value };
    });
    var line = points.map(function(point, index) {
      return (index === 0 ? 'M' : 'L') + point.x.toFixed(1) + ' ' + point.y.toFixed(1);
    }).join(' ');
    var area = line + ' L ' + points[points.length - 1].x.toFixed(1) + ' ' + (height - padding).toFixed(1)
      + ' L ' + points[0].x.toFixed(1) + ' ' + (height - padding).toFixed(1) + ' Z';
    var baselineLine = '';
    if (baseline) {
      var by = padding + (1 - (baseline - minValue) / range) * innerH;
      baselineLine = '<line class="baseline-line" x1="' + padding + '" x2="' + (width - padding) + '" y1="' + by.toFixed(1) + '" y2="' + by.toFixed(1) + '"></line>';
    }

    var circles = points.map(function(point, index) {
      return '<circle cx="' + point.x.toFixed(1) + '" cy="' + point.y.toFixed(1) + '" r="' + (withAxis ? 3 : 2) + '"><title>Run ' + (index + 1) + ': ' + fmtMs(point.value) + '</title></circle>';
    }).join('');

    var axis = withAxis
      ? '<text class="axis-label" x="' + padding + '" y="14">' + fmtMs(maxValue) + '</text>'
        + '<text class="axis-label" x="' + padding + '" y="' + (height - 4) + '">' + fmtMs(minValue) + '</text>'
      : '';

    return '<svg class="trend-svg" viewBox="0 0 ' + width + ' ' + height + '" role="img" aria-label="Benchmark trend">'
      + axis
      + '<path class="trend-area" d="' + area + '"></path>'
      + baselineLine
      + '<path class="trend-line" d="' + line + '"></path>'
      + circles
      + '</svg>';
  }

  function summaryCard(card) {
    return '<article class="summary-card ' + card.tone + '">'
      + '<div class="value">' + esc(card.value) + '</div>'
      + '<div class="label">' + esc(card.label) + '</div>'
      + '<div class="summary-meta">' + esc(card.meta || '') + '</div>'
      + '</article>';
  }

  function overviewRow(label, value, meta, tone) {
    return '<div class="overview-row">'
      + '<div><span class="overview-label">' + esc(label) + '</span><strong>' + esc(value) + '</strong></div>'
      + '<span class="overview-key ' + tone + '">' + esc(meta || '-') + '</span>'
      + '</div>';
  }

  function shortKey(item) {
    if (!item) return '-';
    return item.name ? item.fid + ' / ' + item.name : item.key || '-';
  }

  function scoreClass(score) {
    if (score >= 90) return 'ok';
    if (score >= 70) return 'warn';
    return 'bad';
  }

  function scoreStatus(score) {
    if (score >= 95) return 'Healthy';
    if (score >= 90) return 'Watch small drift';
    if (score >= 70) return 'Needs review';
    return 'Regression risk';
  }

  function deltaClass(delta) {
    if (delta === null || Math.abs(delta) < 0.1) return 'neutral';
    return delta > 0 ? 'bad' : 'good';
  }

  function deltaLabel(delta) {
    return delta === null ? '-' : signed(delta, 1) + '%';
  }

  function referenceHtml(item) {
    if (item.reference === null) return '<span class="muted">-</span>';
    var label = item.referenceKind === 'previous' ? 'previous' : 'baseline';
    return '<span class="reference-value">' + fmtMs(item.reference) + '</span>'
      + '<span class="reference-kind">' + label + '</span>';
  }

  function signed(value, digits) {
    if (value > 0) return '+' + value.toFixed(digits);
    if (value < 0) return value.toFixed(digits);
    return '0.' + ''.padEnd(digits, '0');
  }

  function fmtMs(value) {
    value = number(value);
    if (value >= 1000) return (value / 1000).toFixed(2) + 's';
    if (value < 10) return value.toFixed(1) + 'ms';
    return value.toFixed(0) + 'ms';
  }

  function fmtDate(value) {
    var date = new Date(value);
    if (Number.isNaN(date.getTime())) return value;
    return date.toLocaleString(undefined, {
      year: 'numeric',
      month: 'short',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    });
  }

  function filterText() {
    return (refs.filter.value || '').trim().toLowerCase();
  }

  function applyTheme() {
    if (theme === 'auto') {
      var dark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      document.documentElement.setAttribute('data-theme', dark ? 'dark' : 'light');
    } else {
      document.documentElement.setAttribute('data-theme', theme);
    }
  }

  function updateThemeButton() {
    refs.themeToggle.textContent = theme === 'auto' ? 'Auto' : theme === 'dark' ? 'Dark' : 'Light';
    refs.themeToggle.title = 'Theme: ' + theme;
  }

  function number(value, fallback) {
    var n = typeof value === 'number' ? value : parseFloat(value);
    return Number.isFinite(n) ? n : (fallback === undefined ? 0 : fallback);
  }

  function referenceNumber(value) {
    if (value === null || value === undefined) return null;
    var n = number(value, NaN);
    return Number.isFinite(n) ? n : null;
  }

  function byId(id) {
    return document.getElementById(id);
  }

  function esc(value) {
    return String(value === null || value === undefined ? '' : value)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }
})();
