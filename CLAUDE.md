# PNGOptimKit

> Swift 封装 pngoptim PNG 有损压缩引擎，通过 C FFI + XCFramework 让 macOS/iOS 应用直接调用。

## 项目概况

- **目标**：纯 Swift 分发包，提供 pngoptim 的 Swift-idiomatic API
- **上游依赖**：[pngoptim](https://github.com/okooo5km/pngoptim)（Rust PNG 量化引擎，构建 XCFramework 并通过 dispatch 自动更新）
- **参考模式**：rust-nostr/nostr-sdk-swift — source repo 构建一切，dist repo 极简分发

## 技术栈

- Swift 5.9+ / SwiftPM
- XCFramework（预构建二进制，来自 pngoptim 仓库的 release）
- 测试：Swift Testing

## 项目结构

```
pngoptim-swift/
  Package.swift                    # SPM 包定义（始终使用 remote binary target）
  Sources/
    CPNGOptim/                     # C bridge target（头文件 + modulemap）
    PNGOptimKit/                   # Swift API（PNGOptim.optimize）
  Tests/
    PNGOptimKitTests/              # swift-testing 测试
  docs/                            # 项目文档
  .github/workflows/
    ci.yml                         # CI：swift build + swift test
    update.yml                     # 自动更新：接收 pngoptim dispatch → 更新 Package.swift
```

## 开发约定

- 代码和注释使用英文，交流使用中文
- 新文件署名：okooo5km(十里)
- 文档（除 CLAUDE.md 和 README.md）存放于 `docs/` 目录
- 部署目标：macOS 10.15+ / iOS 13+
- Swift API 中时间类型使用 `TimeInterval`（兼容 macOS 10.15）
- API 变更时同步更新 `docs/usage.md` 和 `README.md` 中的对应文档

## 常用命令

```bash
# Swift 构建和测试（自动下载 remote XCFramework）
swift build
swift test
```

## 发版流程

**核心原则：pngoptim-swift 是纯分发仓库，所有构建在 pngoptim 仓库完成。**

1. pngoptim 仓库打 tag（如 `v0.4.2`）
2. pngoptim 的 release workflow 构建 XCFramework → 计算 checksum → dispatch 到 pngoptim-swift
3. pngoptim-swift 的 update workflow 自动：下载 XCFramework → 验证 checksum → 更新 Package.swift + Version.swift + header → 构建测试 → commit + tag + release
4. 消费者 `swift package update` 即可获取新版本

手动触发备用：通过 workflow_dispatch 手动传入 version / url / checksum。

## 架构层次

```
Swift App → import PNGOptimKit → CPNGOptim (C bridge) → PNGOptimCore (XCFramework) → pngoptim (Rust)
```

## FFI 接口

- `pngoptim_default_options()` → 默认选项
- `pngoptim_process(input, len, options)` → 处理 PNG，返回 `*mut PNGOptimResult`
- `pngoptim_result_free(result)` → 释放结果内存

## 错误码

| 代码 | 含义 |
|------|------|
| 0 | 成功 |
| 1 | 参数错误 |
| 2 | I/O 错误 |
| 3 | 解码失败 |
| 4 | 编码失败 |
| 98 | 质量过低 |
| 99 | 跳过（输出更大） |
