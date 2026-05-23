# Onedayday（一天天）

> *Make every day count. / 让每一天都有迹可循。*

<p align="center">
  <img src="LOGO.png" width="128" alt="Onedayday logo">
</p>

---

## 👋 这是一个怎样的软件？

似乎每一个被 AI 时代浪潮击中的人，他们的 Vibe Coding 之旅都是从一个 Todo List 软件开始的。我也不例外。

在寻找完美 Todo List 的路上，我总是觉得市面上的工具要么太重，要么不够直觉。我真正需要的是：能用**四象限**理清轻重缓急，又能用**时间轴**把任务直接安顿到具体的时段里。

于是，借助 AI 的力量，我为自己量身打造了 Onedayday。它不是什么庞大的商业项目，而是一个绝对安静、极度纯粹的 Mac 本地效率中枢。

---

## ✨ 核心体验

| | |
|---|---|
| 🧭 **四象限法则** | 拒绝无脑堆砌的列表。将任务按“重要 / 紧急”分类，一眼看清该先做什么。 |
| ⏳ **直觉式时间轴** | 把四象限里的任务直接拖拽到右侧时间轴上，为你的一天排兵布阵。 |
| 🍅 **沉浸番茄钟** | 点击任务进入全屏专注模式，隔绝一切干扰。 |
| 🟩 **多巴胺热力图** | 像 GitHub 贡献图一样记录你的日常！看着格点一天天变绿，这是最好的正反馈。 |
| 🛡️ **绝对的隐私安全** | 100% 本地运行，无需联网，没有账号，不传云端。你的数据只存在你自己的 Mac 里。 |

---

## 📥 极简安装（开箱即用）

1. 前往仓库的 [**Releases**](https://github.com/adrianyaoma-commits/Onedayday/releases) 页面。
2. 下载最新版本的 `Onedayday.zip`。
3. 解压后，将 `Onedayday.app` 直接拖入 Mac 的 **「应用程序 (Applications)」** 文件夹中。

> ⚠️ **首次运行提示**：因为是独立开发者作品，首次打开可能会被 macOS 拦截。只需在「应用程序」文件夹中找到它，按住键盘的 **Control** 键并点击图标，在菜单中选择 **「打开」** 即可正常运行。

---

## 🧱 技术栈

| | SwiftUI（主力） | Python（替代） |
|---|---|---|
| 语言 | Swift 5 | Python 3 |
| UI | SwiftUI (macOS 13+) | CustomTkinter（深色主题） |
| 架构 | MVVM + `@EnvironmentObject` | 单体 |
| 持久化 | JSON（App Group + Documents） | JSON |
| 系统集成 | Spotlight、MenuBarExtra、触觉反馈 | `subprocess.open` |
| 构建 | Xcode | PyInstaller |

从源码构建：

```bash
# SwiftUI 版本
open Onedayday.xcodeproj   # 需要 Xcode 15+，选择 My Mac → Cmd+R

# Python 替代版本
pip install customtkinter
python3 app.py
```

---

## 📂 项目结构

```
Onedayday/
├── Onedayday/                   # SwiftUI 原生 macOS 应用
│   ├── OnedaydayApp.swift       # @main 入口（Window + MenuBarExtra）
│   ├── Models/
│   │   ├── TodoItem.swift       # 核心任务数据模型
│   │   ├── DeviceConfig.swift   # 设备配置
│   │   └── TaskTemplate.swift   # 任务模板模型
│   ├── ViewModels/
│   │   ├── TodoViewModel.swift  # 任务 CRUD、时间轴、热力图、Spotlight
│   │   ├── SettingsViewModel.swift  # 设备 & 模板持久化
│   │   └── LocalizationManager.swift  # zh/en/fr/ja 字符串表
│   ├── Services/
│   │   └── SpotlightIndexer.swift   # Core Spotlight 索引
│   └── Views/
│       ├── ContentView.swift        # 主窗口布局
│       ├── QuadrantPanel.swift      # 四象限面板（×4）
│       ├── TaskRowView.swift        # 任务行（hover 操作）
│       ├── AddTaskSheet.swift       # 统一的添加/编辑表单
│       ├── CustomCalendarView.swift # 自定义月历
│       ├── TimelinePanel.swift      # 每日时间轴
│       ├── TimeBlockView.swift      # 时间块（拖拽调整大小）
│       ├── HeatmapView.swift        # 贡献热力图
│       ├── FocusModeView.swift      # 全屏番茄钟浮层
│       ├── MenuBarView.swift        # 菜单栏弹出窗口
│       ├── InboxView.swift          # 收集箱/快速记录
│       ├── HeaderView.swift         # 日期头部 + 进度环
│       ├── SettingsGear.swift       # 设置齿轮图标
│       └── Settings/
│           └── SettingsView.swift   # 4 标签页设置面板
├── app.py                       # Python/CustomTkinter 替代版
├── app.spec                     # app.py 的 PyInstaller 配置
├── LOGO.png                     # 应用 Logo
└── PrivacyInfo.xcprivacy        # Apple 隐私清单
```

---

## 🌍 多语言

| 语言 | 覆盖 |
|---|---|
| 中文 (zh) | 默认语言 |
| English (en) | 完整覆盖 |
| Français (fr) | 完整覆盖 |
| 日本語 (ja) | 完整覆盖 |

在设置中切换语言，UI 即时刷新。

---

## 💬 写在最后

软件完全开源免费。如果你在使用中遇到问题，或者有让它变得更好的好点子，非常欢迎在 [Issues](https://github.com/adrianyaoma-commits/Onedayday/issues) 里面给我留言。

让大目标落地，一天天去完成它。希望 Onedayday 也能帮到你。
