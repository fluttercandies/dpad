# Dpad - Flutter TV 导航系统

[![Pub Version](https://img.shields.io/pub/v/dpad.svg)](https://pub.dev/packages/dpad)
[![Platform](https://img.shields.io/badge/platform-android%20tv%20%7C%20fire%20tv%20%7C%20apple%20tv-blue.svg)](https://github.com/fluttercandies/dpad)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/fluttercandies/dpad/blob/main/LICENSE)

一个简单而强大的方向键导航系统，让 Flutter 在 Android TV、Fire TV 和其他电视平台的开发变得像原生 Android 开发一样简单。

## ✨ 特性

- 🎯 **简单设置**：只需 3 步即可开始
- 🎨 **可定制效果**：内置聚焦效果 + 自定义构建器
- 📺 **平台支持**：Android TV、Fire TV、Apple TV 等
- ⚡ **性能优化**：为流畅导航而优化
- 🔧 **程序化控制**：完整的程序化导航 API
- 🎮 **游戏手柄支持**：支持标准控制器

## 🚀 快速开始

### 1. 添加依赖

```yaml
dependencies:
  dpad: ^1.0.0
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
              color: Colors.blue.withValues(alpha: 0.6),
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

### 程序化导航

```dart
// 方向导航
Dpad.navigateUp(context);
Dpad.navigateDown(context);
Dpad.navigateLeft(context);
Dpad.navigateRight(context);

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
