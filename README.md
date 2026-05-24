# Flow Read

<p align="center">
  <img src="assets/brand/flow_read_logo.png" alt="Flow Read logo" width="140">
</p>

Flow Read 是一款面向英语阅读和词汇积累的 Flutter 应用，把书架、EPUB 阅读、查词、生词复习、RSS 阅读、AI 辅助和本地备份放在同一个安静的工作流里。

当前公开发布目标以 macOS 桌面端为主。代码结构也保留了 Flutter 多端能力，但移动端和其他桌面平台需要单独验证后再作为正式发行目标。

## 应用截图

<p align="center">
  <img src="assets/app-snapshot-1.png" alt="Flow Read 书架截图" width="920">
</p>

## 核心体验

- **继续阅读**：从书架直接回到上次章节，阅读进度、预计剩余时间和阅读目标一目了然。
- **EPUB 书库**：导入英文电子书，按最近阅读、进度和书籍信息快速管理。
- **阅读难度提示**：为书籍展示阅读等级，帮助判断是否适合当前词汇水平。
- **阅读中查词**：点击单词即可查看释义，宽屏下可固定在侧栏，减少阅读中断。
- **生词与复习**：自动汇总阅读中遇到的词，支持掌握状态管理和集中训练。
- **AI 辅助阅读**：按需开启单词详解、句子分析、章节总结和练习题生成。
- **RSS 与网页内容**：订阅 RSS/Atom 内容，并复用阅读侧的词汇查询能力。
- **本地备份**：导出和恢复本地阅读、词汇、设置和学习数据。

## 技术栈

| 类别 | 依赖 |
|------|------|
| 框架 | Flutter / Dart |
| 状态管理 | provider |
| 持久化 | Hive / hive_flutter |
| EPUB 解析 | archive + xml + html |
| 文件导入 | file_picker |
| 网络请求 | http |
| 语音 | flutter_tts |
| UI | Material Design 3 |

## 本地运行

项目使用 Flutter。仓库通过 `.fvmrc` 固定 SDK 版本，推荐使用 FVM：

```bash
fvm flutter pub get
fvm flutter run
```

如果不使用 FVM，请确认本地 `flutter --version` 与 `.fvmrc` 中的版本一致。

## 常用检查

```bash
fvm dart analyze
fvm flutter test
git diff --check
```

## 发布与安装

当前 GitHub Release 产物是 macOS zip 包。除非具体 Release 说明另有标注，请默认它未经过 Apple 公证；安装时可能需要在 macOS 安全设置中手动允许运行。

发布流程见 [Release Runbook](docs/release-runbook.md)。版本号不会随普通功能开发自动更新。

## 隐私与安全

Flow Read 是本地优先应用，不需要账号。AI、RSS、在线词典和更新检查会在用户启用对应功能时访问外部服务。详情见：

- [Privacy](PRIVACY.md)
- [Security](SECURITY.md)
- [Third-party notices](NOTICE)

## 贡献

贡献前请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。内部规划文档、私有备忘和本地实验记录应放在 `private/`，该目录被 Git 忽略，不应强制提交。
