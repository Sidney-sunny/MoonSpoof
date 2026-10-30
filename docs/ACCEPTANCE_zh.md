# 验收检查

[English](ACCEPTANCE.md)

2026-10-30 使用 `moonc v0.10.18+6c83a7f62`、`moon 0.1.20261028` 检查。本文按负责人提供的九项要求记录工程证据，是仓库文档，不是提交表格，也不代表官方已验收。

## 九项检查结果

0.2.0 的九项要求均已有工程验证证据。Mooncakes 0.2.0 已发布，并在独立消费项目通过 WASM/JS 与上游声明检查；[GitHub Release](https://github.com/Sidney-sunny/MoonSpoof/releases/tag/v0.2.0)及附注 tag 指向 `a30e36f969c221efc443bc9f1788f021dd7f6891`。下载的附件另行通过清单/校验值验证；原 0.1.0 的声明缺口已通过新版本解决，没有覆盖 0.1.0。这不代表官方已验收。

| 要求 | 状态 | 可复现证据 |
| --- | --- | --- |
| 1. 主要使用 MoonBit，编译器不低于 0.10.16 | 按要求使用 0.10.18，通过 | [.moon-version](../.moon-version)固定 `0.10.18+6c83a7f62`；[版本检查](../tools/verify-toolchain.py)核对实际编译器。核心算法、门面、接入均为 MoonBit，共 43 个跟踪源码/测试文件 |
| 2. GitHub 公开，提交清晰 | 通过 | [仓库](https://github.com/Sidney-sunny/MoonSpoof)、[提交历史](https://github.com/Sidney-sunny/MoonSpoof/commits/main/)；上传核对 `Sidney-sunny` 认证、作者及提交者 |
| 3. 结构清晰，核心功能可用 | 在声明范围内通过 | [实现范围](SPECIFICATION_zh.md)、[API](API_SPECIFICATION_zh.md)、99 项 MoonBit 测试；不声明完整 UTS #39 合规 |
| 4. README、安装、用法与样例 | 通过 | [README](../README.md)、[中文指南](README_zh.md)；独立模块实测 `moon add Sidney-sunny/moonspoof` 及公开导入 |
| 5. CI 覆盖检查、构建、测试 | 通过 | [发布提交 CI](https://github.com/Sidney-sunny/MoonSpoof/actions/runs/41044994373)通过编译器核验、WASM/JS/native check/build/test，以及生成器、ABI/构建、Unicode、ICU 和注册表安装 |
| 6. 可运行示例 | 通过 | `moon run cmd/registration`、`moon run cmd/main`；[接入指南](../examples/registration/README_zh.md)。最终发布源码 ZIP 在无 .git 时通过注册接入及引擎构建 |
| 7. 核心路径测试 | 通过 | 99 项 MoonBit、19 项生成器、15 项打包、14 项 ABI/Worker、7 项参考工具测试，4,456,448 项全码点属性断言、官方 NFD/映射验证及 [ICU 覆盖](REFERENCE_COMPARISON_zh.md) |
| 8. 发布到 mooncakes.io | 0.2.0 已满足 | [公开包](https://mooncakes.io/modules/Sidney-sunny/moonspoof)列出未撤回的 0.2.0，发布于 2026-10-30；[干净消费验证](../tools/verify-registry-consumer.py)在 WASM/JS 检查精确库版本、键、属性、策略及声明 |
| 9. OSI 许可证及上游条款 | 0.2.0 分发通过 | [Apache-2.0](../LICENSE)获 [OSI 认可](https://opensource.org/license/apache-2-0)；[上游声明](THIRD_PARTY_NOTICES_zh.md)、许可证全文及生成署名已保留，下载的注册表/发行产物包含声明，站点另含 React/Vite 运行时声明 |

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
uv run --no-project python tools/verify-registry-consumer.py --version 0.2.0
pnpm --dir playground install --frozen-lockfile
pnpm --dir playground run check
pnpm --dir playground run verify:unicode
pnpm --dir playground run verify:icu
moon info
moon fmt
```

Linux/CI 可用 `python3` 执行标准库脚本。ICU 需要 PATH 中有 `java`、`javac`；本次使用进程内 JDK 21.0.10.0.10。native 由 Ubuntu CI 验证，本文不声称 Windows 本地 native 构建通过。生成后执行 `moon info`、`moon fmt`，应复现已提交表与接口。

消费验证使用新临时模块、固定注册表依赖，不覆盖为本地源码；可能复用包管理器下载缓存。安装注册表 0.1.0 不会获得本次源码、编译器固定或声明变更。

## 已验证分发

已发布包含编译器兼容源码、精确库版本及 Unicode/Manrope/React/Vite 声明的 0.2.0。注册表校验值为 `c24722e4a5ab5ab62998da011bdf7510479340458546a52561b1c84c70451543`。已从 GitHub 下载源码/引擎/站点 ZIP、RELEASE_MANIFEST.json 与 SHA256SUMS，通过 `tools/package-release.py --verify` 检查。提交、tag、推送及发布身份均核验为 Sidney，Mooncakes 保存账号为 `Sidney-sunny`；密钥与私有资料不进入归档或历史。

[路线图](ROADMAP_zh.md)记录已完成的 M1–M4 门槛，[发布说明](RELEASE_0.2.0_zh.md)解释兼容性和剩余标准边界。本文不认证外部采用或官方验收。
