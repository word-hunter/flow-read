# Flow Read Architecture

> @source lib/main.dart lib/platform/flow_shell_resolver.dart lib/providers/ lib/storage/hive_storage.dart packages/flow_design_system/lib/theme/flow_theme.dart

Last updated: 2026-06-10

## 分层架构

```
┌──────────────────────────────────────────────────┐
│  UI Layer: screens/ + pages/ + widgets/           │
│  (platform shell components, Riverpod consumers)  │
├──────────────────────────────────────────────────┤
│  State Layer: providers/                          │
│  (Riverpod providers + transitional ChangeNotifiers) │
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
2. **Riverpod 入口**：UI 通过 Riverpod facade 消费阅读、设置、备份和 RSS 状态
3. **抽象接口 + 多实现**：词典（4 个 source adapter）、语言模块（LanguageModule）、发音服务
4. **Hive 按语言分区**：schema v2，box 名含语言后缀（`user_vocabulary_en`）
5. **显式 Provider 声明**：依赖通过 `lib/providers/` 中的 Riverpod provider 声明

## 启动流程

```
main()
  → runZonedGuarded (AppLogger)
  → bootstrapStorage()           // Hive.init, registerAdapters, openBoxes, runMigrations
  → ProviderScope                // Riverpod root
  → FlowReadApp                  // MaterialApp, theme, global shortcuts
  → HomeScreen                  // 首屏：书架 + 侧栏
```

## 关键入口

| 入口 | 文件 | 作用 |
|------|------|------|
| `main.dart:main()` | `lib/main.dart` | 应用入口，bootstrap + 路由 |
| `providers/` | `lib/providers/` | Riverpod provider 声明与过渡 facade |
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
- `FlowShellResolver` 按 Flutter `TargetPlatform` 选择设计系统 shell：Android=Material 3、iOS=Cupertino、macOS=HIG、Windows=Fluent
- Linux 当前显式走 `macosStandard` 桌面 shell 规范，避免 fallback 到 Android Material
- `ReaderThemeTokens` 扩展 Material ThemeData（reader 专用颜色/宽度）
- `packages/flow_read_atmosphere` 提供 V2 City 时间主题与动态氛围背景，由 `MaterialApp.builder` 包到 app shell，Home/Reader 在 scope 内透出背景
- 动画 220ms easeOutCubic

## 平台适配

| 平台 | 状态 | 特殊能力 |
|------|------|----------|
| macOS | stable | 原生菜单、AppUpdateInstaller、MacPermissionDiagnostics、Bookmark 文件夹访问 |
| iPad | experimental | ios/ 工程存在，导入/阅读闭环可用，布局待适配 |
| iPhone | 兼容性 | 不崩溃即可，非完整支持 |
| Windows | experimental | Dart UI 走 `WindowsShell` Fluent token；原生打包、CI、安装器仍未纳入正式发布 |
| Linux | experimental | Dart UI 显式走 `macosStandard` 桌面 shell token；原生工程、CI、打包仍未纳入正式发布 |
