# Flow Read

英文阅读 + 词汇学习一体化的 Flutter 桌面/移动端应用。

## 功能

- **EPUB 阅读器** — 导入 `.epub` 电子书，支持字体大小/字体/行高/阅读主题（亮色/暗色/护眼黄）调节，章节导航，阅读进度追踪，书签管理
- **生词标记与释义** — 自动标记生词，点击查词（WordNet / 内置词典 / Collins / Longman 多源回退），宽屏支持右侧固定释义栏，切换生词不打断阅读
- **AI 辅助** — 单词 AI 详解、选句翻译/句式分析、章节 AI 总结、AI 练习题生成（均支持缓存）
- **RSS 订阅** — 支持 RSS 2.0 / Atom 格式，添加/删除订阅源，已读未读标记，宽窄屏自适应布局
- **词汇管理** — 全书生词聚合、搜索排序、已知/学习中/未知分级、生词本
- **阅读统计** — 总阅读时长、书籍数量、词汇量、AI 使用次数统计
- **训练与复习** — 词汇训练、间隔复习
- **响应式布局** — 宽屏侧边栏导航 / 窄屏底部导航自动切换

## 技术栈

| 类别 | 依赖 |
|------|------|
| 框架 | Flutter (Dart) |
| 状态管理 | provider |
| 电子书解析 | epubx |
| 持久化 | hive + hive_flutter |
| 文件导入 | file_picker |
| 网络请求 | http |
| HTML 解析 | html |
| RSS / XML 解析 | xml（epubx 传递依赖） |
| UI | Material Design 3 |

## 运行

```bash
flutter pub get
flutter run
```

## 发布

构建版本保存在 `pubspec.yaml` 的 `version: MAJOR.MINOR.PATCH+BUILD`，应用内展示版本由 `lib/services/app_version.dart` 提供，发布校验会确保两者一致。`CHANGELOG.md` 记录每个发布版本的用户可见变更。

常用命令：

```bash
dart run tool/release.dart current
dart run tool/release.dart bump patch
dart run tool/release.dart check
dart run tool/release.dart notes
```

发布步骤：

1. 在 `CHANGELOG.md` 的 `Unreleased` 区块补充本次变更。
2. 只有在准备发布并明确要更新版本时，执行 `dart run tool/release.dart bump patch`，按需要将 `patch` 替换为 `minor` 或 `major`。
3. 提交 `pubspec.yaml`、`lib/services/app_version.dart` 和 `CHANGELOG.md`。
4. 创建并推送标签，例如 `git tag v0.0.1-alpha && git push origin v0.0.1-alpha`。
5. GitHub Actions 会构建 macOS release 包，并用对应 changelog 区块创建 GitHub Release。

## 项目结构

```
lib/
├── main.dart                  # 入口，Provider 注册，路由表
├── models/                    # 数据模型（Hive 持久化）
├── providers/                 # 状态管理（ChangeNotifier）
├── services/                  # 业务逻辑与持久化
├── screens/                   # 全屏页面
├── pages/                     # 阅读器子页面
├── widgets/                   # 可复用组件
│   ├── home/                  # 首页相关组件
│   ├── reader/                # 阅读器相关组件
│   └── rss/                   # RSS 相关组件
├── theme/                     # 主题与常量
└── utils/                     # 工具函数
```
