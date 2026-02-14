import SwiftUI
import AVFoundation

/// XMusic 应用程序主入口
@main
struct XMusicApp: App {
    /// 应用程序代理
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

/// 应用程序代理类 - 处理应用程序启动和窗口配置
class AppDelegate: NSObject, NSApplicationDelegate {
    /// 应用程序启动完成时调用
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = false
        }
    }
}
