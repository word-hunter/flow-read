# Changelog

All notable changes to Flow Read are tracked here.

This project follows a simple semantic versioning flow:

- `MAJOR` for incompatible data, storage, or user-facing workflow changes.
- `MINOR` for backward-compatible features and meaningful UX additions.
- `PATCH` for bug fixes, copy changes, and internal improvements.

## [Unreleased]

## [1.7.1] - 2026-06-07

### Fixed

- 修复首页封面和难度标签显示

### Changed

- 更新项目说明和提交规范

## [1.7.0] - 2026-06-07

### 新增 — Unified Reading AI Assistant

- **统一 AI 助手面板**：`AIAssistantPanel` 组件，包含上下文卡片、操作条（解释/翻译/短语/指代/出题/总结/词汇/问答）、类型化结果渲染、追问输入、语言范围指示
- **AI 基础设施**：`AIAssistantController` + `AIActionController` 生命周期管理，`AIAssistantActionRegistry` 动作可用性矩阵，统一上下文快照 `AIContextSnapshot`
- **作品词库**：`BookGlossaryService` 基于 HiveType 12 的 `BookGlossaryEntry` 缓存，支持按书查词、批量写入、备份/导入
- **人物注册表**：`CharacterRegistry` 三层匹配（规范化名称 / 别名 / 用户手动覆盖），按书持久化
- **阅读画像**：`ReadingInsightService` 运行时计算查词密度（每千词查词次数）和重复查询率
- **作品词汇 AI 解释**：`PromptBuilder.buildBookGlossaryExplanation()` 结合当前段落、前文出现位置、人物卡片生成语境解释
- **浏览器 AI 统一**：`browser_screen.dart` 从独立 AI 状态迁移至 `AIAssistantPanel`，删除 ~110 行重复代码

### 新增 — Multilingual Foundation 补齐

- **书籍语言元数据**：`BookMetadata.languageConfidence`、`targetExplanationLanguage` per-book 覆盖
- **结构化 Token**：`ReadingToken` / `TokenizedText` 携带 surface/canonical/languageId/offset
- **词汇状态语言隔离**：`UserVocabularyEntry` + `UserVocabularyKey(languageId, canonical)`，旧数据懒迁移
- **词典来源语言过滤**：`DictionarySourceConfig.supportedLanguages`，Collins/WordNet/Longman 默认 `en`
- **语言设置 UI**：书籍原文语言手动修正入口、默认解释语言下拉选择
- **词汇页语言标签/筛选**：`AggregatedVocabulary.languageId`，支持按语言筛选和标签展示
- **单词点击回调扩展**：从只传 word → 传 surface/canonical/languageId/contextText，避免重复 canonicalize

### 变更

- **AI 状态迁移**：阅读器文本/词汇分析均通过 `AIAssistantController` 路由，`AINotifier` 保留章节级 AI（总结/预习/练习）
- **备份管线扩展**：`book_glossary` 和 `character_registry` 两个全局 box 纳入导出/导入

### 修复

- `WordLevelService.init()` 在 Riverpod 迁移后未被调用

## [1.6.1] - 2026-06-04

### Fixed

- 修复阅读器单词高亮没有正确初始化词形规范化服务的问题，避免学习中和已掌握状态无法按单词原形识别。
- 将默认备份间隔调整为 1 天，减少首次使用时自动备份等待过长的问题。

## [1.6.0] - 2026-06-04

### Added

- 新增多语言基础设施，阅读分析和高亮渲染开始通过语言模块处理。
- 新增语言感知查词请求，为词形规范化、词典查询和后续多语言词汇状态隔离打基础。
- 新增按语言拆分的存储 box，并支持语言感知的备份恢复路径。
- 新增词典查不到时的辅助分析能力，改善作品内合成词和上下文兜底体验。
- 新增首页书籍难度的紧凑标签展示，并刷新书架布局。

### Fixed

- 修复阅读器工具栏在紧凑布局下的对齐与空间占用问题。
- 修复首页书架条目、难度标签和阅读进度在窄宽度下可能挤压或溢出的问题。
- 修复首页控件缺少悬停反馈的问题。
- 修复掌握单词庆祝动效因全局 key 频繁重建导致的状态不稳定问题。

### Changed

