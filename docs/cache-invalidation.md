# Flow Read Cache Invalidation

> @source lib/services/book_cache.dart packages/flow_dictionary/lib/src/dictionary_cache_service.dart packages/flow_ai/lib/src/ai_cache_service.dart packages/flow_rss/lib/src/ lib/services/reading_search_service.dart

Last updated: 2026-06-14

## 目标

明确各缓存的失效条件和生命周期，避免数据过期或缓存膨胀。

## 缓存清单

| 缓存 | 存储位置 | 容量限制 | 失效条件 |
|------|---------|---------|---------|
| 词典查询结果 | Drift `dictionary_cache` | 500 条（LRU 淘汰） | 手动清除 / 来源设置变更 |
| 可视化词典结果 | Drift `dictionary_cache` (source: `visual_dictionary:v1`) | 同上 | 同上；空结果标记为 `__empty__` 防止重复查询 |
| AI 章节摘要 | 文件缓存 (`AICacheService`) | 无上限 | contentHash 变更 / promptVersion 变更 / 语言变更 |
| AI 文本分析 | 文件缓存 (`AICacheService`) | 无上限 | 同上 |
| AI 单词分析 | 文件缓存 (`AICacheService`) | 无上限 | 同上 |
| 书籍难度 | 运行时内存 | 按书 | 书籍重新解析时失效 |
| Tokenization | 运行时内存 | 按章节 | 切换章节时释放上一章 |
| 全文搜索索引 | 无持久化（按需计算） | — | 每次搜索重新计算 |
| RSS 文章列表 | Drift `rss_articles` | 按订阅源保留最近文章 | 手动刷新 / 定时刷新覆盖 |
| 书籍封面 | 内存 + 文件系统 | 按书 | 书籍删除时清理 |
| EPUB 解析结果 | 运行时内存 (`BookCache`) | 当前打开的书 | 关闭书籍时释放 |

## 失效规则

### 词典缓存

- **写入**：每次成功查询后写入，key = `{source}:{word}:{languageCode}`
- **淘汰**：超过 500 条时按 LRU 淘汰最旧记录
- **主动失效**：用户更改词典来源设置时，相关 source 的缓存可选清除
- **空结果**：可视化词典空结果存为 `__empty__` 标记，避免重复网络请求

### AI 缓存

- **Key 组成**：`{capability}_{contentHash}_{promptVersion}_{sourceLanguage}_{outputLanguage}`
- **自动失效**：内容 hash 变更（如编辑器修改章节）、prompt 模板版本升级、语言设置变更
- **手动失效**：用户可从 AI 面板触发重新生成（忽略缓存）
- **无 TTL**：AI 缓存不设时间过期，仅基于内容和版本失效

### RSS 缓存

- **文章持久化**：已读/收藏/稍后读标记持久化到 Drift
- **内容刷新**：手动刷新或进入 RSS 页面时触发
- **文章清理**：当前不自动清理旧文章

### 书籍运行时缓存

- **BookCache**：缓存当前打开书籍的解析结果（章节、token、图片）
- **失效**：关闭书籍 (`closeBook()`) 时释放
- **难度缓存**：`BookDifficulty` 按书计算后缓存，书籍重新导入时失效

### Tokenization

- **范围**：当前章节的 token 流
- **失效**：切换章节时上一章的 token 被释放
- **重建**：进入章节时按需 tokenize

## 缓存健康指标

| 指标 | 获取方式 |
|------|---------|
| 词典缓存条目数 | `DictionaryCacheService.count()` |
| 词典缓存命中率 | 查询时统计 hit/miss |
| AI 缓存命中 | `AICacheService.load()` 返回非 null |
| RSS 文章总数 | Drift 查询 `rss_articles` count |

## 清理操作

| 操作 | 入口 | 影响 |
|------|------|------|
| 清除词典缓存 | Settings → 词典 → 清除缓存 | 清空 `dictionary_cache` 表 |
| 重置 AI 缓存 | 无 UI 入口（需手动删除缓存目录） | 所有 AI 结果需重新生成 |
| 清除 RSS 数据 | 取消订阅 | 删除对应订阅的文章 |
| 诊断导出 | Settings → 导出诊断 | 只读，不修改缓存 |
