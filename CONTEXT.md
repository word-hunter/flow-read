# Flow Read

英语阅读和词汇学习应用，结合 EPUB 阅读、词典查词、AI 辅助、RSS 阅读和词汇复习。

## Language

### Backup

**Backup（备份快照）**：一次完整的应用数据导出，包含所有 Hive boxes（书籍 metadata、词汇、书签、阅读进度、RSS 订阅、设置等）和每本书的 EPUB 源文件 + 封面，打包为一个独立的 `.flow.bak` 文件。每次备份生成新快照，不做增量更新、不覆盖已有快照。

**`.flow.bak`（备份容器）**：备份快照的物理文件格式。本质是 zip 压缩包，内部结构由 `manifest.json` 索引，固定包含 `data/app.json` 和 `books/<bookId>/` 下的源文件/封面。文件名模式：`flow_read_backup_YYYYMMDD_HHMMSS.flow.bak`。

**Manifest（容器索引表）**：`.flow.bak` zip 内的 `manifest.json` 文件，声明容器层元数据（`app`、`formatVersion`、`createdAt`、`dataPath`）和每本书的二进制 entry 路径映射（`books`）。导入时通过 manifest 定位各 entry，不靠路径模式猜测。

**`data/app.json`（应用数据段）**：`.flow.bak` 内的压缩 JSON 文件，只含 `schemaVersion` 和 `boxes`。`boxes` 结构与旧 JSON 备份中的 boxes 部分编码格式 100% 一致。不包含 `app`、`createdAt`（由 manifest 提供），不包含 `files.books`（书籍文件由 zip entry 提供）。
_Avoid_: 备份 payload、backup content

**`formatVersion`（容器格式版本）**：`manifest.json` 中的版本号，管理 `.flow.bak` 的 zip 布局规则（entry 路径约定、是否允许新 entry 类型等）。当前为 1。
_Avoid_: 容器版本、format version number

**`schemaVersion`（数据 schema 版本）**：`data/app.json` 中的版本号，管理 boxes 的编码语义（字段增减、序列化规则变化等）。当前为 1，与旧 JSON 备份中的 `schemaVersion` 含义相同。
_Avoid_: 数据版本、data version

**Pre-backup（导入前备份）**：在导入任何 `.flow.bak` 之前，自动生成的当前数据快照，作为导入失败时的安全网。文件名模式：`flow_read_pre_import_YYYYMMDD_HHMMSS.flow.bak`。存放于用户配置的备份文件夹，fallback 到 `documents/backups/pre_import/`。不更新 `lastBackupAt`。

**`.part`（未完成备份）**：导出过程中写入的临时文件（`flow_read_backup_*.flow.bak.part`），完成后 rename 为最终 `.flow.bak`。应用崩溃时可能残留，在下次导出开始时自动清理。语义等同"不可用的未完成备份"。

### Books

**Book（书籍）**：用户导入的 EPUB 出版物。存储单元为 `BookMetadata`（Hive box `books`），包含标题、作者、阅读进度、章节信息、难度评级等。每本书对应一个唯一的 `bookId`。

**EPUB source file（源文件）**：导入后复制到 `documents/books/<bookId>.epub` 的 EPUB 原始文件。在 `.flow.bak` 中作为 `books/<bookId>/source.epub` 以原始字节存储（不压缩，因为 EPUB 本身已是 zip）。

**Cover（封面）**：从 EPUB 提取的封面图片，存储为 `documents/books/<bookId>_cover.png`。在 `.flow.bak` 中作为 `books/<bookId>/cover.png` 以原始字节存储（不压缩）。非必须：无封面时不在 zip 中写入 cover entry，导入后 `coverPath = null`。

**`bookId`（书籍标识）**：书籍的唯一标识符，由导入时基于文件名、时间戳和随机数生成。用作 books box 的 key、磁盘文件名的核心部分，以及 `.flow.bak` 中 `books/` 下子目录名（经 path-safe 编码）。

### External import

**Word Hunter import（外部导入）**：从 Word Hunter 应用的 JSON 备份中合并词汇数据（known → mastered、learning → learning with examples）。与 Flow Read 自身备份格式无关，保留独立解析路径。

### macOS

**Backup Folder Access（备份文件夹访问）**：macOS 沙盒下通过安全作用域书签获取备份文件夹读写权限的机制。授予的是整个目录的权限，同目录内的文件创建、rename、copy、delete 均在授权范围内。

## Example dialogue

**Dev**: 用户点"导入备份"，选了一个 `.flow.bak` 文件。我需要知道哪些信息？

**Domain expert**: 先做 pre-backup（当前数据的安全网）。然后读 `.flow.bak` 的 `manifest.json`：校验 `formatVersion` 是否支持、`app` 是否为 `flow_read`。再从 `data/app.json` 校验 `schemaVersion`，恢复所有 boxes。最后按 manifest 里的 `books` 映射，把 zip entry 里的 EPUB/封面字节写到当前磁盘规范路径。如果 manifest 声明了某本书的 source entry 但 zip 里没有 → 整体导入失败，`.flow.bak` 是完整快照，不容忍部分缺失。

**Dev**: 旧 `.json` 备份还能导入吗？

**Domain expert**: 不能。`.flow.bak` 是唯一支持的 Flow Read 备份格式。旧 JSON 格式的导入代码已删除。Word Hunter JSON 导入不受影响 —— 那是外部格式。