- 将阅读器、书架、词汇、RSS、设置、备份和 AI cache 相关状态逐步迁移到 Riverpod 基础设施。
- 移除旧的 provider bridge，收敛应用状态初始化和读取路径。
- 收紧 Dart 分析规则，并新增架构参考文档与文档新鲜度校验工具。
- 更新 macOS Pod lockfile 和 Dart 依赖锁定结果。

## [1.5.0] - 2026-06-02

### Added

- 新增 RSS 文章详情阅读页，支持返回列表、上一篇/下一篇、已读/未读、收藏、稍后读和打开原文。
- 新增 RSS 文章列表筛选与搜索，支持全部、未读、收藏和稍后读视图。
- 新增 RSS 订阅、文章列表和文章详情的显式加载、空状态和错误状态，网络失败时显示明确反馈和重试入口。
- 新增 RSS 本地精读模式，复用现有查词与选中文本分析能力，不触发自动 AI 消耗。
- 新增设置页诊断报告导出和 macOS 权限诊断，便于排查网络、备份目录和沙盒权限问题。

### Fixed

- 修复 macOS 自动安装更新时解压出的应用可能无法启动的问题。
- 修复结构分析悬停高亮时布局可能抖动的问题。
- 修复备份导入恢复前置事务中的异常处理边界。
- 补齐 RSS 文章查词回归，确保高亮词复用统一词典详情路径。

### Changed

- 改进 RSS 正文渲染和解析结构，让文章阅读体验更接近主阅读器。
- Browser 继续作为 RSS 原文查看的内部能力，不再暴露独立首页或设置入口。
- 收敛 AI、词典和 RSS 相关内部模块边界，为后续统一阅读助手做准备。

## [1.4.0] - 2026-05-31

### Added

- 新增共享图片查看器，为阅读内容中的图片提供统一预览体验。
- 新增内置 Literata 字体，并支持 EPUB CSS 子集布局，让正文呈现更贴近书籍排版。
- 新增章节 AI 覆盖状态、无剧透章节预览、下一步阅读建议、弱点诊断、练习准确率和周学习信号摘要。
- 优化阅读设置面板，让阅读偏好调整更集中、清晰。

### Fixed

- 修复 EPUB 内嵌样式优先级过高时正文排版可能偏离应用主题的问题。
- 修复目录交互中的若干细节问题。

### Changed

- 简化阅读器外层控件，并重构阅读目标浮层，减少阅读时的视觉干扰。
- 抽离 EPUB 解析核心并纳入测试，为阅读器后续复用打基础。
- 更新 macOS Flutter 构建设置。

## [1.3.0] - 2026-05-30

### Added

- 新增词典来源管理：可查看来源类型、启用状态、优先级和最近测试结果，并可调整来源顺序。
- 新增词典来源可用性测试，方便验证当前来源链路是否可用。
- 查词详情支持继续点击释义中的单词查询，并可返回上一个查词词条。
- 阅读器正文中的普通词、学习中词和已掌握词都可以单击查词；已掌握词保持普通视觉，不额外高亮。
- 阅读器支持将已掌握词改回学习中，并在记住单词时显示轻量星星动效。
- EPUB 图片会按正文宽度自适应，降低窄屏横向溢出、裁剪和布局跳动。
- 阅读器增加轻量阅读目标提醒，避免遮挡查词、搜索和章节导航。

### Fixed

- 修复切换查词词条后原文语境可能停留在旧词的问题。
- 修复词典侧栏操作区光标和可点击反馈不一致的问题。
- 修复查词高亮与词典状态显示中的若干细节问题。
- 修复更新检查与安装流程中的版本和状态处理问题。

### Changed

- 整理阅读流 AI 入口：移除阅读器顶部菜单里的 AI 总结和练习生成入口，保留选中文本和原文语境下的主动 AI 解析。
- 移除选中文本菜单中的冗余“查词”入口，查词统一通过单击单词触发。
- 阅读器词典详情和操作区进一步收敛为同一条查词路径，Reader、词汇页和 RSS 复用同一详情体验。
- 重构关于页面，并增加 pre-push 测试钩子以减少发布前回归。

## [1.2.0] - 2026-05-30

### Added

- 新增统一的 AI PromptBuilder 基础设施，为章节总结、练习题、选中文本分析、翻译、词汇分析和文章助手提供一致的语言、证据和剧透边界约束。
- AI 总结和练习缓存现在会按内容、prompt 版本、源语言和输出语言隔离，避免 prompt 或文本变化后复用过期结果。

