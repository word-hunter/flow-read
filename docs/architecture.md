# Flow Read Architecture

> @source lib/main.dart lib/app/app_providers.dart lib/storage/hive_storage.dart

Last updated: 2026-06-03

## 分层架构

```
┌──────────────────────────────────────────────────┐
│  UI Layer: screens/ + pages/ + widgets/           │
│  (Material 3, Provider consumers)                 │
├──────────────────────────────────────────────────┤
│  State Layer: providers/                          │
│  (ChangeNotifier × 3: Reading + RSS + Settings)   │
├──────────────────────────────────────────────────┤
│  Service Layer: services/                         │
│  (Stateless services, abstract adapters)          │
├──────────────────────────────────────────────────┤
│  Model Layer: models/                             │
│  (Hive-annotated data classes + value objects)    │
├──────────────────────────────────────────────────┤
│  Storage Layer: storage/                          │
│  (Hive boxes, repositories, migrations)           │
└──────────────────────────────────────────────────┘
```

## 核心设计原则

1. **阅读器优先**：EPUB 阅读、搜索、图片渲染不依赖词汇标注、AI、RSS 或备份
2. **Provider 单总线**：`ReadingProvider` 是核心状态中枢，但不新增 AI 状态
3. **抽象接口 + 多实现**：词典（4 个 source adapter）、语言模块（LanguageModule）、发音服务
4. **Hive 按语言分区**：schema v2，box 名含语言后缀（`user_vocabulary_en`）
5. **手动 DI**：无框架，`AppProviders` 通过 `MultiProvider` 组装依赖

## 启动流程

```
main()
  → runZonedGuarded (AppLogger)
  → bootstrapStorage()           // Hive.init, registerAdapters, openBoxes, runMigrations
  → AppProviders (MultiProvider) // 创建 SettingsService → BackupService → ReadingProvider → RssProvider
  → FlowReadApp                 // MaterialApp.router, theme, global shortcuts
  → HomeScreen                  // 首屏：书架 + 侧栏
```

## 关键入口

| 入口 | 文件 | 作用 |
|------|------|------|
| `main.dart:main()` | `lib/main.dart` | 应用入口，bootstrap + 路由 |
| `app_providers.dart` | `lib/app/app_providers.dart` | 依赖装配 |
| `hive_storage.dart:bootstrapStorage()` | `lib/storage/hive_storage.dart` | Hive 初始化 |
| `reading_provider.dart:init()` | `lib/providers/reading_provider.dart` | 恢复上次阅读状态 |

## 路由结构

```
/                          → HomeScreen
/settings                  → SettingsScreen
/dashboard                 → DashboardScreen
/syntax                    → SyntaxScreen
/practice                  → PracticeScreen
/review                    → ReviewScreen
/spaced-review             → SpacedReviewScreen

内部导航（非命名路由）:
HomeScreen → ReadingDeskScreen → ReaderPage（正文）
         → RssScreen → RssArticleDetailScreen
         → VocabularyScreen
         → BookshelfScreen
         → ProfileScreen / DiscoverScreen
```

## 主题系统

- `AppThemeId` 枚举：classic / ocean / forest / highContrast
- `MaterialApp` theme/darkTheme 由 `SettingsService.themeMode` 控制
- `ReaderThemeTokens` 扩展 Material ThemeData（reader 专用颜色/宽度）
- 动画 220ms easeOutCubic

## 平台适配

| 平台 | 状态 | 特殊能力 |
|------|------|----------|
| macOS | stable | 原生菜单、AppUpdateInstaller、MacPermissionDiagnostics、Bookmark 文件夹访问 |
| iPad | experimental | ios/ 工程存在，导入/阅读闭环可用，布局待适配 |
| iPhone | 兼容性 | 不崩溃即可，非完整支持 |
| Windows | 未评估 | — |
| Linux | out of scope | — |
