<h1 align="center">
  📺 Dpad
  <br>
  <span style="font-size: 0.6em; font-weight: normal;">Flutter TV 应用的 D-pad 导航</span>
</h1>

<p align="center">
  <a href="https://github.com/fluttercandies/dpad/blob/main/README.md">
    <img src="https://img.shields.io/badge/📖-English-red.svg" alt="English">
  </a>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/fluttercandies/dpad/main/dpad.png" alt="Dpad Logo" width="200">
</p>

<p align="center">
  <a href="https://pub.dev/packages/dpad">
    <img src="https://img.shields.io/pub/v/dpad.svg" alt="Pub Version">
  </a>
  <a href="https://github.com/fluttercandies/dpad">
    <img src="https://img.shields.io/badge/platform-android%20tv%20%7C%20fire%20tv%20%7C%20apple%20tv-blue.svg" alt="Platform">
  </a>
  <a href="https://github.com/fluttercandies/dpad/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License">
  </a>
</p>

<div align="center">
  <strong>符合 TV 用户直觉的焦点系统 —— 带记忆的导航区域、光束式方向遍历、按压反馈，以及永远不会"失灵"的遥控器。</strong>
</div>

## 为什么选择 Dpad？

Flutter 内置的方向焦点只会选择几何上*最近*的组件。在真实的 TV 布局里，这意味着焦点会在侧边栏和内容区之间"串道"、跳行、逃出轮播，还会忘记你刚才停留的位置。Dpad 用 TV 平台真正使用的模型（Android 的 `FocusFinder` / Leanback）重写了这套引擎：

- **🗂 带记忆的区域** —— 侧边栏、海报行、网格：每个 `DpadRegion` 优先在内部移动焦点；再次进入时，焦点回到你离开时的那一项。
- **📐 光束式遍历** —— 与当前焦点对齐的候选项优先于斜向候选项。按"下"就是下，而不是"差不多是下，还稍微偏右"。
- **🧲 逐轴边缘控制** —— 在每个区域边界上选择离开（leave）、停止（stop）或环绕（wrap）。轮播环绕、面板停止，其余自然流动。
- **🛟 焦点永不丢失** —— 应用启动即有焦点，push 的新页面无需 `autofocus` 也会自动获得初始焦点，列表刷新、对话框关闭、应用从后台恢复都不会让焦点消失。没有焦点的遥控器就是坏掉的遥控器，Dpad 让这种状态不可能出现。
- **⏯ 真实的遥控器语义** —— 选择 / 长按选择（带按压态视觉）、返回 / 菜单键、应用级快捷键、按键连发 —— 在文本框编辑期间全部自动让位，绝不劫持输入。
- **⌨️ 文本框的正确姿势** —— 文本中间方向键移动光标；光标到达边缘（以及单行输入框的上下键）时方向键正常移出焦点，遥控器用户永远不会被困在搜索框里；IME 拼字期间按键完全归输入法。
- **📜 懒加载列表感知** —— 下一项还没构建出来时（`ListView.builder`），Dpad 会先滚动再继续导航，而不是停在缓存边界。
- **🖱 混合输入** —— 点按与鼠标开箱即用，方便触屏 TV 与桌面调试。
- **🔍 内置焦点检查器** —— `debugOverlay: true` 实时框出当前焦点及其标签、区域、尺寸。TV 上的焦点 bug 不可见，没有它寸步难行。

一切都构建在 Flutter 自身的焦点体系之上（`FocusTraversalPolicy`、`Shortcuts`、`Actions`）—— 不劫持按键，与普通 `Focus`、`TextField`、对话框完全互通。

## 快速开始

### 1. 添加依赖

```yaml
dependencies:
  dpad: ^3.0.0
```

### 2. 安装根组件（一行）

```dart
import 'package:dpad/dpad.dart';

MaterialApp(
  builder: Dpad.wrap(),   // 覆盖所有路由、对话框与底部面板
  home: const HomePage(),
)
```

### 3. 让组件可聚焦

