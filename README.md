# XMusic - 现代 macOS 音乐播放器

一款专为 macOS 设计的现代化音乐播放器，支持多种音频格式，提供直观的用户界面和完整的音乐管理功能。

## 🎵 功能特性

### 音频格式支持
- ✅ **FLAC** - 无损音频压缩格式
- ✅ **WAV/WAVE** - 无损音频格式
- ✅ **MP3** - 有损压缩音频格式
- ✅ **M4A/AAC** - Apple 音频格式
- ✅ **AIFF** - 音频交换文件格式
- ✅ **更多格式** - AU, SND, SD2, CAF

### 界面设计
- 🎨 **现代化 SwiftUI 界面**
- 🌙 **原生支持深色模式**
- 📱 **三栏式导航布局**
- ✨ **无标题栏窗口设计**
- 🖼️ **专辑封面显示**
- 🎯 **响应式播放状态指示**

### 音乐库管理
- 📁 **文件夹扫描导入**
- 📄 **单文件/多文件添加**
- 🔍 **实时搜索功能**
- 📚 **自动专辑分类**
- 🎤 **艺人管理**
- 📋 **播放列表创建和管理**
- 💾 **音乐库持久化**

### 播放控制
- ▶️ **播放/暂停**
- ⏭️ **上一首/下一首**
- 🔀 **播放列表导航**
-  **进度条拖动**
- 🔊 **音量调节**
- 🎵 **播放状态可视化**

## 🖥️ 系统要求

- **macOS 15.0** 或更高版本
- **Apple Silicon (ARM64)** 或 **Intel Mac**
- **Swift 6.0** 或更高版本

## 🚀 安装使用

### 方法 1: 直接运行
```bash
cd /path/to/xmusic
./build.sh
open build/XMusic.app
```

### 方法 2: 使用 Xcode
1. **安装 xcodegen**（如果还没安装）
   ```bash
   brew install xcodegen
   ```
2. **生成 Xcode 项目**
   ```bash
   cd /path/to/xmusic
   xcodegen generate
   ```
3. **打开生成的 Xcode 项目**
   ```bash
   open XMusic.xcodeproj
   ```
4. **点击运行按钮** (⌘+R)

## 📖 使用指南

### 添加音乐
1. **点击工具栏的 "+", 按钮** 添加单个或多个音频文件
2. **点击工具栏的 "文件夹" 按钮** 扫描整个文件夹

### 浏览音乐库
- **歌曲**: 查看所有导入的歌曲列表
- **专辑**: 按专辑浏览，支持专辑详情查看
- **艺人**: 按艺人浏览，查看艺人的所有专辑和歌曲
- **播放列表**: 创建和管理自定义播放列表

### 播放控制
- **点击任意歌曲** 开始播放
- **使用右侧的播放控制面板** 控制播放
- **拖动进度条** 跳转到指定位置
- **调节音量滑块** 控制音量

### 播放列表管理
- **右键点击播放列表** 删除不需要的播放列表
- **在歌曲上点击右键** 添加到播放列表（功能开发中）

## 📁 项目结构

```
xmusic/
├── XMusic/
│   ├── Sources/
│   │   ├── Main.swift              # 应用入口
│   │   ├── Models/
│   │   │   ├── AudioPlayer.swift   # 音频播放器核心
│   │   │   ├── MusicLibrary.swift  # 音乐库管理
│   │   │   └── Track.swift         # 歌曲模型
│   │   └── Views/
│   │       ├── ContentView.swift   # 主界面
│   │       ├── SidebarView.swift   # 侧边栏
│   │       ├── ContentAreaView.swift   # 内容区域
│   │       ├── NowPlayingView.swift    # 正在播放
│   │       ├── AlbumGridView.swift     # 专辑网格
│   │       ├── ArtistListView.swift    # 艺人列表
│   │       └── PlaylistGridView.swift  # 播放列表
│   └── Info.plist
├── build.sh                        # 构建脚本
├── project.yml                     # xcodegen 配置文件
├── .gitignore                      # Git 忽略文件
└── README.md                       # 项目说明文档
```

## 🛠️ 技术栈

- **语言**: Swift 6.0
- **UI 框架**: SwiftUI
- **音频播放**: AVFoundation
- **架构模式**: MVVM
- **状态管理**: ObservableObject + @Published
- **文件系统**: FileManager
- **数据持久化**: UserDefaults + JSON

## 📝 开发说明

### 构建命令
```bash
swiftc -target arm64-apple-macos15.0 \
       -sdk /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk \
       -framework Foundation \
       -framework AppKit \
       -framework SwiftUI \
       -framework AVFoundation \
       -o build/XMusic \
       XMusic/Sources/Main.swift \
       XMusic/Sources/Models/*.swift \
       XMusic/Sources/Views/*.swift
```

### 核心功能实现

#### 音频播放
- 使用 `AVAudioPlayer` 实现音频播放
- 支持播放、暂停、音量调节
- 实现播放进度追踪和更新

#### 音乐库管理
- 支持文件夹扫描和文件导入
- 自动分类专辑和艺人
- 实现播放列表创建和管理
- 使用 `UserDefaults` 持久化音乐库

#### 用户界面
- 使用 `NavigationSplitView` 实现三栏布局
- 响应式设计，适配不同窗口大小
- 实时播放状态指示
- 原生文件选择器集成

### 代码亮点

1. **模块化设计**: 清晰的职责分离，便于维护和扩展
2. **异步编程**: 使用 `async/await` 处理音频元数据加载
3. **响应式状态管理**: 使用 `ObservableObject` 和 `@Published`
4. **错误处理**: 完整的错误捕获和处理机制
5. **性能优化**: 后台线程文件扫描，避免 UI 阻塞
6. **用户体验**: 流畅的动画和状态指示

## 📄 许可证

MIT License

## 👨‍💻 作者

Kevin Zhang@20260211

---

**XMusic** - 用 Swift 打造的现代音乐体验 🎵
