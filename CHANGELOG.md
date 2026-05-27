# Changelog

All notable changes to Flow Read are tracked here.

This project follows a simple semantic versioning flow:

- `MAJOR` for incompatible data, storage, or user-facing workflow changes.
- `MINOR` for backward-compatible features and meaningful UX additions.
- `PATCH` for bug fixes, copy changes, and internal improvements.

## [Unreleased]

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
