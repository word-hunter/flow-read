import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../models/reading_memory.dart';
import '../../storage/database/dao/reading_memory_dao.dart';
import 'reading_memory_inspector_service.dart';

final class ReadingMemoryInspectorWebLauncher {
  const ReadingMemoryInspectorWebLauncher._();

  static ReadingMemoryInspectorWebServer? _activeServer;

  static Future<Uri> open({
    required ReadingMemoryDao dao,
    required String languageCode,
  }) async {
    final server =
        _activeServer ??
        ReadingMemoryInspectorWebServer(
          dao: dao,
          languageCode: languageCode,
        );
    _activeServer = server;
    server.updateContext(dao: dao, languageCode: languageCode);
    return server.start();
  }

  static Future<void> closeActive() async {
    await _activeServer?.close();
    _activeServer = null;
  }
}

final class ReadingMemoryInspectorWebServer {
  ReadingMemoryInspectorWebServer({
    required ReadingMemoryDao dao,
    required String languageCode,
  }) : _dao = dao,
       _languageCode = languageCode;

  ReadingMemoryDao _dao;
  String _languageCode;
  HttpServer? _server;

  bool get isRunning => _server != null;

  void updateContext({
    required ReadingMemoryDao dao,
    required String languageCode,
  }) {
    _dao = dao;
    _languageCode = languageCode;
  }

  Future<Uri> start() async {
    final existing = _server;
    if (existing != null) return _uriFor(existing);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    unawaited(_serve(server));
    return _uriFor(server);
  }

  Future<void> close() async {
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }

  Uri _uriFor(HttpServer server) {
    return Uri(
      scheme: 'http',
      host: InternetAddress.loopbackIPv4.address,
      port: server.port,
    );
  }

  Future<void> _serve(HttpServer server) async {
    await for (final request in server) {
      unawaited(_handle(request));
    }
  }

  Future<void> _handle(HttpRequest request) async {
    if (request.method == 'OPTIONS') {
      _setCorsHeaders(request.response);
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }

    try {
      final path = request.uri.path;
      if (path == '/' || path == '/index.html') {
        await _writeHtml(request);
        return;
      }
      if (path == '/api/overview') {
        await _writeJson(request, await _overviewJson(request));
        return;
      }
      if (path == '/api/health') {
        await _writeJson(request, await _healthJson(request));
        return;
      }
      if (path == '/api/health-detail') {
        await _writeJson(request, await _healthDetailJson(request));
        return;
      }
      if (path == '/api/entities') {
        await _writeJson(request, await _entitiesJson(request));
        return;
      }
      if (path == '/api/entity') {
        await _writeJson(request, await _entityDetailJson(request));
        return;
      }
      if (path == '/api/sources') {
        await _writeJson(request, await _sourcesJson(request));
        return;
      }
      if (path == '/api/source') {
        await _writeJson(request, await _sourceDetailJson(request));
        return;
      }
      if (path == '/api/evidences') {
        await _writeJson(request, await _evidencesJson(request));
        return;
      }
      if (path == '/api/events') {
        await _writeJson(request, await _eventsJson(request));
        return;
      }

      await _writeJson(
        request,
        {'error': 'not_found', 'path': path},
        statusCode: HttpStatus.notFound,
      );
    } catch (error) {
      await _writeJson(
        request,
        {'error': 'internal_error', 'message': error.toString()},
        statusCode: HttpStatus.internalServerError,
      );
    }
  }

  ReadingMemoryInspectorService get _service {
    return ReadingMemoryInspectorService(
      dao: _dao,
      languageCode: _languageCode,
    );
  }

  String _language(HttpRequest request) {
    final requested = _textQuery(request, 'language');
    return requested ?? _languageCode;
  }

