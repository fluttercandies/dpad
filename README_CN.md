<h1 align="center">
  📺 Dpad
  <br>
  <span style="font-size: 0.6em; font-weight: normal;">Flutter TV 导航系统</span>
</h1>

<p align="center">
  <a href="README.md">
    <img src="https://img.shields.io/badge/📖-文档切换-red.svg" alt="English">
  </a>
</p>

<p align="center">
  <img src="dpad.png" alt="Dpad Logo" width="200">
</p>

<br>

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

<div align="center" style="padding: 20px; max-width: 600px; margin: 0 auto; text-align: center;">
一个简单而强大的方向键导航系统，让 Flutter 在 Android TV、Fire TV 和其他电视平台的开发变得像原生 Android 开发一样简单。
</div>

## ✨ 特性

- 🎯 **简单设置**：只需 3 步即可开始
- 🎨 **可定制效果**：内置聚焦效果 + 自定义构建器
- 📺 **平台支持**：Android TV、Fire TV、Apple TV 等
- ⚡ **性能优化**：为流畅导航而优化
- 🔧 **程序化控制**：完整的程序化导航 API
- 🎮 **游戏手柄支持**：支持标准控制器
- 🔄 **顺序导航**：支持媒体和列表的上一个/下一个导航

## 🚀 快速开始

### 1. 添加依赖

```yaml
dependencies:
  dpad: any
```

### 2. 包装你的应用

```dart
import 'package:dpad/dpad.dart';

void main() {
  runApp(
    DpadNavigator(
      enabled: true,
      child: MaterialApp(
        home: MyApp(),
      ),
    ),
  );
}
```

### 3. 使组件可聚焦

```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DpadFocusable(
          autofocus: true,
          onFocus: () => print('获得焦点'),
          onSelect: () => print('被选中'),
          builder: (context, isFocused, child) {
            return AnimatedContainer(
              duration: Duration(milliseconds: 200),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isFocused ? Colors.blue : Colors.transparent,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: child,
            );
          },
          child: ElevatedButton(
            onPressed: () => print('按下'),
            child: Text('按钮 1'),
          ),
        ),
        
        DpadFocusable(
          onSelect: () => print('按钮 2 被选中'),
          child: ElevatedButton(
            onPressed: () => print('按下'),
            child: Text('按钮 2'),
          ),
        ),
      ],
    );
  }
}
```

## 🎨 聚焦效果

### 内置效果

```dart
// 边框高亮
DpadFocusable(
  builder: FocusEffects.border(color: Colors.blue),
  child: MyWidget(),
)

// 发光效果
DpadFocusable(
  builder: FocusEffects.glow(glowColor: Colors.blue),
  child: MyWidget(),
)

// 缩放效果
DpadFocusable(
  builder: FocusEffects.scale(scale: 1.1),
  child: MyWidget(),
)

// 渐变背景
DpadFocusable(
  builder: FocusEffects.gradient(
    focusedColors: [Colors.blue, Colors.purple],
  ),
  child: MyWidget(),
)

// 组合多个效果
DpadFocusable(
  builder: FocusEffects.combine([
    FocusEffects.scale(scale: 1.05),
    FocusEffects.border(color: Colors.blue),
  ]),
  child: MyWidget(),
)
```

### 自定义效果

```dart
DpadFocusable(
  builder: (context, isFocused, child) {
    return Transform.scale(
      scale: isFocused ? 1.1 : 1.0,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        decoration: BoxDecoration(
          boxShadow: isFocused ? [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.6), // ignore: deprecated_member_use
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        child: child,
      ),
    );
  },
  child: Container(
    child: Text('自定义效果'),
  ),
)
```

## 🔧 高级用法

### 📜 自动滚动 (v1.2.2 新功能)

`DpadFocusable` 现在会自动滚动以确保焦点组件完全可见，包括发光、边框等焦点效果。

```dart
DpadFocusable(
  autoScroll: true,           // 启用自动滚动（默认：true）
  scrollPadding: 24.0,        // 焦点效果的额外边距（默认：24.0）
  builder: FocusEffects.glow(glowColor: Colors.blue),
  child: MyWidget(),
)

// 为特定组件禁用自动滚动
DpadFocusable(
  autoScroll: false,
  child: MyWidget(),
)

// 程序化滚动控制
Dpad.scrollToFocus(
  focusNode,
  padding: 32.0,
  duration: Duration(milliseconds: 300),
  curve: Curves.easeOutCubic,
);
```

## 🧠 焦点记忆 (v1.2.2更新)

焦点记忆系统智能记录用户的焦点位置，并在返回导航时恢复它们，提供更自然的电视导航体验。

### 快速设置

```dart
DpadNavigator(
  focusMemory: FocusMemoryOptions(
    enabled: true,
    maxHistory: 20,
  ),
  onNavigateBack: (context, previousEntry, history) {
    if (previousEntry != null) {
      previousEntry.focusNode.requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  },
  child: MyApp(),
)
```

### 区域标识

```dart
// Tab栏
DpadFocusable(
  region: 'tabs',
  child: TabButton(),
)

// 筛选区域
DpadFocusable(
  region: 'filters',
  child: FilterOption(),
)

// 内容卡片
DpadFocusable(
  region: 'cards',
  child: ContentCard(),
)
```

### 使用场景

