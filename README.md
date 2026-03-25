# 小紫桌宠（Qt 6 / QML）

一个基于 **Qt Quick + QML + C++ 桥接** 的桌面宠物应用。  
当前默认形象为 **小紫**（`pet.png`），支持托盘常驻、AI 对话、屏幕雷达、形象切换、聊天历史等能力。

## 先看这个：功能、用法、注意事项

### 你现在可以做什么
- 右键宠物打开菜单：聊天、形象设置、API 设置、雷达设置、任务栏显示切换、退出。
- 左键拖动宠物；左键点击可触发互动气泡。
- 使用 AI 多轮对话（带最近历史上下文）。
- 启用“屏幕雷达”后，定时读取当前活动窗口标题并生成建议。
- 在“雷达设置”里可关闭“乱动模式”，让宠物不再随机移动。
- 在“形象设置”里修改宠物名称，导入本地图片/动图（png/jpg/gif/webp）。

### 快速用法（30 秒）
1. 构建并运行项目。
2. 右键宠物 → **⚙️ 设置 API**，填写 `API URL / 模型名 / API Key`。
3. 右键宠物 → **💬 跟我聊天** 开始对话。
4. 右键宠物 → **🎨 形象设置** 可改名、换本地图像。
5. 右键宠物 → **📡 雷达设置** 可调扫描间隔和“乱动模式”。

### 重要注意事项
- 本项目包含系统级输入能力（鼠标移动、点击、文本输入），仅在你明确知情时使用。  
- “屏幕雷达”读取的是**当前活动窗口标题**，不是截图，不抓取窗口内部像素内容。  
- 若导入了损坏图片，系统会自动回退到默认 `pet.png`。  
- Windows 原生样式下，不建议对控件做深度皮肤重绘（会有样式兼容限制）。

---

## 项目定位

小紫桌宠是一个“**轻量可扩展桌面 Agent UI 容器**”，核心目标是：
- 提供自然的桌面交互入口（宠物/气泡/托盘）。
- 通过设置面板将“模型、行为、形象”解耦。
- 保持 QML 前端快速迭代，C++ 只承载系统能力桥接。

---

## 架构总览

