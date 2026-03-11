# PNGOptimKit

> Swift 封装 pngoptim PNG 有损压缩引擎，通过 C FFI + XCFramework 让 macOS/iOS 应用直接调用。

## 项目概况

- **目标**：将 Rust pngoptim 的 `process_png_bytes` API 通过 C FFI 导出，打包为 XCFramework，提供 Swift-idiomatic 的 API
- **上游依赖**：[pngoptim](https://github.com/okooo5km/pngoptim) v0.4.1（Rust PNG 量化引擎，支持 APNG）
- **参考项目**：[SVGift](https://github.com/okooo5km/SVGift)（svgo-swift）

## 技术栈

- Swift 5.9+ / SwiftPM
- Rust (staticlib via C FFI)
- cbindgen（自动生成 C 头文件）
- XCFramework（多架构分发）
- 测试：Swift Testing

## 项目结构

```
pngoptim-swift/
  Package.swift                    # SPM 包定义（useLocalFramework 开关）
  Sources/
    CPNGOptim/                     # C bridge target（头文件 + modulemap）
    PNGOptimKit/                   # Swift API（PNGOptim.optimize）
  Tests/
    PNGOptimKitTests/              # swift-testing 测试
  rust/                            # FFI crate（pngoptim-ffi）
    Cargo.toml                     # 依赖 pngoptim git tag v0.4.1
    src/lib.rs                     # C ABI 导出函数
    build.rs                       # cbindgen 生成 generated/pngoptim.h
  scripts/
    build-xcframework.sh           # 交叉编译 + XCFramework 打包
  docs/                            # 项目文档
  .github/workflows/               # CI/CD
```

## 开发约定

- 代码和注释使用英文，交流使用中文
- 新文件署名：okooo5km(十里)
- 文档（除 CLAUDE.md 和 README.md）存放于 `docs/` 目录
- 部署目标：macOS 10.15+ / iOS 13+
- Swift API 中时间类型使用 `TimeInterval`（兼容 macOS 10.15）
- FFI 使用 `std::ffi::c_char`（不依赖 libc crate）
- API 变更时同步更新 `docs/usage.md` 和 `README.md` 中的对应文档

## 常用命令

```bash
# Rust FFI 编译
cd rust && cargo build --release

# 构建 XCFramework（本地开发）
bash scripts/build-xcframework.sh --local-only

# 构建 XCFramework（完整 5 架构）
bash scripts/build-xcframework.sh

# Swift 构建和测试
swift build
swift test
```

## 发版流程

**核心原则：main 分支始终 `useLocalFramework = true`，release tag 由 CI 自动处理。**

1. 确保 main 代码就绪，Package.swift 为 `useLocalFramework = true`
2. 打 tag：`git tag vX.Y.Z && git push origin vX.Y.Z`
3. release workflow 自动：构建 XCFramework → 计算 checksum → 修改 Package.swift（`false` + checksum + URL）→ retag → 创建 Release
4. **workflow 不会推回 main**，tag commit 是独立的发布快照

重新发版：`gh release delete vX.Y.Z` → `git tag -f vX.Y.Z && git push -f origin vX.Y.Z`

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
