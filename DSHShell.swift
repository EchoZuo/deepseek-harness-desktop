// DSH Shell — 极简 DeepSeek Harness 桌面壳
// SwiftUI + WKWebView，加载本机运行中的 dsh web 实例。
import SwiftUI
import WebKit
import AppKit

// MARK: - 实例探测

@MainActor
final class AppState: ObservableObject {
    @Published var url: URL? = nil
    @Published var checking = false

    static let candidatePorts: [Int] = [3080, 8080, 3000]

    func discover() {
        guard !checking else { return }
        checking = true
        url = nil
        Task {
            for port in Self.candidatePorts where await Self.probe(port: port) {
                self.url = URL(string: "http://127.0.0.1:\(port)/")!
                self.checking = false
                return
            }
            self.checking = false
        }
    }

    nonisolated static func probe(port: Int) async -> Bool {
        guard let u = URL(string: "http://127.0.0.1:\(port)/") else { return false }
        var req = URLRequest(url: u, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 1.0)
        req.httpMethod = "GET"
        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            return (resp as? HTTPURLResponse) != nil
        } catch {
            return false
        }
    }
}

// MARK: - WebView

struct WebView: NSViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if webView.url?.absoluteString != url.absoluteString, !webView.isLoading {
            webView.load(URLRequest(url: url))
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate {
        // 需要下载的资源转成 WKDownload
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            navigationAction.shouldPerformDownload ? .download : .allow
        }

        func webView(_ webView: WKWebView,
                     navigationAction: WKNavigationAction,
                     didBecome download: WKDownload) {
            download.delegate = self
        }

        func webView(_ webView: WKWebView,
                     navigationResponse: WKNavigationResponse,
                     didBecome download: WKDownload) {
            download.delegate = self
        }

        func download(_ download: WKDownload,
                      decideDestinationUsing response: URLResponse,
                      suggestedFilename: String) async -> URL? {
            let panel = NSSavePanel()
            panel.canCreateDirectories = true
            panel.nameFieldStringValue = suggestedFilename
            let ok = await MainActor.run { panel.runModal() == .OK }
            return ok ? panel.url : nil
        }

        // target=_blank 的外链交给系统浏览器
        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil,
               let u = navigationAction.request.url,
               u.scheme == "http" || u.scheme == "https" {
                NSWorkspace.shared.open(u)
            }
            return nil
        }
    }
}

// MARK: - App 入口

@main
struct DSHShellApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var state = AppState()

    var body: some Scene {
        WindowGroup("DSH Shell") {
            content
                .frame(minWidth: 960, minHeight: 640)
                .onAppear {
                    state.discover()
                    // 窗口就绪后，把 logo 拼进标题栏
                    DispatchQueue.main.async {
                        if let win = NSApp.windows.first(where: { $0.isVisible }) {
                            Self.brandWindow(win)
                        }
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let url = state.url {
            WebView(url: url)
        } else {
            VStack(spacing: 14) {
                if state.checking {
                    ProgressView()
                    Text("正在探测本机 DSH 实例…").foregroundStyle(.secondary)
                } else {
                    Text("未找到运行中的 DSH Web 实例")
                        .font(.title3.bold())
                    Text("请先在终端运行 dsh web，然后重试。\n（依次探测端口：3080 / 8080 / 3000）")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Button("重试探测") { state.discover() }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // 从 bundle 读取图标
    private static var appIcon: NSImage? {
        guard let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
              let icon = NSImage(contentsOf: url) else { return nil }
        return icon
    }

    // 标题栏：logo 挂到左侧（交通灯旁边）
    static func brandWindow(_ window: NSWindow) {
        guard let icon = appIcon else { return }
        icon.size = NSSize(width: 16, height: 16)
        let imgView = NSImageView(frame: NSRect(x: 4, y: 2, width: 16, height: 16))
        imgView.image = icon
        imgView.imageScaling = .scaleProportionallyUpOrDown
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 24, height: 20))
        container.addSubview(imgView)
        let accessory = NSTitlebarAccessoryViewController()
        accessory.view = container
        accessory.layoutAttribute = .leading
        window.addTitlebarAccessoryViewController(accessory)
        window.title = "DSH Shell"
    }
}

// MARK: - 菜单 / 激活

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        // 应用级图标（About 面板、菜单等处）
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: url) {
            NSApp.applicationIconImage = icon
        }
        installMainMenu()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    // 原生菜单：让 Cmd+C/V/A、Cmd+R 在 WKWebView 里正常工作
    private func installMainMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "关于 DSH Shell",
                        action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
                        keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "退出 DSH Shell",
                        action: #selector(NSApplication.terminate(_:)),
                        keyEquivalent: "q")
        appItem.submenu = appMenu

        let editItem = NSMenuItem()
        mainMenu.addItem(editItem)
        let editMenu = NSMenu(title: "编辑")
        editMenu.addItem(withTitle: "撤销", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "剪切", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "拷贝", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "全选", action: #selector(NSResponder.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu

        let viewItem = NSMenuItem()
        mainMenu.addItem(viewItem)
        let viewMenu = NSMenu(title: "显示")
        viewMenu.addItem(withTitle: "重新加载", action: #selector(WKWebView.reload(_:)), keyEquivalent: "r")
        viewItem.submenu = viewMenu

        let windowItem = NSMenuItem()
        mainMenu.addItem(windowItem)
        let windowMenu = NSMenu(title: "窗口")
        windowMenu.addItem(withTitle: "最小化",
                           action: #selector(NSWindow.performMiniaturize(_:)),
                           keyEquivalent: "m")
        windowMenu.addItem(withTitle: "缩放",
                           action: #selector(NSWindow.performZoom(_:)),
                           keyEquivalent: "")
        windowItem.submenu = windowMenu

        NSApp.mainMenu = mainMenu
    }
}