### 1) UI 与交互层（QML）
- 主窗口、宠物渲染、右键菜单、聊天窗、设置窗、雷达窗、历史窗都在 [Main.qml](file:///e:/code/QTproject/Pet/Main.qml)。
- 使用 `Settings` 持久化关键配置（API、行为开关、形象路径与名称）。
- 宠物渲染采用“静态图/动图双通道”策略：
  - 静态图走 `Image`
  - 动图走 `AnimatedImage`
  - 避免 `AnimatedImage` 误读 png 造成的空白问题。

### 2) 系统能力桥接（C++）
- [SystemController.h](file:///e:/code/QTproject/Pet/SystemController.h) / [SystemController.cpp](file:///e:/code/QTproject/Pet/SystemController.cpp)
- 暴露给 QML 的能力：
  - 鼠标移动、点击
  - 文本输入
  - 当前鼠标位置
  - 当前活动窗口标题
- Windows 下使用 `SendInput` / `GetForegroundWindow` 等 WinAPI，非 Windows 环境自动降级为空实现。

### 3) 应用启动与依赖注入
- [main.cpp](file:///e:/code/QTproject/Pet/main.cpp)
- 将 `SystemController` 通过 `QQmlContext` 注入为 `sysCtrl`，供 QML 调用。
- 设置组织名/应用名，确保 `Settings` 可持久化。

### 4) 构建系统
- [CMakeLists.txt](file:///e:/code/QTproject/Pet/CMakeLists.txt)
- 使用 `qt_add_qml_module` 打包 QML 与资源（当前内置 `pet.png`）。

---

## 功能清单（当前实现）

### 核心交互
- 无边框透明置顶桌宠窗口
- 拖拽移动
- 左键互动气泡
- 右键菜单操作
- 系统托盘常驻与菜单

### AI 对话
- 支持 OpenAI 兼容格式接口
- 可配置：URL、模型名、API Key
- 多轮记忆：发送时附带最近 10 条对话
- 失败兜底与响应解析容错

### 雷达能力
- 定时读取活动窗口标题
- 调用模型生成“建议/吐槽/关心”
- 可配置扫描间隔
- 可独立开关“乱动模式”

### 形象系统
- 默认角色名：小紫
- 默认资源：`pet.png`
- 支持本地导入 png/jpg/gif/webp
- 图片加载失败自动回退默认资源

### 数据持久化
- API 配置
- 雷达与行为开关
- 形象名称与资源路径
- 气泡显示时长

---

## 运行环境与平台

### 已验证开发环境
- OS: Windows
- Qt: 6.9.1（MinGW 64-bit 套件）
- CMake: 3.16+
- 编译器：MinGW64（与本地 Qt 套件匹配）

### 平台说明
- UI 层（QML）具备跨平台潜力。
- 系统输入模拟与活动窗口标题读取目前以 Windows 为主实现。

---

## 构建与运行

### Qt Creator（推荐）
1. 打开工程目录。
2. 选择 Qt 6.9.1 MinGW Kit。
3. 构建并运行。

### 命令行
```bash
cmake -S . -B build/Desktop_Qt_6_9_1_MinGW_64_bit-Debug
cmake --build build/Desktop_Qt_6_9_1_MinGW_64_bit-Debug
```

---

## 配置项说明（Settings）

主要配置位于 [Main.qml](file:///e:/code/QTproject/Pet/Main.qml) 的 `Settings` 块：
- `llmApiKey`: 模型 API Key
- `llmApiUrl`: 模型接口地址
- `llmModelName`: 模型名称
- `showInTaskbar`: 是否显示在主任务栏
- `radarEnabled`: 屏幕雷达开关
- `radarInterval`: 雷达扫描间隔（秒）
- `bubbleDuration`: 气泡停留时间（秒）
- `randomMoveEnabled`: 乱动模式开关
- `petName`: 宠物名称（默认“小紫”）
- `petImagePath`: 形象路径（默认 `pet.png`）

---

## 常见问题（FAQ）

### 1) 运行后“什么都看不到”
- 多数是图片路径不可读或格式不匹配导致透明窗口空白。
- 已内置回退机制，默认应回到 `pet.png`。
- 若仍不可见，先确认 [pet.png](file:///e:/code/QTproject/Pet/pet.png) 存在且可读。

### 2) 右键菜单或窗口样式报警告
- Windows 原生样式不支持某些控件部件深度自定义。
- 当前版本已移除高风险样式重载，保留兼容写法。

### 3) 雷达是否会读取隐私内容
- 当前只读取活动窗口标题字符串，不采集屏幕像素。
- 你可随时在“雷达设置”关闭该功能。

---

## 安全与合规建议

- 启用系统输入模拟前，确认你理解其行为影响。  
- 不要把 API Key 写入公开仓库。  
- 对外发布时建议提供“功能总开关”与“权限提示”。  

---

## 可扩展方向（建议）

- 图像粘贴/多模态对话（Vision）
- 动作系统（待机/点击/说话状态机）
- 插件化技能（定时提醒、番茄钟、日程）
- 更细粒度的隐私策略（仅白名单应用启用雷达）

---

## 关键文件导读

- 主界面与业务逻辑：[Main.qml](file:///e:/code/QTproject/Pet/Main.qml)
- 系统能力桥接头文件：[SystemController.h](file:///e:/code/QTproject/Pet/SystemController.h)
- 系统能力桥接实现：[SystemController.cpp](file:///e:/code/QTproject/Pet/SystemController.cpp)
- 应用启动入口：[main.cpp](file:///e:/code/QTproject/Pet/main.cpp)
- 构建脚本：[CMakeLists.txt](file:///e:/code/QTproject/Pet/CMakeLists.txt)

---

如果你希望，我可以在下一步再补一版：
- 面向“使用者”的简版 README（1 页）
- 面向“开发者”的架构文档（模块图 + 数据流图 + 调用时序图）