### Changed

- 改进选中文本的“结构分析”展示：原文片段会以下划线标出结构区域，鼠标悬停解释项时会高亮对应原文。
- 优化“词汇说明”布局，让加入学习卡片的操作按钮保持右对齐，侧栏标题与收起按钮保持同一行。

### Fixed

- 当 AI 返回非严格 JSON 内容时，改为安全展示 fallback 文本，避免结果区只显示解析失败。

## [1.1.1-alpha] - 2026-05-28

### Fixed

- 修复 alpha 版本在 GitHub Release 上传 macOS 安装包时可能被发布状态限制阻止的问题。

## [1.1.0-alpha] - 2026-05-27

### Added

- support auto-download and one-click install for macOS updates
- 备份格式迁移至 .flow.bak zip 容器
- 细化缓存信息展示

### Fixed

- 修复备份恢复可能存在的报错
- support stream based epub imports
- 防止旧调试包干扰版本验收

### Changed

- 新增备份格式迁移 ADR 和项目术语表
- 更新公开贡献说明

## [1.0.0] - 2026-05-24

### Milestone

- 发布 Flow Read 第一个开源稳定版，版本号进入 `1.0.0`。
- 完成开源发布准备：补充许可证、第三方声明、隐私说明、安全策略、贡献说明和发布 Runbook。

### Added

- 增加本地诊断日志，失败排查时可打开日志目录，并对密钥、正文、路径和 URL 查询参数做脱敏。
- 增加章节学习分析能力，可汇总阅读时长、查词依赖、复习情况和下一步建议。
- 增加轻量复习入口，将阅读和练习中沉淀的学习项带入复习流程。
- 增加单词发音能力，查词时可辅助听读。

### Fixed

- 修复重新打开阅读器时阅读位置恢复不准确的问题。

### Changed

- 更新 README，明确产品定位、macOS 发布目标、技术栈、隐私安全入口和贡献入口。
- 统一 Hive repository 生命周期：启动层打开存储 box，repository 只复用已打开 box。
- 改进 RSS 服务的可测试性和稳定性，网络请求与时间来源可注入，并补充 RSS/Atom、HTTP 失败、缓存回退和更新时间测试。

## [0.0.3-alpha] - 2026-05-20

### Added

- 阅读器支持键盘方向键滚动和翻页。
- 选中文本后自动显示操作菜单。
- 发布流程支持从提交历史生成 changelog 草稿。

### Fixed

- 修复阅读器缩略形式的高亮误判。
- 修复选中文本内容被截断的问题。
- 修复文本操作菜单执行后不会自动隐藏的问题。
- 修复设置页滚动条相关报错。
- 修复词典音标乱码。
- 持久化书籍难易度，避免每次启动触发重新计算。
- 修复关于菜单和设置页仍显示旧版本号的问题。
- 更新发布流水线，确保打包产物的版本号与发布元数据一致。

## [0.0.2-alpha] - 2026-05-19

### Changed

- 发布 `0.0.2-alpha` 内测版本。

### Fixed

- 修复设置页列表项在新版 Flutter 下的 Material 层级断言，保持点击反馈可见。

## [0.0.1-alpha] - 2026-05-18

### Milestone

- 将 `0.0.1-alpha` 定义为 Flow Read 第一个稳定内测版 milestone。
- 该版本面向内测使用和反馈收集，保留 alpha 阶段的功能迭代空间。

### Added

- 建立 GitHub 发布流程、changelog、版本号校验和 macOS 本地打包流程。
- 在设置页显示当前应用版本，并在新版本首次打开时展示更新内容。
- 完成 EPUB 导入、书架、阅读器、目录、书签、阅读进度和全文搜索的基础体验。
- 完成词汇标记、词典释义、例句展示、复习和训练的基础学习闭环。
- 增加 AI 配置、连接测试、统一可用性判断和阅读侧 AI 辅助入口。
- 增加 RSS 订阅管理、最新内容阅读和实验功能开关。
- 增加本地备份、定时同步、备份导入和 Word Hunter 备份导入。

### Fixed

- 修复 macOS RSS 网络访问和备份目录写入所需的沙盒权限问题。
- 修复启动阶段空白首帧、阅读器翻页滚动位置残留和更多菜单显示异常。
