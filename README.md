# Flow Read

<p align="center">
  <img src="assets/brand/flow_read_logo.png" alt="Flow Read logo" width="140">
</p>

Flow Read 是一款面向英语阅读和词汇积累的应用，把书架、EPUB 阅读、查词、生词复习和阅读进度放在同一个安静的工作流里。

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

## 本地运行

项目使用 Flutter。仓库通过 `.fvmrc` 固定 SDK 版本，推荐使用 FVM：

```bash
fvm flutter pub get
fvm flutter run
```

如果不使用 FVM，请确认本地 `flutter --version` 与 `.fvmrc` 中的版本一致。

更多维护流程以仓库内脚本和项目说明为准。