```dart
DpadFocusable(
  autofocus: true,
  onSelect: () => playMovie(movie),
  child: PosterCard(movie),
)
```

这就是一个可用的 TV 应用了：方向键 / 遥控器移动焦点（默认缩放 + 描边效果，可主题化），中键触发 `onSelect`，焦点项自动滚动进入视野并为光晕预留空间。

## 区域：像 TV 应用一样组织界面

```dart
Row(
  children: [
    // 侧边栏：焦点永远不会从屏幕上下两端"掉出去"，
    // 并记住所选目的地。
    DpadRegion(
      verticalEdge: DpadEdgeBehavior.stop,
      child: SidebarColumn(...),
    ),
    Expanded(
      child: ListView(
        children: [
          for (final row in rows)
            // 每个海报行都记住自己的位置。向下再回来，
            // 焦点回到同一张海报 —— 与所有真实 TV 应用一致。
            DpadRegion(
              child: SizedBox(
                height: 200,
                child: ListView(scrollDirection: Axis.horizontal,
                    children: row.cards),
              ),
            ),
        ],
      ),
    ),
  ],
)
```

### 进入区域

`DpadRegion(enter: ...)` 决定焦点跨入时落在哪一项：

| `DpadEnterBehavior` | 落点 |
|---|---|
| `restore`（默认） | 上次聚焦的项；依次回退到位置最近的项、`entry` 项、几何目标 |
| `entry` | 标记了 `DpadFocusable(entry: true)` 的项 |
| `nearest` | 几何上最近的项（Flutter 原生行为） |

### 离开区域

每个方向独立决定边界行为 —— 先用 `horizontalEdge` / `verticalEdge` 设定整轴默认，
再用 `leftEdge` / `rightEdge` / `upEdge` / `downEdge` 覆盖任意单侧：

| `DpadEdgeBehavior` | 效果 |
|---|---|
| `leave`（默认） | 焦点继续移动到区域外的最佳目标 |
| `stop` | 按键被消费，焦点不动，触发 `onEdge`（做撞墙动画、音效） |
| `wrap` | 焦点环绕到区域另一侧 —— 轮播 |
| `lineWrap` | 焦点换行到下一条网格线：行尾按右落到下一行行首（按左反之）；到达网格首/末行时触发 `onEdge`；懒加载网格会滚动构建出下一行 |

```dart
DpadRegion(
  horizontalEdge: DpadEdgeBehavior.wrap,   // 无限循环的剧集轮播
  onEdge: (direction) => playBumpSound(),
  onFocusChange: (inside) => setState(() => highlighted = inside),
  child: episodeRow,
)

// 网格：行间换行，横向永远不出区域。
DpadRegion(
  horizontalEdge: DpadEdgeBehavior.lineWrap,
  child: settingsGrid,
)

// 一行末尾停住，但左侧仍能回到导航栏。
DpadRegion(
  horizontalEdge: DpadEdgeBehavior.stop,
  leftEdge: DpadEdgeBehavior.leave,        // 只有导航栏这一侧可以离开
  child: row,
)
```

方向名都是**物理方向** —— 即遥控器按键的方向 —— 在 RTL 布局下含义不变。
与阅读顺序相关的行为（网格换行、初始焦点落点）会自动适配 RTL。

### 跨重建持久的记忆

基于 State 的记忆会在分区切换重建子树时丢失 —— 这是"切换标签页就忘记位置"的经典 TV 坑。给区域一个稳定的 key，记忆就能跨任意重建持久存在（并按位置感知恢复）：

```dart
DpadRegion(
  memoryKey: 'home/trending-row',
  child: trendingRow,
)
```

## 焦点效果

效果是不可变、可 const、可组合的对象 —— 列表中第一个效果在最外层：

```dart
DpadFocusable(
  effects: const [
    DpadScaleEffect(scale: 1.1),                // 抬起…
    DpadGlowEffect(color: Colors.amber),        // …并发光
  ],
  child: card,
)
```