- **Tab导航**：Tab A → 浏览 → Tab B → 返回 → Tab B（恢复到之前的Tab）
- **筛选导航**：筛选A → 浏览 → 筛选A → 返回 → 筛选A（恢复到之前的筛选）
- **跨路由导航**：为每个路由维护独立的焦点历史

## 🎯 区域导航 (v2.0.0 新功能)

区域导航解决了 Flutter 默认几何距离导航不符合用户预期的常见 TV UX 问题。

### 问题

使用 Flutter 默认导航时：
- Tab → 内容：可能根据距离聚焦到任意卡片
- 内容 → Tab：可能跳转到意外的 Tab
- 侧边栏 → 网格：焦点可能落在任何位置

### 解决方案

```dart
DpadNavigator(
  regionNavigation: RegionNavigationOptions(
    enabled: true,
    rules: [
      // Tab → 内容：总是聚焦第一张卡片
      RegionNavigationRule(
        fromRegion: 'tabs',
        toRegion: 'content',
        direction: TraversalDirection.down,
        strategy: RegionNavigationStrategy.fixedEntry,
        bidirectional: true,
        reverseStrategy: RegionNavigationStrategy.memory,
      ),
      // 侧边栏 → 网格：总是聚焦第一张卡片
      RegionNavigationRule(
        fromRegion: 'sidebar',
        toRegion: 'grid',
        direction: TraversalDirection.right,
        strategy: RegionNavigationStrategy.fixedEntry,
      ),
    ],
  ),
  child: MyApp(),
)
```

### 标记入口点

```dart
// 内容区域的第一张卡片 - 入口点
DpadFocusable(
  region: 'content',
  isEntryPoint: true,
  child: ContentCard(),
)

// 同一区域的其他卡片
DpadFocusable(
  region: 'content',
  child: ContentCard(),
)
```

### 导航策略

| 策略 | 行为 |
|------|------|
| `geometric` | Flutter 默认的基于距离的导航 |
| `fixedEntry` | 总是聚焦标记为 `isEntryPoint` 的组件 |
| `memory` | 恢复上次聚焦的组件，回退到入口点 |
| `custom` | 使用自定义解析函数 |

### 自定义快捷键

```dart
DpadNavigator(
  customShortcuts: {
    LogicalKeyboardKey.keyG: () => _showGridView(),
    LogicalKeyboardKey.keyL: () => _showListView(),
    LogicalKeyboardKey.keyR: () => _refreshData(),
    LogicalKeyboardKey.keyS: () => _showSearch(),
  },
  onMenuPressed: () => _showMenu(),
  onBackPressed: () => _handleBack(),
  child: MyApp(),
)
```

**默认键盘快捷键（v1.1.0+）：**
- **方向键**：方向导航（上、下、左、右）
- **Tab/Shift+Tab**：顺序导航（下一个/上一个）
- **媒体下一个/上一个**：媒体控制导航
- **频道上/下**：TV 遥控器顺序导航
- **Enter/选择/空格**：触发选择动作
- **Esc/返回**：导航返回
- **菜单键**：显示菜单

### 程序化导航

```dart
// 方向导航
Dpad.navigateUp(context);
Dpad.navigateDown(context);
Dpad.navigateLeft(context);
Dpad.navigateRight(context);

// 顺序导航（v1.1.0+ 新增）
Dpad.navigateNext(context);      // Tab / 媒体下一个
Dpad.navigatePrevious(context);   // Shift+Tab / 媒体上一个

// 焦点管理
final currentFocus = Dpad.currentFocus;
Dpad.requestFocus(myFocusNode);
Dpad.clearFocus();
```

### 平台特定处理

```dart
DpadNavigator(
  onMenuPressed: () {
    // 处理电视遥控器菜单键
    _showMenu();
  },
  onBackPressed: () {
    // 处理返回键
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  },
  child: MyApp(),
)
```

## 📱 平台支持

- **Android TV**：完整的原生方向键支持
- **Amazon Fire TV**：兼容 Fire TV 遥控器
- **Apple TV**：支持 Siri 遥控器（Flutter web）
- **游戏手柄**：标准控制器导航
- **通用电视平台**：任何支持方向键的输入设备

## 💡 最佳实践

1. **始终设置 `autofocus: true`**：每个屏幕上至少设置一个组件以获得初始焦点
2. **使用真实的方向键硬件测试**：不要只用键盘方向键
3. **考虑焦点顺序**：按逻辑排列组件以便导航
4. **提供清晰的视觉反馈**：使用显著的焦点指示器
5. **处理边缘情况**：导航失败时怎么办？

## 🏗️ 架构

系统由三个主要组件组成：

- **DpadNavigator**：捕获方向键事件的根组件
- **DpadFocusable**：使组件可聚焦的包装器
- **Dpad**：用于程序化控制的实用类

所有组件与 Flutter 的焦点系统无缝协作。

## 🔄 迁移

从其他电视导航库迁移？

- ✅ 不需要复杂配置
- ✅ 与标准 Flutter 组件兼容
- ✅ 不需要自定义 FocusNode 管理
- ✅ 内置支持所有电视平台
- ✅ 广泛的自定义选项

## 📖 示例

查看 [示例应用](./example) 了解完整实现，包括：
- 网格导航
- 列表导航
- 自定义聚焦效果
- 程序化导航
- 平台特定处理

## 🤝 贡献

欢迎贡献！请随时提交 Pull Request。

## 📄 许可证

本项目基于 MIT 许可证 - 详情请查看 [LICENSE](LICENSE) 文件。
