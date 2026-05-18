import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSDraggingDestination {
  private static let defaultContentSize = NSSize(width: 1360, height: 840)
  private static let minimumContentSize = NSSize(width: 1180, height: 740)

  private var backupFolderChannel: FlutterMethodChannel?
  private var backupFolderAccessHandler: BackupFolderAccessHandler?
  private var fileDropChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    configureTitleBar()

    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    configureInitialWindowSize()

    RegisterGeneratedPlugins(registry: flutterViewController)
    registerBackupFolderAccessChannel(flutterViewController: flutterViewController)
    registerFileDropChannel(flutterViewController: flutterViewController)
    registerForDraggedTypes([.fileURL])

    super.awakeFromNib()
  }

  private func configureTitleBar() {
    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    styleMask.insert(.fullSizeContentView)
    isMovableByWindowBackground = true
  }

  private func configureInitialWindowSize() {
    contentMinSize = Self.minimumContentSize

    let currentContentSize = contentLayoutRect.size
    guard currentContentSize.width < Self.minimumContentSize.width ||
      currentContentSize.height < Self.minimumContentSize.height
    else {
      return
    }

    let targetSize = Self.contentSizeThatFitsScreen()
    setContentSize(targetSize)
    center()
  }

  private static func contentSizeThatFitsScreen() -> NSSize {
    guard let visibleFrame = NSScreen.main?.visibleFrame else {
      return defaultContentSize
    }

    let availableWidth = max(0, visibleFrame.width - 48)
    let availableHeight = max(0, visibleFrame.height - 48)
    return NSSize(
      width: min(defaultContentSize.width, availableWidth),
      height: min(defaultContentSize.height, availableHeight))
  }

  private func registerBackupFolderAccessChannel(flutterViewController: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "flow_read/backup_folder_access",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    let handler = BackupFolderAccessHandler(window: self)
    channel.setMethodCallHandler(handler.handle)
    backupFolderChannel = channel
    backupFolderAccessHandler = handler
  }

  private func registerFileDropChannel(flutterViewController: FlutterViewController) {
    fileDropChannel = FlutterMethodChannel(
      name: "flow_read/file_drop",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
  }

  func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    guard !epubFilePaths(from: sender).isEmpty else {
      return []
    }
    fileDropChannel?.invokeMethod("dragEntered", arguments: nil)
    return .copy
  }

  func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
    return epubFilePaths(from: sender).isEmpty ? [] : .copy
  }

  func draggingExited(_ sender: NSDraggingInfo?) {
    fileDropChannel?.invokeMethod("dragExited", arguments: nil)
  }

  func draggingEnded(_ sender: NSDraggingInfo) {
    fileDropChannel?.invokeMethod("dragExited", arguments: nil)
  }

  func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    let paths = epubFilePaths(from: sender)
    guard !paths.isEmpty else {
      fileDropChannel?.invokeMethod("dragExited", arguments: nil)
      return false
    }

    fileDropChannel?.invokeMethod("filesDropped", arguments: paths)
    return true
  }

  private func epubFilePaths(from draggingInfo: NSDraggingInfo) -> [String] {
    let pasteboard = draggingInfo.draggingPasteboard
    let urls = pasteboard.readObjects(
      forClasses: [NSURL.self],
      options: [.urlReadingFileURLsOnly: true]) as? [URL]

    return urls?
      .filter { $0.pathExtension.lowercased() == "epub" }
      .map { $0.path } ?? []
  }
}

private final class BackupFolderAccessHandler {
  private weak var window: NSWindow?
  private var activeUrls: [String: URL] = [:]

  init(window: NSWindow) {
    self.window = window
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "chooseBackupFolder":
      chooseBackupFolder(arguments: call.arguments, result: result)
    case "startAccessingBackupFolder":
      startAccessingBackupFolder(arguments: call.arguments, result: result)
    case "stopAccessingBackupFolder":
      stopAccessingBackupFolder(arguments: call.arguments)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func chooseBackupFolder(arguments: Any?, result: @escaping FlutterResult) {
    let args = arguments as? [String: Any]
    let dialog = NSOpenPanel()
    dialog.title = args?["dialogTitle"] as? String ?? "选择备份文件夹"
    dialog.showsHiddenFiles = false
    dialog.allowsMultipleSelection = false
    dialog.canChooseDirectories = true
    dialog.canChooseFiles = false
    dialog.canCreateDirectories = true

    if let initialDirectory = args?["initialDirectory"] as? String, !initialDirectory.isEmpty {
      dialog.directoryURL = URL(fileURLWithPath: initialDirectory)
    }

    guard let window else {
      result(nil)
      return
    }

    dialog.beginSheetModal(for: window) { response in
      guard response == .OK, let url = dialog.url else {
        result(nil)
        return
      }

      do {
        let bookmark = try url.bookmarkData(
          options: [.withSecurityScope],
          includingResourceValuesForKeys: nil,
          relativeTo: nil)
        result([
          "path": url.path,
          "bookmark": bookmark.base64EncodedString()
        ])
      } catch {
        result(FlutterError(
          code: "BOOKMARK_CREATE_FAILED",
          message: "无法保存备份文件夹访问权限",
          details: error.localizedDescription))
      }
    }
  }

  private func startAccessingBackupFolder(arguments: Any?, result: @escaping FlutterResult) {
    guard
      let args = arguments as? [String: Any],
      let bookmark = args["bookmark"] as? String,
      let data = Data(base64Encoded: bookmark)
    else {
      let path = (arguments as? [String: Any])?["path"] as? String ?? ""
      result(["path": path, "started": false])
      return
    }

    var isStale = false
    do {
      let url = try URL(
        resolvingBookmarkData: data,
        options: [.withSecurityScope],
        relativeTo: nil,
        bookmarkDataIsStale: &isStale)
      let started = url.startAccessingSecurityScopedResource()
      if started {
        activeUrls[url.path] = url
      }
      result([
        "path": url.path,
        "started": started,
        "stale": isStale
      ])
    } catch {
      result(FlutterError(
        code: "BOOKMARK_RESOLVE_FAILED",
        message: "无法恢复备份文件夹访问权限",
        details: error.localizedDescription))
    }
  }

  private func stopAccessingBackupFolder(arguments: Any?) {
    guard
      let args = arguments as? [String: Any],
      let path = args["path"] as? String,
      let url = activeUrls.removeValue(forKey: path)
    else {
      return
    }
    url.stopAccessingSecurityScopedResource()
  }
}
