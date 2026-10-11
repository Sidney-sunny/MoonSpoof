<p align="center"><img src="assets/banner.png" alt="MoonSpoof" width="960" /></p>

<p align="center"><img alt="Unicode 16.0" src="https://img.shields.io/badge/Unicode-16.0.0-334155?style=flat-square" /> <img alt="Apache 2.0" src="https://img.shields.io/badge/License-Apache_2.0-334155?style=flat-square" /></p>

<p align="center">为 MoonBit 提供 Unicode 混淆键、字符证据与批量冲突检测。</p>

<p align="center"><a href="../README.md">English</a> · <a href="API_SPECIFICATION_zh.md">API 规范</a> · <a href="ARCHITECTURE_zh.md">架构</a> · <a href="SPECIFICATION_zh.md">实现范围</a></p>

## 引擎能力

| 混淆键 | 字符证据 | 批量分组 |
| --- | --- | --- |
| Unicode 16.0 NFD 与完整默认大小写折叠 | 码点、字系、原始映射目标、风险规则 | 与双字符串比较使用同一键的哈希桶 |
| 默认忽略字符与应用全角折叠 | 双向/控制字符检测与自定义标识符策略 | 保持首次出现顺序，保留重复输入 |
| 纯 MoonBit，支持 JS、WASM、native | 有限字系分类，明确标准缺口 | 无须逐对比较每个名称 |

本项目实现部分 UTS #39 机制，不声明完整合规。风险信号不证明恶意。[实现范围](SPECIFICATION_zh.md)记录具体边界。

## 启动双语演示

[打开在线演示](https://sidney-sunny.github.io/MoonSpoof/)。GitHub Actions 在引擎与前端检查通过后，将 `main` 分支构建并发布到 Pages。

```powershell
pnpm --dir playground install --frozen-lockfile
pnpm --dir playground dev
```

打开 Vite 输出的地址。默认中文，EN / 中文切换完整界面。浏览器使用工作线程中的新编译 MoonBit JavaScript，输入保留在本机。演示包含双字符串比较、字符证据、批量冲突与双向文本。竞品矩阵引用 ICU 与 confusable_homoglyphs 官方 API，不虚构性能排名。

```powershell
moon run cmd/main
```

## 库接入

执行 `moon add Sidney-sunny/moonspoof`，在包的 `moon.pkg` 中导入：

```moonbit
import {
  "Sidney-sunny/moonspoof" @moonspoof,
}
```

```moonbit
let authentic = "paypal"
let candidate = "p\u0430ypal"
@moonspoof.are_confusable(authentic, candidate) // true
@moonspoof.skeleton(candidate) // "paypal"
@moonspoof.analyze_identifier(candidate)
@moonspoof.find_confusable_groups([authentic, candidate, "stripe"])
@moonspoof.are_confusable_ignore_case("PAYPAL", "P\u0430yPal") // true
@moonspoof.get_restriction_level(candidate) // MinimallyRestrictive
@moonspoof.validate_identifier(candidate) // Err("Identifier contains disallowed mixed scripts")
```

## 安全边界与兼容性

引擎公开十一类字系及 Unknown，尚未实现完整 Script_Extensions、Identifier_Status、混合数字系统与双向骨架重排。标识符策略是可配置应用检查，不是完整 Unicode 标识符语法验证。全角折叠与重复归一化至稳定键属于应用扩展。

敏感键与折叠键是独立策略：`I` / `l` 在敏感模式下可能匹配，而在折叠模式下不同。持久化键应记录库与数据版本，升级后重新计算。[API 规范](API_SPECIFICATION_zh.md)说明修正后的行为。

## 开发者与代理导航

| 主题 | 文档 |
| --- | --- |
| 架构 | [ARCHITECTURE_zh.md](ARCHITECTURE_zh.md) |
| API | [API_SPECIFICATION_zh.md](API_SPECIFICATION_zh.md) |
| 标准范围 | [SPECIFICATION_zh.md](SPECIFICATION_zh.md) |
| 性能 | [BENCHMARKS_zh.md](BENCHMARKS_zh.md) |
| 品牌 | [BRANDING_zh.md](BRANDING_zh.md) |

<details><summary><strong>从源码构建与验证</strong></summary>

```powershell
moon check
moon test
moon test --target js
moon test --target native
pnpm --dir playground run check
python tools/data-generator/generate.py
moon info
moon fmt
pnpm --dir playground run verify:unicode
```

Unicode 表来自六个记录哈希的官方数据文件。Node 检查会先重建引擎。纯库没有第三方运行时依赖。

</details>

## 许可

[Apache-2.0](../LICENSE)。
