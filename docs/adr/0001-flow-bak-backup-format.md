# 0001: `.flow.bak` zip archive backup format

Flow Read 的备份格式从单个 pretty JSON（内含 base64 编码的 EPUB/封面文件）迁移为 `.flow.bak` zip 容器。外层容器版本（`manifest.formatVersion`）和应用数据 schema 版本（`data/app.json.schemaVersion`）独立管理，互不污染。

## Considered Options

- **保留旧 JSON 并兼容两种格式**：需要维护两套导入路径、base64 编解码、漏文件的宽松恢复逻辑。用户备份目录里混合 `.json` 和 `.flow.bak`，增加困惑和测试矩阵。
- **完全替换为 `.flow.bak`，不保留旧 JSON 兼容**：导入路径单一，代码精简，不再维护 base64 编解码。代价是目前已存在的旧 `.json` 备份无法直接导入 —— 用户需在升级前在旧版本中完成最后一次恢复。

选择后者。旧 JSON 兼容的成本是持续性的（每处改动都要考虑两种路径），而迁移成本是一次性的（用户升级前做最后一次恢复即可）。

## Consequences

- `backup_service.dart` 中所有旧 JSON 导出/导入逻辑被删除：`createBackupPayloadForExport`、`_snapshotBookFiles`、`_restoreBookFiles`、`_encodeFileBytes`、`_decodeFileBytes`、`_encodePayloadIsolate`。
- Word Hunter 导入保留不变 —— 它是外部第三方格式，不受此决策影响。
- 新增 `lib/services/backup_archive.dart` 处理 zip 容器逻辑（manifest、编解码、isolate 调度），与 `BackupService` 的业务职责分离。
- `importBackupFile()` 改用 magic bytes（`PK\x03\x04`）探测文件类型，不依赖扩展名。
