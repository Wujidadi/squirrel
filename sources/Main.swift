//
//  Main.swift
//  Squirrel
//
//  Created by Leo Liu on 5/10/24.
//

import Foundation
import InputMethodKit

@main
struct SquirrelApp {
  static let userDir = if let pwuid = getpwuid(getuid()) {
    URL(fileURLWithFileSystemRepresentation: pwuid.pointee.pw_dir, isDirectory: true, relativeTo: nil).appending(components: "Library", "Rime")
  } else {
    try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("Rime", isDirectory: true)
  }
  static let appDir = "/Library/Input Methods/Squirrel.app".withCString { dir in
    URL(fileURLWithFileSystemRepresentation: dir, isDirectory: false, relativeTo: nil)
  }
  static let logDir = FileManager.default.temporaryDirectory.appending(component: "rime.squirrel", directoryHint: .isDirectory)

  // swiftlint:disable:next cyclomatic_complexity
  static func main() {
    // 離線維護旗標（dotfiles 的 rime-hold-quit 於離線重建 userdb 期間放置）：
    // 輸入法是 TIS 隨需啟動的行程，--quit 後只要仍是已啟用的輸入來源就會被立即重新拉起，
    // 與 rime_dict_manager 競逐同一 LevelDB；macOS 26 對終端行程的 TISDisableInputSource
    // 靜默失效，無法以停用輸入來源阻其重啟，見旗標即退場是唯一可靠的阻擋。
    // 僅無參數（輸入法常駐模式）受旗標約束，CLI 動詞不受影響；
    // 旗標逾 10 分鐘視為腳本意外殘留，自動失效以免輸入法永久無法啟動
    if CommandLine.arguments.count <= 1 {
      let holdFlag = userDir.appending(component: ".maintenance-hold")
      if let mtime = try? holdFlag.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
         Date.now.timeIntervalSince(mtime) < 600 {
        return
      }
    }
    let rimeAPI: RimeApi_stdbool = rime_get_api_stdbool().pointee

    let handled = autoreleasepool {
      let installer = SquirrelInstaller()
      let args = CommandLine.arguments
      if args.count > 1 {
        switch args[1] {
        case "--quit":
          let bundleId = Bundle.main.bundleIdentifier!
          let runningSquirrels = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
          runningSquirrels.forEach { $0.terminate() }
          return true
        case "--reload":
          // Squirrel is a background app, and AppKit suspends distributed-notification delivery to inactive apps;
          // deliverImmediately is required for these notifications to reach Squirrel while it stays in the background
          DistributedNotificationCenter.default().postNotificationName(.init("SquirrelReloadNotification"), object: nil, userInfo: nil, deliverImmediately: true)
          return true
        case "--register-input-source", "--install":
          installer.register()
          return true
        case "--enable-input-source":
          if args.count > 2 {
            let modes = args[2...].map { SquirrelInstaller.InputMode(rawValue: $0) }.compactMap { $0 }
            if !modes.isEmpty {
              installer.enable(modes: modes)
              return true
            }
          }
          installer.enable()
          return true
        case "--disable-input-source":
          if args.count > 2 {
            let modes = args[2...].map { SquirrelInstaller.InputMode(rawValue: $0) }.compactMap { $0 }
            if !modes.isEmpty {
              installer.disable(modes: modes)
              return true
            }
          }
          installer.disable()
          return true
        case "--select-input-source":
          if args.count > 2, let mode = SquirrelInstaller.InputMode(rawValue: args[2]) {
            installer.select(mode: mode)
          } else {
            installer.select()
          }
          return true
        case "--build":
          SquirrelApplicationDelegate.showMessage(msgText: NSLocalizedString("deploy_update", comment: ""))
          var builderTraits = RimeTraits.rimeStructInit()
          builderTraits.setCString("rime.squirrel-builder", to: \.app_name)
          rimeAPI.setup(&builderTraits)
          rimeAPI.deployer_initialize(nil)
          _ = rimeAPI.deploy()
          return true
        case "--sync":
          DistributedNotificationCenter.default().postNotificationName(.init("SquirrelSyncNotification"), object: nil, userInfo: nil, deliverImmediately: true)
          return true
        case "--ascii":
          DistributedNotificationCenter.default().postNotificationName(.init("SquirrelToggleASCIIModeNotification"), object: "ascii", userInfo: nil, deliverImmediately: true)
          return true
        case "--nascii":
          DistributedNotificationCenter.default().postNotificationName(.init("SquirrelToggleASCIIModeNotification"), object: "nascii", userInfo: nil, deliverImmediately: true)
          return true
        case "--getascii":
          var responseReceived = false
          var asciiStatus = ""
          let observer = DistributedNotificationCenter.default().addObserver(
            forName: .init("SquirrelASCIIModeResponse"),
            object: nil,
            queue: .main
          ) { notification in
            if let status = notification.object as? String {
              asciiStatus = status
              responseReceived = true
            }
          }
          DistributedNotificationCenter.default().postNotificationName(.init("SquirrelGetASCIIModeNotification"), object: nil, userInfo: nil, deliverImmediately: true)
          let timeout = Date().addingTimeInterval(2.0)
          while !responseReceived && Date() < timeout {
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
          }
          DistributedNotificationCenter.default().removeObserver(observer)
          if responseReceived {
            print(asciiStatus)
          } else {
            print("nascii")
          }
          return true
        case "--help":
          print(helpDoc)
          return true
        default:
          break
        }
      }
      return false
    }
    if handled {
      return
    }

    autoreleasepool {
      let main = Bundle.main
      let connectionName = main.object(forInfoDictionaryKey: "InputMethodConnectionName") as! String
      _ = IMKServer(name: connectionName, bundleIdentifier: main.bundleIdentifier!)
      let app = NSApplication.shared
      let delegate = SquirrelApplicationDelegate()
      app.delegate = delegate
      app.setActivationPolicy(.accessory)

      // OpenCC uses relative dictionary paths from SharedSupport.
      FileManager.default.changeCurrentDirectoryPath(main.sharedSupportPath!)

      if NSApp.squirrelAppDelegate.problematicLaunchDetected() {
        print("Problematic launch detected!")
        let args = ["Problematic launch detected! Squirrel may be suffering a crash due to improper configuration. Revert previous modifications to see if the problem recurs."]
        let task = Process()
        task.executableURL = "/usr/bin/say".withCString { dir in
          URL(fileURLWithFileSystemRepresentation: dir, isDirectory: false, relativeTo: nil)
        }
        task.arguments = args
        try? task.run()
      } else {
        NSApp.squirrelAppDelegate.setupRime()
        NSApp.squirrelAppDelegate.startRime(fullCheck: false)
        NSApp.squirrelAppDelegate.loadSettings()
        print("Squirrel reporting!")
      }

      app.run()
      print("Squirrel is quitting...")
      rimeAPI.finalize()
    }
    return
  }

  static let helpDoc = """
Supported arguments:
Perform actions:
  --quit                     quit all Squirrel process
  --reload                   deploy
  --sync                     sync user data
  --build                    build all schemas in current directory
  --ascii                    turn on ASCII mode
  --nascii                   turn off ASCII mode
  --getascii                 get current ASCII mode status
Install Squirrel:
  --install, --register-input-source    register input source
  --enable-input-source [source id...]  input source list optional
  --disable-input-source [source id...] input source list optional
  --select-input-source [source id]     input source optional
"""
}
