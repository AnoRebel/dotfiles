# Ano Shell Plugin System

## Overview

This directory is reserved for future C++ QuickShell plugins that extend the
Ano shell. The core shell is pure QML/JS, but the architecture is designed to
allow C++ plugins to override or extend functionality.

## Extension Points

The following singletons are designed as extension points where a C++ plugin
could provide an alternative implementation:

### CompositorService (services/CompositorService.qml)
- Add support for additional compositors (Sway, KWin, etc.)
- Provide native toplevel sorting for new compositors
- Override `detectCompositor()` to add new detection logic

### NiriService (services/NiriService.qml)
- Replace the QML-based socket implementation with native C++ for better performance
- Add support for Niri features that require binary protocol parsing

### AnimationConfig (modules/common/AnimationConfig.qml)
- Replace with a physics-based animation engine
- Add Lottie or Rive animation support
- Implement spring-based animations

### MaterialThemeLoader (services/MaterialThemeLoader.qml)
- Replace color extraction with native C++ implementation
- Add support for additional color scheme algorithms

## How to Add a Plugin

1. Create your C++ plugin as a QuickShell module
2. Place the compiled `.so` file in this directory
3. Register it in your `shell.qml` with the appropriate import
4. The plugin singleton will shadow the QML singleton of the same name

## Plugin Conventions

- Plugin files should be named `lib<PluginName>.so`
- Each plugin should provide a `qmldir` file
- Plugins must be compatible with QuickShell v0.2.1+
- Document any new QML types in a README within the plugin subdirectory
