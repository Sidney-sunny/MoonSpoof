# 验收检查

[English](ACCEPTANCE.md)

2026-10-30 使用 `moonc v0.10.18+6c83a7f62`、`moon 0.1.20261028` 检查。本文按负责人提供的九项要求记录工程证据，是仓库文档，不是提交表格，也不代表官方已验收。

## 九项检查结果

第 1–8 项有实现和验证证据。第 9 项已在当前源码及待发布归档中修复，但 Mooncakes 已发布的 0.1.0 缺少本次保留的第三方声明，需发布新版本后，才能声称完整分发包满足全部九项。本次未发布新的注册表版本。

| 要求 | 状态 | 可复现证据 |
| --- | --- | --- |
| 1. 主要使用 MoonBit，编译器不低于 0.10.16 | 按要求使用 0.10.18，通过 | [.moon-version](../.moon-version)固定 `0.10.18+6c83a7f62`；[版本检查](../tools/verify-toolchain.py)核对实际编译器。核心算法、门面、接入均为 MoonBit，共 41 个跟踪源码/测试文件 |
| 2. GitHub 公开，提交清晰 | 通过 | [仓库](https://github.com/Sidney-sunny/MoonSpoof)、[提交历史](https://github.com/Sidney-sunny/MoonSpoof/commits/main/)；上传核对 `Sidney-sunny` 认证、作者及提交者 |
| 3. 结构清晰，核心功能可用 | 在声明范围内通过 | [实现范围](SPECIFICATION_zh.md)、[API](API_SPECIFICATION_zh.md)、97 项 MoonBit 测试；不声明完整 UTS #39 合规 |
| 4. README、安装、用法与样例 | 通过 | [README](../README.md)、[中文指南](README_zh.md)；独立模块实测 `moon add Sidney-sunny/moonspoof` 及公开导入 |
| 5. CI 覆盖检查、构建、测试 | 同版本 CI 运行成功后通过 | [工作流](../.github/workflows/ci.yml)对 WASM、JS、native 显式执行编译器核验与 check/build/test；[Actions](https://github.com/Sidney-sunny/MoonSpoof/actions)另验证生成器、ABI/构建、Unicode、ICU 和注册表安装 |
| 6. 可运行示例 | 通过 | `moon run cmd/registration`、`moon run cmd/main`；[接入指南](../examples/registration/README_zh.md)。从 `3051c64` 干净跟踪源码导出运行接入与 97 项测试 |
| 7. 核心路径测试 | 通过 | 97 项 MoonBit、19 项生成器、14 项 ABI/Worker、7 项参考工具测试，4,456,448 项全码点属性断言、官方 NFD/映射验证及 [ICU 覆盖](REFERENCE_COMPARISON_zh.md) |
| 8. 发布到 mooncakes.io | 0.1.0 已满足 | [公开包](https://mooncakes.io/modules/Sidney-sunny/moonspoof)列出未撤回的 0.1.0，发布于 2026-10-23；[干净消费验证](../tools/verify-registry-consumer.py)在 0.10.18 下运行 WASM/JS 键、属性和策略检查 |
| 9. OSI 许可证及上游条款 | 源码/归档已修复；已发布包待更新 | [Apache-2.0](../LICENSE)获 [OSI 认可](https://opensource.org/license/apache-2-0)；[上游声明](THIRD_PARTY_NOTICES_zh.md)、许可证全文及生成署名已保留，站点产物含副本。注册表已有 0.1.0 无法覆盖 |

## 复现检查

使用固定编译器。CI 官方安装器读取 `MOONBIT_INSTALL_VERSION`，版本检查拒绝其他构建。

```powershell
moon version --all
uv run --no-project python tools/verify-toolchain.py
moon check
moon build --target wasm
moon test
moon test --target js
moon run cmd/registration
uv run --no-project python tools/verify-registry-consumer.py
pnpm --dir playground install --frozen-lockfile
pnpm --dir playground run check
pnpm --dir playground run verify:unicode
pnpm --dir playground run verify:icu
moon info
moon fmt
```

Linux/CI 可用 `python3` 执行标准库脚本。ICU 需要 PATH 中有 `java`、`javac`；本次使用进程内 JDK 21.0.10.0.10。native 由 Ubuntu CI 验证，本文不声称 Windows 本地 native 构建通过。生成后执行 `moon info`、`moon fmt`，应复现已提交表与接口。

消费验证使用新临时模块、固定注册表依赖，不覆盖为本地源码；可能复用包管理器下载缓存。安装注册表 0.1.0 不会获得本次源码、编译器固定或声明变更。

## 剩余分发动作

发布包含编译器兼容源码及上游声明的新版本。`moon package --list` 已验证包含 `LICENSE`、`THIRD_PARTY_NOTICES.md` 和两份许可证全文。对未变更的 0.1.0 执行发布验证会报告重复版本冲突，未替换已有产物。密钥、保存凭据和私有资料不进入归档或 Git 历史。已使用专用环境变量密钥，将 Mooncakes 保存账号改为 `Sidney-sunny`。

[路线图](ROADMAP_zh.md)另行保留测量、兼容性复核及拟议 v0.2.0 发布门槛；这些目标不改变本次九项要求。本文不认证外部采用或尚未发布的版本。