内置效果：`DpadScaleEffect`（含按压下沉）、`DpadBorderEffect`（不引起布局位移）、`DpadGlowEffect`、`DpadElevationEffect`、`DpadOpacityEffect`（压暗其余项）、`DpadTintEffect`、`DpadCustomEffect`。

一次性设置全局默认：

```dart
MaterialApp(
  builder: Dpad.wrap(
    theme: const DpadThemeData(
      effects: [DpadGlowEffect()],
      scrollPadding: 64,
    ),
  ),
)
```

或者完全自定义 —— 包括选择键的**按压**状态：

```dart
DpadFocusable(
  onSelect: play,
  builder: (context, state, child) => AnimatedScale(
    scale: state.pressed ? 0.97 : (state.focused ? 1.06 : 1.0),
    duration: const Duration(milliseconds: 120),
    child: child,
  ),
  child: card,
)
```

## 遥控器交互

```dart
DpadFocusable(
  onSelect: () => play(),                 // 中键（或点按）
  onLongSelect: () => showOptionsSheet(), // 长按中键
  onFocusChange: (focused) => setState(() => hovered = focused),
  onDirection: (direction) {              // 滑块：消费左右键
    if (direction == TraversalDirection.right) { volumeUp(); return true; }
    if (direction == TraversalDirection.left)  { volumeDown(); return true; }
    return false;                         // 上下键继续导航
  },
  child: volumeRow,
)
```

返回、菜单、应用级快捷键、音效反馈与焦点检查器都挂在根上：

```dart
Dpad.wrap(
  onBack: () {                  // 返回键：先 pop，首页则确认退出
    if (navigator.canPop()) { navigator.pop(); return true; }
    showExitDialog(); return true;
  },
  onMenu: () => showAboutDialog(),
  onFocusChange: (node) {       // 全局焦点"滴答"音效
    if (node != null) audio.playTick();
  },
  shortcuts: {
    LogicalKeyboardKey.keyS: () => openSearch(),
  },
  debugOverlay: kDebugMode,     // 屏上焦点检查器
)
```

以上所有能力 —— 包括方向导航本身 —— 在 `TextField` 获得焦点时都会自动让位，输入永远不会被劫持。

遥控器键值特殊？任意重映射：

```dart
Dpad.wrap(
  keySet: const DpadKeySet().copyWith(
    select: [LogicalKeyboardKey.f1, ...DpadKeySet.defaultSelect],
  ),
)
```

## 编程式控制

```dart
final dpad = Dpad.of(context);

dpad.moveDown();                 // 与按下遥控器方向键完全一致
dpad.move(TraversalDirection.left);
dpad.select();                   // "按下"当前焦点项
dpad.requestFocus(searchNode);   // 跳转焦点（同步更新区域记忆）
dpad.ensureVisible();            // 带留白的滚动进入视野
dpad.focused;                    // 当前焦点节点
```

## TV 最佳实践

从示例应用中提炼，照做即可让复杂 TV 应用保持可预期：

1. **每屏一个 `autofocus`。** 给主要操作（`播放`、第一张卡片）设
   `autofocus: true`。其余情况——push 新页、删除条目、应用恢复——焦点
   都会自动保活。
2. **每个可视分区一个 `DpadRegion`。** 侧边栏、每个内容行、每个网格。
   区域优先遍历 + 焦点记忆是"原生手感"的来源。
3. **分区切换器内的区域使用 `memoryKey`。** 普通 State 随子树销毁而
   消失；带 key 的记忆可跨任意重建存活。
4. **货架布局把 padding 放进滚动视图内部。**

   ```dart
   SizedBox(
     height: cardHeight + 32,                    // 给焦点效果留余量
     child: ListView.builder(
       scrollDirection: Axis.horizontal,
       padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
       ...
     ),
   )
   ```

   缩放与光晕效果会绘制进 padding，而不是被行边缘裁掉。
5. **固定面板边缘用 `stop`，轮播用 `wrap`。** 侧边栏永远不该让焦点
   "掉出"屏幕；剧集条可以循环。