  Future<Map<String, Object?>> _overviewJson(HttpRequest request) async {
    final overview = await _service.overview(languageCode: _language(request));
    return {
      'languageCode': overview.languageCode,
      'counts': {
        'sources': overview.sourceCount,
        'entities': overview.entityCount,
        'explanations': overview.explanationCount,
        'evidences': overview.evidenceCount,
        'events': overview.eventCount,
        'reviewCandidates': overview.reviewCandidateCount,
      },
      'distributions': {
        'entityTypes': _countMap(
          overview.entityCountsByType,
          (value) => value.storageValue,
        ),
        'masteryStates': _countMap(
          overview.entityCountsByMastery,
          (value) => value.storageValue,
        ),
        'eventTypes': _countMap(
          overview.eventCountsByType,
          (value) => value.storageValue,
        ),
        'sourceAvailability': _countMap(
          overview.sourceCountsByAvailability,
          (value) => value.storageValue,
        ),
      },
    };
  }

  Future<Map<String, Object?>> _healthJson(HttpRequest request) async {
    final checks = await _service.healthChecks(
      languageCode: _language(request),
    );
    return {
      'languageCode': _language(request),
      'rows': checks.map(_healthCheckToJson).toList(growable: false),
    };
  }

  Future<Map<String, Object?>> _healthDetailJson(HttpRequest request) async {
    final code = _textQuery(request, 'code');
    if (code == null) return {'detail': null};
    final detail = await _service.healthCheckDetail(
      code,
      languageCode: _language(request),
    );
    return {'detail': detail == null ? null : _healthCheckDetailToJson(detail)};
  }

  Future<Map<String, Object?>> _entitiesJson(HttpRequest request) async {
    final rows = await _service.entities(
      type: _enumQuery(
        request,
        'type',
        KnowledgeEntityType.values,
        (value) => value.storageValue,
      ),
      masteryState: _enumQuery(
        request,
        'mastery',
        KnowledgeMasteryState.values,
        (value) => value.storageValue,
      ),
      query: _textQuery(request, 'query'),
      limit: _intQuery(
        request,
        'limit',
        ReadingMemoryInspectorService.maxLimit,
      ),
      offset: _intQuery(request, 'offset', 0),
      languageCode: _language(request),
    );
    return {
      'languageCode': _language(request),
      'rows': rows.map(_entityToJson).toList(growable: false),
    };
  }

  Future<Map<String, Object?>> _entityDetailJson(HttpRequest request) async {
    final id = _textQuery(request, 'id');
    if (id == null) return {'detail': null};
    final detail = await _service.entityDetail(id);
    return {'detail': detail == null ? null : _entityDetailToJson(detail)};
  }

  Future<Map<String, Object?>> _sourcesJson(HttpRequest request) async {
    final rows = await _service.sources(
      sourceKind: _enumQuery(
        request,
        'kind',
        SourceKind.values,
        (value) => value.storageValue,
      ),
      availability: _enumQuery(
        request,
        'availability',
        SourceAvailability.values,
        (value) => value.storageValue,
      ),
      query: _textQuery(request, 'query'),
      limit: _intQuery(
        request,
        'limit',
        ReadingMemoryInspectorService.maxLimit,
      ),
      offset: _intQuery(request, 'offset', 0),
      languageCode: _language(request),
    );
    return {
      'languageCode': _language(request),
      'rows': rows.map(_sourceToJson).toList(growable: false),
    };
  }

  Future<Map<String, Object?>> _sourceDetailJson(HttpRequest request) async {
    final id = _textQuery(request, 'id');
    if (id == null) return {'detail': null};
    final detail = await _service.sourceDetail(
      id,
      languageCode: _language(request),
    );
    return {'detail': detail == null ? null : _sourceDetailToJson(detail)};
  }

