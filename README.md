# DSH Shell

<div align="center">

**简体中文** | [English](#english)

</div>

---

## 简体中文

一个极简的 macOS 桌面应用，为 DeepSeek Harness (DSH) 提供原生窗口体验。

### 功能特性

- 🪟 **原生窗口**：将 DSH Web UI 封装为独立桌面应用
- 🚀 **自动发现**：自动检测本地运行的 DSH 实例（3080/8080/3000 端口）
- 🎨 **自定义图标**：支持使用自定义图标，自动生成所有尺寸
- 🌐 **通用二进制**：同时支持 Apple Silicon 和 Intel Mac
- ⚡ **极简设计**：无内置 DSH 运行时，依赖本地已安装环境
- 📥 **下载支持**：正确处理文件下载对话框
- ⌨️ **完整快捷键**：Cmd+C/V、Cmd+R 刷新、Cmd+Q 退出等

### 系统要求

- macOS 13.0 或更高版本
- 已安装并运行 DeepSeek Harness (DSH)
- Apple Silicon 或 Intel 处理器

### 安装使用

#### 方式一：下载预编译版本（推荐）

1. 前往 [Releases](https://github.com/EchoZuo/deepseek-harness-desktop/releases) 页面
2. 下载最新版本的 `deepseek-harness-desktop-mac.zip`
3. 解压并将 `DSH Shell.app` 拖入"应用程序"文件夹
4. 首次运行时，如果系统提示"无法验证开发者"，请右键点击应用 → 打开

#### 方式二：从源码编译

```bash
git clone https://github.com/EchoZuo/deepseek-harness-desktop.git
cd dsh-mac-shell
bash build.sh
```

编译完成后，`DSH Shell.app` 会出现在当前目录。

### 自定义图标

项目提供了一个图标生成工具 `makeicon.swift`，可以将你的 PNG 图片转换为 macOS 应用图标：

```bash
swift makeicon.swift your-icon.png AppIcon.iconset
iconutil -c icns AppIcon.iconset -o AppIcon.icns
```

然后将 `AppIcon.icns` 复制到 `DSH Shell.app/Contents/Resources/` 目录即可。

图标会自动添加 20% 内边距和圆角，确保与 macOS 系统风格一致。

### 使用方式

1. 确保 DSH 正在运行（`dsh web` 命令）
2. 启动 DSH Shell
3. 应用会自动检测并加载 DSH Web UI
4. 如果未检测到，可以点击"重试探测"按钮

### 常见问题

**Q: 为什么需要单独运行 DSH？**

DSH Shell 是一个纯窗口应用，不包含 DSH 运行时。这种设计保持应用轻量，并允许你灵活控制 DSH 的版本和配置。

**Q: 支持远程 DSH 实例吗？**

当前版本仅支持本地实例（localhost）。远程支持可以在源码中修改端口检测逻辑。

**Q: 如何更新？**

重新下载最新版本的 zip 文件，替换应用程序文件夹中的旧版本即可。你的配置保存在 DSH 中，不会丢失。

### 技术细节

- **架构**：SwiftUI + WKWebView
- **构建**：支持 Universal Binary（arm64 + x86_64）
- **部署目标**：macOS 13.0+
- **签名**：Ad-hoc 签名（本地使用）或可配置开发者证书
- **沙盒**：默认启用，确保安全性

### 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

---

<div align="center">

## English

</div>

---

A minimal macOS desktop application that provides a native window experience for DeepSeek Harness (DSH).

### Features

- 🪟 **Native Window**: Wraps DSH Web UI in a standalone desktop app
- 🚀 **Auto-Discovery**: Automatically detects locally running DSH instances (ports 3080/8080/3000)
- 🎨 **Custom Icon**: Supports custom icons with automatic size generation
- 🌐 **Universal Binary**: Supports both Apple Silicon and Intel Macs
- ⚡ **Minimal Design**: No bundled DSH runtime, relies on local installation
- 📥 **Download Support**: Properly handles file download dialogs
- ⌨️ **Full Shortcuts**: Cmd+C/V, Cmd+R refresh, Cmd+Q quit, etc.

### System Requirements

- macOS 13.0 or later
- DeepSeek Harness (DSH) installed and running
- Apple Silicon or Intel processor

### Installation

#### Option 1: Download Pre-built Release (Recommended)

1. Go to the [Releases](https://github.com/EchoZuo/deepseek-harness-desktop/releases) page
2. Download the latest `deepseek-harness-desktop-mac.zip`
3. Extract and drag `DSH Shell.app` to your Applications folder
4. On first run, if you see "cannot be opened because the developer cannot be verified", right-click the app → Open

#### Option 2: Build from Source

```bash
git clone https://github.com/EchoZuo/deepseek-harness-desktop.git
cd dsh-mac-shell
bash build.sh
```

After building, `DSH Shell.app` will appear in the current directory.

### Custom Icon

The project includes an icon generation tool `makeicon.swift` that converts your PNG image to macOS app icons:

```bash
swift makeicon.swift your-icon.png AppIcon.iconset
iconutil -c icns AppIcon.iconset -o AppIcon.icns
```

Then copy `AppIcon.icns` to `DSH Shell.app/Contents/Resources/`.

The icon will automatically have 20% padding and rounded corners to match macOS system style.

### Usage

1. Ensure DSH is running (`dsh web` command)
2. Launch DSH Shell
3. The app will automatically detect and load the DSH Web UI
4. If not detected, click the "Retry Detection" button

### FAQ

**Q: Why do I need to run DSH separately?**

DSH Shell is a pure window application that doesn't include the DSH runtime. This design keeps the app lightweight and gives you flexibility to control DSH version and configuration.

**Q: Does it support remote DSH instances?**

The current version only supports local instances (localhost). Remote support can be added by modifying the port detection logic in the source code.

**Q: How do I update?**

Download the latest zip from Releases and replace the old version in Applications. Your configuration is stored in DSH and won't be lost.

### Technical Details

- **Architecture**: SwiftUI + WKWebView
- **Build**: Universal Binary support (arm64 + x86_64)
- **Deployment Target**: macOS 13.0+
- **Signing**: Ad-hoc signing (for local use) or configurable developer certificate
- **Sandbox**: Enabled by default for security

### License

MIT License - See [LICENSE](LICENSE) file for details

---

<div align="center">

Made with ❤️ for the DeepSeek Harness community

</div>