6. **行为接到 `onSelect`，而不是子组件的 `onPressed`。**
   `DpadFocusable` 是唯一焦点停靠点；包裹的 Material 按钮只是视觉。
7. **不要和文本框较劲。** `TextField` 保持裸用（不要包 `DpadFocusable`）；
   方向键在文本中间编辑光标、在边缘自动移出焦点。
8. **用 `debugOverlay: true` 调试。** 隔着客厅看不见焦点 bug；检查器
   实时显示焦点节点、所属区域和几何信息。

## 与 Flutter 的协作方式

- `DpadTraversalPolicy` 是标准的 `FocusTraversalPolicy` —— 普通 `Focus` / `ElevatedButton` 同样参与导航，对话框通过自己的 `FocusScope` 天然困住焦点，路由 pop 后焦点自动回到打开它的那一项。
- `DpadFocusable` 默认排除子树焦点（`excludeChildFocus: true`），包裹按钮也不会产生两个焦点停靠点。子组件需要自己管理焦点时（如 `TextField`）设为 `false`。
- Tab 顺序回退到阅读顺序。

## 示例

[example](https://github.com/fluttercandies/dpad/tree/main/example) 是一个完整的 TV 流媒体界面 —— 跟随焦点展开的侧边栏、带记忆的海报行、环绕式剧集轮播、文本搜索、带 `onDirection` 音量滑块的设置页、长按上下文菜单、返回键退出确认。可在 TV 模拟器或任意桌面运行：

```bash
cd example
flutter run -d macos   # 或 windows、linux、Android TV 模拟器…
```

## 平台支持

| 平台 | 输入 |
|---|---|
| Android TV / Google TV | 遥控器 D-pad、游戏手柄 |
| Amazon Fire TV | Fire TV 遥控器 |
| Apple TV（Web / 自定义嵌入） | Siri Remote 方向键 |
| 桌面（macOS/Windows/Linux） | 方向键 —— 开发调试利器 |
| Web | 方向键（即使 Flutter 默认不映射，Dpad 也会映射） |

要求 Flutter `>= 3.24`。

## 从 2.x 迁移

3.0 是彻底重写，API 更小、更贴近 TV。全局历史栈、规则表与注册标记被声明式组件取代：

| 2.x | 3.0 |
|---|---|
| `DpadNavigator(child: app)` | `MaterialApp(builder: Dpad.wrap())` |
| `Dpad.navigateUp(context)` | `Dpad.of(context).moveUp()` |
| `DpadFocusable(builder: (c, focused, child) ...)` | `builder: (c, state, child)`，使用 `state.focused` / `state.pressed` |
| `FocusEffects.glow()`（闭包） | `effects: const [DpadGlowEffect()]`（const 类） |
| `FocusMemoryOptions` + 历史栈 | 每个 `DpadRegion` 自带记忆（默认 `enter: DpadEnterBehavior.restore`） |
| `RegionNavigationOptions` + `RegionNavigationRule` 规则表 | `DpadRegion(enter: ..., horizontalEdge: ..., verticalEdge: ...)` |
| `DpadFocusable(region: 'tabs', isEntryPoint: true)` | 用 `DpadRegion` 包裹标签栏，标记一项 `entry: true` |
| `customShortcuts:` | `shortcuts:`（编辑文本时自动挂起） |
| `onBackPressed` / `onMenuPressed` | `onBack`（返回 `bool`）/ `onMenu` |

完整列表见 [CHANGELOG](https://github.com/fluttercandies/dpad/blob/main/CHANGELOG.md)。

## ❤️ 支持一下

- 🌟 [GitHub Star](https://github.com/fluttercandies/dpad)
- 👍 [pub.dev 点赞](https://pub.dev/packages/dpad)
- 🐛 [报告问题](https://github.com/fluttercandies/dpad/issues)

---

**让 Flutter 在电视平台上发光发热！** 🚀📺✨
