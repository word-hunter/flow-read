# Flow Read Widget Tree

> @source lib/screens/ lib/pages/ lib/widgets/

Last updated: 2026-06-14

## 屏幕导航

```
HomeScreen (底部导航 / 宽屏侧栏)
├── Bookshelf (默认 tab)
│   └── BookShelfRow → BookShelfItem → BookCoverView → 进入阅读
├── RSS (实验性功能 tab)
│   └── RssScreen
│       ├── RssFeedSidebar (订阅列表)
│       └── RssArticleList (文章列表，支持筛选)
│           └── 点击 → RssArticleDetailScreen
│               ├── RssArticleBodyView (正文渲染 + 高亮词点词)
│               └── 原文 → BrowserScreen (内部 substrate)
├── Vocabulary (词汇 tab)
│   └── VocabularyScreen (列表 / 卡片视图)
├── Profile (个人 tab)
│   └── ProfileScreen
└── Settings (设置按钮 → 独立页面)
    └── SettingsScreen
        ├── 侧栏导航 (SettingsSection 枚举)
        └── 右侧内容区 (SettingsDictionarySection, _SourceManagerSection 等)
```

## 阅读流程

```
HomeScreen → 点击书籍
  → ReadingDeskScreen (卡片式桌面容器)
    → ReaderPage (正文阅读)
      ├── _buildNavBar (顶部导航栏)
      │   ├── 返回、目录、章节切换、搜索、字体、书签、更多
      │   └── 更多菜单：搜索(窄屏)、前/后目录项、历史书签
      ├── _buildReadingReminder (阅读提醒横幅)
      ├── _buildContent (正文区域)
      │   └── ReaderTextView (EPUB 正文渲染)
      │       ├── _HighlightBuilder (词汇高亮 + 点词)
      │       │   ├── buildTappableWordSpan (学习中/生词)
      │       │   └── buildPlainLookupWordSpan (已掌握/普通词)
      │       └── _EpubImageBlockView (图片自适应)
      └── _buildReaderSidebar (宽屏右侧栏)
          ├── ReaderWordSidebar (词典详情)
          │   ├── DictionaryDetailView (词典正文)
          │   ├── VisualHintCard (可视化释义卡片)
          │   └── _buildLearningStatusSection (学习状态 SegmentedButton)
          └── 未来：AIAssistantPanel (1.7.0)
```

## 词典弹出（窄屏）

```
WordBottomSheet (showModalBottomSheet)
├── DictionaryDetailView.fromProvider
│   ├── 词典释义 (来自 DictionaryManagerService)
│   ├── 构词分析 (来自 CompoundWordAnalyzer)
│   ├── 全书上下文 (来自 WordContextService)
│   └── 导入示例 (来自 WordHunter import)
└── 底部操作区
    ├── SegmentedButton: 已掌握 / 学习中
    └── 清除状态按钮
```

## 词典详情组件（共享）

```
DictionaryDetailView (用于 ReaderWordSidebar + WordBottomSheet + VocabularyScreen)
├── 单词头部 (phonetic, level badge, source badge, 发音按钮)
├── 释义区块 (partOfSpeech chip, 编号释义, 例句)
├── VisualHintCard (Wikidata 可视化释义：缩略图 + 标签 + 描述)
├── 回退区 (compoundAnalysis + bookContexts)
├── 上下文块 (单词在原文中的上下文高亮)
├── 导入示例 (WordHunter examples)
└── 二次查词 (点击释义/例句中的英文词 → lookupRelatedWord)
```

## AI 相关组件

```
AISummaryView (DraggableScrollableSheet)
├── _buildSummaryCoverage (覆盖率: "已生成 3/12 章")
├── _buildAIStatus (状态栏: loading/cacheHit/failed/fallback/generated)
├── _buildPreReading (读前预览)
├── _buildSummaryContent (总结正文)
└── _buildPracticeContent (练习内容)

SelectedTextSheet (选中文本 AI 分析弹窗)
├── 选中文本预览
└── AITextAnalysis 结果渲染

语法分析入口
├── SyntaxScreen (完整句法分解)
├── SyntaxBreakdown (组件渲染)
├── SentenceBreakdown (数据模型)
└── Slot / SlotRole (句法角色)
```

## 关键 Widget 复用矩阵

| 组件 | 复用位置 |
|------|----------|
| `DictionaryDetailView` | ReaderWordSidebar, WordBottomSheet, VocabularyScreen |
| `WordBottomSheet` | ReaderPage, RssArticleBodyView, BrowserScreen, VocabularyScreen |
| `BookCoverView` | HomeScreen 书架, 多本书选择 |
| `FontSettingsSheet` | ReaderPage, RssArticleDetailScreen |
| `TocBottomSheet` | ReaderPage |
| `SelectedTextActionToolbar` | ReaderPage, RssArticleBodyView |
| `EpubDropImporter` | HomeScreen (拖拽导入) |
| `ReleaseNotesGate` | 应用启动后首屏 |
| `BookDifficultyChip` | ReaderPage, 书架项 |
| `PronunciationButton` | DictionaryDetailView |
| `VisualHintCard` | DictionaryDetailView, ReaderWordSidebar |

## 添加新页面 / 组件的约定

1. **页面**放 `lib/screens/`，**可复用组件**放 `lib/widgets/`
2. **阅读器专用组件**放 `lib/widgets/reader/`
3. **RSS 专用组件**放 `lib/widgets/rss/`
4. **设置专用组件**放 `lib/widgets/settings/`
5. **书架/首页组件**放 `lib/widgets/home/`
6. 使用 `context.read<T>()` 获取 provider，`context.watch<T>()` 监听
7. 词典详情统一使用 `DictionaryDetailView.fromProvider`
8. 查词弹窗统一使用 `WordBottomSheet`
9. AI 面板未来统一使用 `AIAssistantPanel`（1.7.0）
