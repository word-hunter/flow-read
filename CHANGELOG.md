# Changelog

All notable changes to Flow Read are tracked here.

This project follows a simple semantic versioning flow:

- `MAJOR` for incompatible data, storage, or user-facing workflow changes.
- `MINOR` for backward-compatible features and meaningful UX additions.
- `PATCH` for bug fixes, copy changes, and internal improvements.

## [Unreleased]

## [0.0.2-alpha] - 2026-05-19

### Changed

- Prepared 0.0.2-alpha release.

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