  Future<Map<String, Object?>> _evidencesJson(HttpRequest request) async {
    final rows = await _service.evidences(
      sourceKind: _enumQuery(
        request,
        'sourceKind',
        SourceKind.values,
        (value) => value.storageValue,
      ),
      sourceAvailability: _enumQuery(
        request,
        'sourceAvailability',
        SourceAvailability.values,
        (value) => value.storageValue,
      ),
      query: _textQuery(request, 'query'),
      limit: _intQuery(
        request,
        'limit',
        ReadingMemoryInspectorService.maxLimit,
      ),
      offset: _intQuery(request, 'offset', 0),
      languageCode: _language(request),
    );
    return {
      'languageCode': _language(request),
      'rows': rows.map(_evidenceToJson).toList(growable: false),
    };
  }

  Future<Map<String, Object?>> _eventsJson(HttpRequest request) async {
    final rows = await _service.events(
      type: _enumQuery(
        request,
        'type',
        MemoryEventType.values,
        (value) => value.storageValue,
      ),
      query: _textQuery(request, 'query'),
      limit: _intQuery(
        request,
        'limit',
        ReadingMemoryInspectorService.maxLimit,
      ),
      offset: _intQuery(request, 'offset', 0),
      languageCode: _language(request),
    );
    return {
      'languageCode': _language(request),
      'rows': rows.map(_eventToJson).toList(growable: false),
    };
  }

