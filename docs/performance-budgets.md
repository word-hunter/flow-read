# Flow Read Performance Budgets

> @source lib/services/epub_parse_worker.dart lib/services/reading_search_service.dart lib/services/backup_service.dart packages/flow_dictionary/lib/src/ packages/flow_rss/lib/src/

Last updated: 2026-06-14

## 目标

为主要长任务建立性能目标和后台/取消策略，确保 UI 不被阻塞。

## 性能预算

| 操作 | 目标耗时 | 执行方式 | 取消支持 |
|------|---------|---------|---------|
| EPUB 解析（<5MB） | < 3s | Isolate (`EpubParseWorker`) | ✓ 任务取消 |
| EPUB 解析（5-50MB） | < 10s | Isolate (`EpubParseWorker`) | ✓ 任务取消 |
| 全文搜索（单章） | < 100ms | 主线程 | — |
| 全文搜索（全书） | < 2s | 主线程，分批 yield | ✓ 新搜索覆盖 |
| RSS 聚合（全部订阅刷新） | < 10s | 异步并发 | ✓ dispose 取消 |
| RSS 单源刷新 | < 3s | 异步 HTTP | ✓ timeout |
| 备份导出 | < 5s（常规数据量） | 异步 ZIP | — |
| 备份导入 | < 10s | 异步解压 + Drift 写入 | — |
| 词典查询（单源） | < 2s | 异步 HTTP | ✓ timeout |
| 词典查询（多源编排） | < 5s | 按优先级串行 + 首成功返回 | ✓ 早期返回 |
| 可视化词典查询 | < 3s | 异步 HTTP (Wikidata) | ✓ 10s timeout |
| AI 生成（章节摘要） | < 30s | 异步 HTTP (LLM) | — |
| AI 文本分析 | < 15s | 异步 HTTP (LLM) | — |

## 后台执行策略

### Isolate 任务

| 任务 | 实现 | 进度回调 |
|------|------|---------|
| EPUB 解析 | `EpubParseWorker` (Isolate.spawn) | ✓ 解析阶段回调 |

### 异步任务（主 Isolate）

以下任务在主 Isolate 的事件循环中执行，通过 `async/await` 保持 UI 响应：

- 备份导出/导入
- RSS 刷新
- 词典查询
- AI API 调用
- 全文搜索

### 取消与超时

| 机制 | 使用场景 |
|------|---------|
| `Completer` + cancel flag | EPUB 解析 |
| HTTP timeout (10s) | 词典在线查询、Wikidata |
| 新请求覆盖旧结果 | 全文搜索、查词 |
| Provider dispose | RSS 刷新 |

## 监测建议

1. EPUB 解析耗时通过 `AppLogger` 记录（解析开始→完成时间差）
2. 词典查询通过 `DictionaryCacheService` 命中率统计 cache hit/miss
3. AI 调用通过 `AIDebugTraceRecorder` 记录耗时（开发环境）
4. 备份导出/导入耗时通过 `BackupService` 日志记录

## 性能回归检测

当前无自动化性能测试。建议：
- EPUB 解析：使用固定测试 EPUB 文件，assert 解析时间 < budget
- 搜索：使用固定章节内容，assert 搜索时间 < 100ms
- 词典缓存命中：mock HTTP，验证缓存路径不触发网络请求