  static String? _textQuery(HttpRequest request, String key) {
    final value = request.uri.queryParameters[key]?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  static int _intQuery(HttpRequest request, String key, int fallback) {
    final value = int.tryParse(request.uri.queryParameters[key] ?? '');
    if (value == null) return fallback;
    return value;
  }

  static T? _enumQuery<T>(
    HttpRequest request,
    String key,
    Iterable<T> values,
    String Function(T value) storageValue,
  ) {
    final raw = _textQuery(request, key);
    if (raw == null) return null;
    for (final value in values) {
      if (storageValue(value) == raw) return value;
    }
    return null;
  }

  static Map<String, int> _countMap<T>(
    Map<T, int> values,
    String Function(T value) keyOf,
  ) {
    return {for (final entry in values.entries) keyOf(entry.key): entry.value};
  }

  static Map<String, Object?> _sourceToJson(MemorySourceRecord value) {
    return {
      'id': value.id,
      'sourceKind': value.sourceKind.storageValue,
      'titleSnapshot': value.titleSnapshot,
      'authorSnapshot': value.authorSnapshot,
      'languageCode': value.languageCode,
      'fingerprint': value.fingerprint,
      'availability': value.availability.storageValue,
      'createdAt': _date(value.createdAt),
      'updatedAt': _date(value.updatedAt),
      'deletedAt': _date(value.deletedAt),
    };
  }

  static Map<String, Object?> _entityToJson(MemoryKnowledgeEntity value) {
    return {
      'id': value.id,
      'languageCode': value.languageCode,
      'type': value.type.storageValue,
      'canonicalKey': value.canonicalKey,
      'displayText': value.displayText,
      'normalizedText': value.normalizedText,
      'masteryState': value.masteryState.storageValue,
      'confidence': value.confidence,
      'createdAt': _date(value.createdAt),
      'updatedAt': _date(value.updatedAt),
      'lastAccessedAt': _date(value.lastAccessedAt),
    };
  }

  static Map<String, Object?> _explanationToJson(
    MemoryKnowledgeExplanation value,
  ) {
    return {
      'id': value.id,
      'entityId': value.entityId,
      'explanation': value.explanation,
      'source': value.source.storageValue,
      'targetLanguage': value.targetLanguage,
      'promptVersion': value.promptVersion,
      'createdAt': _date(value.createdAt),
      'updatedAt': _date(value.updatedAt),
    };
  }

  static Map<String, Object?> _evidenceToJson(MemoryKnowledgeEvidence value) {
    return {
      'id': value.id,
      'entityId': value.entityId,
      'sourceId': value.sourceId,
      'sourceKind': value.sourceKind.storageValue,
      'bookId': value.bookId,
      'chapterIndex': value.chapterIndex,
      'locationLocator': value.locationLocator,
      'shortExcerpt': value.shortExcerpt,
      'excerptHash': value.excerptHash,
      'sourceTitleSnapshot': value.sourceTitleSnapshot,
      'sourceAvailability': value.sourceAvailability.storageValue,
      'retentionPolicy': value.retentionPolicy.storageValue,
      'createdAt': _date(value.createdAt),
    };
  }

  static Map<String, Object?> _eventToJson(MemoryEvent value) {
    return {
      'id': value.id,
      'type': value.type.storageValue,
      'languageCode': value.languageCode,
      'sourceId': value.sourceId,
      'entityId': value.entityId,
      'targetText': value.targetText,
      'canonicalKey': value.canonicalKey,
      'sourceRefJson': value.sourceRefJson,
      'metadataJson': value.metadataJson,
      'createdAt': _date(value.createdAt),
    };
  }

  static Map<String, Object?> _reviewCandidateToJson(ReviewCandidate value) {
    return {
      'id': value.id,
      'entityId': value.entityId,
      'entityType': value.entityType.storageValue,
      'targetText': value.targetText,
      'explanationId': value.explanationId,
      'evidenceId': value.evidenceId,
      'suggestedQuestionType': value.suggestedQuestionType,
      'priority': value.priority,
      'status': value.status.storageValue,
      'createdAt': _date(value.createdAt),
      'updatedAt': _date(value.updatedAt),
    };
  }

  static Map<String, Object?> _healthCheckToJson(
    ReadingMemoryHealthCheck value,
  ) {
    return {
      'code': value.code,
      'title': value.title,
      'description': value.description,
      'count': value.count,
      'sampleIds': value.sampleIds,
      'hasIssues': value.hasIssues,
    };
  }

  static Map<String, Object?> _healthIssueToJson(
    ReadingMemoryHealthIssue value,
  ) {
    return {
      'recordKind': value.recordKind,
      'recordId': value.recordId,
      'summary': value.summary,
      'fields': value.fields,
    };
  }

  static Map<String, Object?> _entityDetailToJson(
    ReadingMemoryEntityDetail value,
  ) {
    return {
      'entity': _entityToJson(value.entity),
      'explanations': value.explanations
          .map(_explanationToJson)
          .toList(growable: false),
      'evidences': value.evidences.map(_evidenceToJson).toList(growable: false),
      'recentEvents': value.recentEvents
          .map(_eventToJson)
          .toList(growable: false),
      'reviewCandidates': value.reviewCandidates
          .map(_reviewCandidateToJson)
          .toList(growable: false),
    };
  }

  static Map<String, Object?> _sourceDetailToJson(
    ReadingMemorySourceDetail value,
  ) {
    return {
      'source': _sourceToJson(value.source),
      'entities': value.entities.map(_entityToJson).toList(growable: false),
      'evidences': value.evidences.map(_evidenceToJson).toList(growable: false),
      'recentEvents': value.recentEvents
          .map(_eventToJson)
          .toList(growable: false),
    };
  }

  static Map<String, Object?> _healthCheckDetailToJson(
    ReadingMemoryHealthCheckDetail value,
  ) {
    return {
      'check': _healthCheckToJson(value.check),
      'issues': value.issues.map(_healthIssueToJson).toList(growable: false),
    };
  }

  static String? _date(DateTime? value) => value?.toIso8601String();

  static Future<void> _writeHtml(HttpRequest request) async {
    final response = request.response;
    _setCorsHeaders(response);
    response.headers.contentType = ContentType(
      'text',
      'html',
      charset: 'utf-8',
    );
    response.write(_inspectorHtml);
    await response.close();
  }

  static Future<void> _writeJson(
    HttpRequest request,
    Object? body, {
    int statusCode = HttpStatus.ok,
  }) async {
    final response = request.response;
    _setCorsHeaders(response);
    response.statusCode = statusCode;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
    await response.close();
  }

  static void _setCorsHeaders(HttpResponse response) {
    response.headers.set('Access-Control-Allow-Origin', '*');
    response.headers.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
    response.headers.set('Access-Control-Allow-Headers', 'Content-Type');
  }
}

const _inspectorHtml = r'''
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Reading Memory Inspector</title>
  <style>
    :root {
      color-scheme: light;
      --bg: #f6f7f4;
      --surface: #fffefa;
      --surface-2: #eef5f0;
      --line: #d7ddd8;
      --text: #1f2522;
      --muted: #637068;
      --accent: #2d6f5f;
      --accent-2: #8a5a13;
      --danger: #a23932;
      --shadow: 0 10px 28px rgba(31, 37, 34, .08);
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: var(--bg);
      color: var(--text);
    }
    header {
      position: sticky;
      top: 0;
      z-index: 4;
      display: grid;
      grid-template-columns: minmax(0, 1fr) auto;
      gap: 16px;
      align-items: center;
      padding: 18px 24px 14px;
      background: rgba(255, 254, 250, .92);
      border-bottom: 1px solid var(--line);
      backdrop-filter: blur(16px);
    }
    h1 {
      margin: 0;
      font-size: 20px;
      line-height: 1.2;
      font-weight: 720;
      letter-spacing: 0;
    }
    .subhead {
      margin-top: 4px;
      color: var(--muted);
      font-size: 13px;
    }
    button, input, select {
      font: inherit;
      letter-spacing: 0;
    }
    button {
      border: 1px solid var(--line);
      border-radius: 8px;
      background: var(--surface);
      color: var(--text);
      min-height: 36px;
      padding: 7px 12px;
      cursor: pointer;
    }
    button:hover { border-color: var(--accent); }
    button.active {
      color: white;
      background: var(--accent);
      border-color: var(--accent);
    }
    input, select {
      min-height: 36px;
      border: 1px solid var(--line);
      border-radius: 8px;
      background: white;
      color: var(--text);
      padding: 7px 10px;
    }
    main {
      display: grid;
      grid-template-columns: minmax(0, 1fr) minmax(320px, 390px);
      gap: 18px;
      padding: 18px 24px 24px;
    }
    nav {
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
    }
    .toolbar {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      align-items: center;
      margin-bottom: 12px;
    }
    .toolbar input { min-width: min(360px, 100%); }
    .panel, aside {
      background: var(--surface);
      border: 1px solid var(--line);
      border-radius: 8px;
      box-shadow: var(--shadow);
    }
    .panel {
      min-width: 0;
      padding: 16px;
    }
    aside {
      position: sticky;
      top: 88px;
      max-height: calc(100vh - 112px);
      overflow: auto;
      padding: 16px;
    }
    .metric-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
      gap: 12px;
    }
    .metric {
      border: 1px solid var(--line);
      border-radius: 8px;
      padding: 14px;
      background: white;
    }
    .metric strong {
      display: block;
      margin-top: 6px;
      font-size: 24px;
    }
    .section-title {
      margin: 20px 0 10px;
      font-size: 15px;
      font-weight: 720;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      table-layout: fixed;
      background: white;
      border: 1px solid var(--line);
      border-radius: 8px;
      overflow: hidden;
    }
    th, td {
      padding: 10px 12px;
      border-bottom: 1px solid var(--line);
      text-align: left;
      vertical-align: top;
      font-size: 13px;
      overflow-wrap: anywhere;
    }
    th {
      color: var(--muted);
      background: var(--surface-2);
      font-weight: 650;
    }
    tr:last-child td { border-bottom: 0; }
    tbody tr.clickable { cursor: pointer; }
    tbody tr.clickable:hover { background: #f8fbf4; }
    .pill {
      display: inline-flex;
      align-items: center;
      min-height: 24px;
      border-radius: 999px;
      padding: 2px 8px;
      background: var(--surface-2);
      color: var(--muted);
      font-size: 12px;
      max-width: 100%;
      overflow-wrap: anywhere;
    }
    .issue { color: var(--danger); }
    .ok { color: var(--accent); }
    .empty {
      padding: 28px;
      color: var(--muted);
      text-align: center;
      border: 1px dashed var(--line);
      border-radius: 8px;
      background: white;
    }
    pre {
      margin: 0;
      white-space: pre-wrap;
      overflow-wrap: anywhere;
      font-size: 12px;
      line-height: 1.55;
      color: #26312c;
    }
    .error {
      color: var(--danger);
      background: #fff3f0;
      border: 1px solid #e4b5ad;
      border-radius: 8px;
      padding: 12px;
    }
    @media (max-width: 900px) {
      header { grid-template-columns: 1fr; }
      main { grid-template-columns: 1fr; padding: 14px; }
      aside { position: static; max-height: none; }
    }
  </style>
</head>
<body>
  <header>
    <div>
      <h1>Reading Memory Inspector</h1>
      <div class="subhead" id="status">Connecting to local inspector...</div>
    </div>
    <nav id="tabs"></nav>
  </header>
  <main>
    <section class="panel">
      <div id="toolbar" class="toolbar"></div>
      <div id="content"></div>
    </section>
    <aside>
      <div class="section-title" style="margin-top:0">Detail</div>
      <div id="detail" class="empty">Select a row to inspect its raw data.</div>
    </aside>
  </main>
  <script>
    const tabs = [
      ['overview', '概览'],
      ['entities', '实体'],
      ['sources', '来源'],
      ['evidences', '证据'],
      ['events', '事件'],
    ];
    const sourceKinds = ['book', 'rss', 'browser', 'manual', 'ai'];
    const availability = ['available', 'archived', 'deleted'];
    const entityTypes = ['word', 'phrase', 'pattern', 'grammar', 'concept', 'character', 'book_term', 'sentence'];
    const masteryStates = ['unknown', 'learning', 'mastered'];
    const eventTypes = ['lookup', 'ai_analyze', 'save_explanation', 'mark_learning', 'mark_known', 'mark_unknown', 'review', 'bookmark'];
    const state = {
      tab: 'overview',
      filters: {
        entities: {},
        sources: {},
        evidences: {},
        events: {},
      },
    };

    function esc(value) {
      return String(value ?? '').replace(/[&<>"']/g, c => ({
        '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
      }[c]));
    }
    function fmt(value) {
      if (!value) return '';
      const date = new Date(value);
      return Number.isNaN(date.valueOf()) ? value : date.toLocaleString();
    }
    function qs(params) {
      const out = new URLSearchParams();
      Object.entries(params || {}).forEach(([key, value]) => {
        if (value !== undefined && value !== null && String(value).trim() !== '') {
          out.set(key, value);
        }
      });
      const text = out.toString();
      return text ? `?${text}` : '';
    }
    async function api(path, params) {
      const response = await fetch(`${path}${qs(params)}`, { cache: 'no-store' });
      const text = await response.text();
      const data = text ? JSON.parse(text) : null;
      if (!response.ok) throw new Error(data?.message || data?.error || response.statusText);
      return data;
    }
    function setStatus(message) {
      document.getElementById('status').textContent = message;
    }
    function renderTabs() {
      document.getElementById('tabs').innerHTML = tabs.map(([id, label]) =>
        `<button class="${state.tab === id ? 'active' : ''}" data-tab="${id}">${label}</button>`
      ).join('');
      document.querySelectorAll('[data-tab]').forEach(button => {
        button.addEventListener('click', () => {
          state.tab = button.dataset.tab;
          document.getElementById('detail').className = 'empty';
          document.getElementById('detail').textContent = 'Select a row to inspect its raw data.';
          load();
        });
      });
    }
    function renderToolbar() {
      const filter = state.filters[state.tab] || {};
      const search = `<input id="query" placeholder="Search" value="${esc(filter.query || '')}">`;
      const select = (id, label, values, current) =>
        `<select id="${id}" aria-label="${label}"><option value="">${label}</option>` +
        values.map(value => `<option value="${value}" ${current === value ? 'selected' : ''}>${value}</option>`).join('') +
        `</select>`;
      let html = '';
      if (state.tab === 'entities') {
        html = search + select('type', 'type', entityTypes, filter.type) + select('mastery', 'mastery', masteryStates, filter.mastery);
      } else if (state.tab === 'sources') {
        html = search + select('kind', 'kind', sourceKinds, filter.kind) + select('availability', 'availability', availability, filter.availability);
      } else if (state.tab === 'evidences') {
        html = search + select('sourceKind', 'source kind', sourceKinds, filter.sourceKind) + select('sourceAvailability', 'source availability', availability, filter.sourceAvailability);
      } else if (state.tab === 'events') {
        html = search + select('type', 'type', eventTypes, filter.type);
      }
      html += `<button id="refresh">刷新</button>`;
      document.getElementById('toolbar').innerHTML = html;
      const query = document.getElementById('query');
      if (query) {
        query.addEventListener('keydown', event => {
          if (event.key === 'Enter') applyFilters();
        });
      }
      document.getElementById('refresh').addEventListener('click', applyFilters);
    }
    function applyFilters() {
      const filter = {};
      ['query', 'type', 'mastery', 'kind', 'availability', 'sourceKind', 'sourceAvailability'].forEach(id => {
        const element = document.getElementById(id);
        if (element && element.value) filter[id] = element.value;
      });
      if (state.tab !== 'overview') state.filters[state.tab] = filter;
      load();
    }
    function table(headers, rows) {
      if (!rows.length) return '<div class="empty">No rows.</div>';
      return `<table><thead><tr>${headers.map(header => `<th>${esc(header)}</th>`).join('')}</tr></thead><tbody>${rows.join('')}</tbody></table>`;
    }
    function pill(value, cls = '') {
      return `<span class="pill ${cls}">${esc(value)}</span>`;
    }
    function renderDetail(title, data) {
      document.getElementById('detail').className = '';
      document.getElementById('detail').innerHTML =
        `<div class="section-title" style="margin-top:0">${esc(title)}</div><pre>${esc(JSON.stringify(data, null, 2))}</pre>`;
    }
    async function showEntity(id) {
      const data = await api('/api/entity', { id });
      renderDetail(id, data.detail || {});
    }
    async function showSource(id) {
      const data = await api('/api/source', { id });
      renderDetail(id, data.detail || {});
    }
    async function showHealth(code) {
      const data = await api('/api/health-detail', { code });
      renderDetail(code, data.detail || {});
    }
    async function renderOverview() {
      const [overview, health] = await Promise.all([api('/api/overview'), api('/api/health')]);
      setStatus(`Language: ${overview.languageCode}`);
      const counts = overview.counts || {};
      const metricLabels = {
        sources: 'Sources',
        entities: 'Entities',
        explanations: 'Explanations',
        evidences: 'Evidence',
        events: 'Events',
        reviewCandidates: 'Review candidates',
      };
      let html = '<div class="metric-grid">';
      html += Object.entries(metricLabels).map(([key, label]) =>
        `<div class="metric"><span>${label}</span><strong>${esc(counts[key] ?? 0)}</strong></div>`
      ).join('');
      html += '</div>';
      const rows = health.rows.map(check =>
        `<tr class="clickable" data-health="${esc(check.code)}"><td>${esc(check.title)}</td><td>${pill(check.count, check.hasIssues ? 'issue' : 'ok')}</td><td>${esc(check.description)}</td><td>${esc((check.sampleIds || []).join(', '))}</td></tr>`
      );
      html += '<div class="section-title">健康检查</div>';
      html += table(['检查项', '数量', '说明', '样本'], rows);
      html += '<div class="section-title">分布</div>';
      html += `<pre>${esc(JSON.stringify(overview.distributions, null, 2))}</pre>`;
      document.getElementById('content').innerHTML = html;
      document.querySelectorAll('[data-health]').forEach(row => row.addEventListener('click', () => showHealth(row.dataset.health)));
    }
    async function renderEntities() {
      const data = await api('/api/entities', state.filters.entities);
      setStatus(`Language: ${data.languageCode} · ${data.rows.length} entities`);
      const rows = data.rows.map(row =>
        `<tr class="clickable" data-entity="${esc(row.id)}"><td>${esc(row.displayText)}</td><td>${pill(row.type)}</td><td>${pill(row.masteryState)}</td><td>${esc(row.canonicalKey)}</td><td>${fmt(row.updatedAt)}</td></tr>`
      );
      document.getElementById('content').innerHTML = table(['Text', 'Type', 'Mastery', 'Canonical', 'Updated'], rows);
      document.querySelectorAll('[data-entity]').forEach(row => row.addEventListener('click', () => showEntity(row.dataset.entity)));
    }
    async function renderSources() {
      const data = await api('/api/sources', state.filters.sources);
      setStatus(`Language: ${data.languageCode} · ${data.rows.length} sources`);
      const rows = data.rows.map(row =>
        `<tr class="clickable" data-source="${esc(row.id)}"><td>${esc(row.titleSnapshot)}</td><td>${pill(row.sourceKind)}</td><td>${pill(row.availability)}</td><td>${esc(row.id)}</td><td>${fmt(row.updatedAt)}</td></tr>`
      );
      document.getElementById('content').innerHTML = table(['Title', 'Kind', 'Availability', 'ID', 'Updated'], rows);
      document.querySelectorAll('[data-source]').forEach(row => row.addEventListener('click', () => showSource(row.dataset.source)));
    }
    async function renderEvidences() {
      const data = await api('/api/evidences', state.filters.evidences);
      setStatus(`Language: ${data.languageCode} · ${data.rows.length} evidence rows`);
      const rows = data.rows.map(row =>
        `<tr><td>${esc(row.shortExcerpt)}</td><td>${esc(row.entityId)}</td><td>${pill(row.sourceKind)}</td><td>${esc(row.sourceTitleSnapshot)}</td><td>${fmt(row.createdAt)}</td></tr>`
      );
      document.getElementById('content').innerHTML = table(['Excerpt', 'Entity', 'Kind', 'Source', 'Created'], rows);
    }
    async function renderEvents() {
      const data = await api('/api/events', state.filters.events);
      setStatus(`Language: ${data.languageCode} · ${data.rows.length} events`);
      const rows = data.rows.map(row =>
        `<tr><td>${pill(row.type)}</td><td>${esc(row.targetText)}</td><td>${esc(row.entityId || '')}</td><td>${esc(row.sourceId || '')}</td><td>${fmt(row.createdAt)}</td></tr>`
      );
      document.getElementById('content').innerHTML = table(['Type', 'Target', 'Entity', 'Source', 'Created'], rows);
    }
    async function load() {
      renderTabs();
      renderToolbar();
      document.getElementById('content').innerHTML = '<div class="empty">Loading...</div>';
      try {
        if (state.tab === 'overview') await renderOverview();
        if (state.tab === 'entities') await renderEntities();
        if (state.tab === 'sources') await renderSources();
        if (state.tab === 'evidences') await renderEvidences();
        if (state.tab === 'events') await renderEvents();
      } catch (error) {
        document.getElementById('content').innerHTML = `<div class="error">${esc(error.message || error)}</div>`;
        setStatus('Inspector request failed');
      }
    }
    load();
  </script>
</body>
</html>
''';
