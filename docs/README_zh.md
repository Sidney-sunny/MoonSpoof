<p align="center">
  <img src="assets/banner.jpg" alt="MoonSpoof: Unicode 视觉混淆识别基础库" width="960" />
</p>

<p align="center">
  <img alt="版本 0.1.0" src="https://img.shields.io/badge/版本-0.1.0-334155?style=flat-square" />
  <img alt="Unicode 16.0" src="https://img.shields.io/badge/Unicode-16.0.0-334155?style=flat-square" />
  <img alt="标准 UTS #39" src="https://img.shields.io/badge/标准-UTS_%2339-334155?style=flat-square" />
  <img alt="支持目标 WASM JS Native" src="https://img.shields.io/badge/支持目标-WASM_%7C_JS_%7C_Native-334155?style=flat-square" />
  <a href="../LICENSE"><img alt="Apache 2.0" src="https://img.shields.io/badge/协议-Apache_2.0-334155?style=flat-square" /></a>
  <img alt="MoonBit 2026 黑客松" src="https://img.shields.io/badge/MoonBit-2026_Hackathon-000000?style=flat-square" />
</p>

<p align="center">
  基于 Unicode UTS #39 规范的字符视觉混淆识别、标识符冒用检测与安全诊断基础库。
</p>

<p align="center">
  <a href="../README.md"><strong>English Version</strong></a> ·
  <a href="#快速开始">快速开始</a> ·
  <a href="API_SPECIFICATION_zh.md">接口规范</a> ·
  <a href="ARCHITECTURE_zh.md">架构设计</a> ·
  <a href="SPECIFICATION_zh.md">UTS #39 规范对照</a>
</p>

---

## 字符混淆，精准识别与结构化诊断

| 标准 Skeleton 转换 | 字系与限制级别分析 | 高性能批量冲突扫描 |
| :--- | :--- | :--- |
| 严格基于 UTS #39 Confusable Skeleton 算法 | 自动化 Script 与 Script_Extensions 归属识别 | 基于 Skeleton 哈希分桶的 O(N) 冲突检测 |
| 明确区分“视觉混淆”与普通字符串相等 | 智能识别混合字系，依据上下文合理定级 | 万级用户名批量碰撞扫描，免除 O(N^2) 耗时 |
| 覆盖西里尔、希腊、拉丁及东亚 CJK 常用字系 | 精准拦截零宽不可见字符与双向文本控制符 | 零运行时依赖，原生编译为 WASM、JS 与 Native |

在现代多语言软件生态中，攻击者常利用字形极度相似的非拉丁字符（如西里尔字母 `а` U+0430 与拉丁字母 `a` U+0061）仿冒关键用户、代码标识符或网络域名。MoonSpoof 提供工业级、标准驱动的检测原语与可解释字符诊断报告，既防范恶意冒用，又避免对正常多语言文本的误伤。

---

## 选择你的接入方式

**基础库集成** — 直接作为 MoonBit 模块引入，供用户名注册系统、包管理器与编译器 Linter 调用。

**CLI 命令行工具** — 快速对标识符、单词列表进行合规审计，输出终端可读诊断。

**WebAssembly Playground** — 编译为 WebAssembly 嵌入浏览器安全看板，实现纯前端零延迟离线检测。

```powershell
# 运行内置 CLI 演示程序
moon run cmd/main
```

---

## 快速开始

### 1. 声明依赖

在项目 `moon.mod` 中声明：

```moonbit
import {
  "Sidney-sunny/moonspoof" @lib,
}
```

### 2. 基础混淆检测与 Skeleton 生成

```moonbit
let authentic = "paypal"
let spoofed = "p\u0430ypal" // 西里尔小写字母 A (U+0430)

// 判断两字符串是否存在视觉混淆关联
let confusable : Bool = @moonspoof.are_confusable(authentic, spoofed)
// confusable == true

// 生成标准骨架字符串 (Skeleton)
let sk : String = @moonspoof.skeleton(spoofed)
// sk == "paypal"
```

### 3. 字符级结构化安全诊断

```moonbit
let report = @moonspoof.analyze_identifier("admin\u200B")

// 查看综合风险等级：Safe, Low, Medium, High, Critical
println(report.risk_level) // Critical

// 查看触发的安全规则列表
println(report.rules_triggered) // ["RULE_INVISIBLE_OR_FORMAT_CHARACTER"]
```

### 4. 批量用户名冲突扫描

```moonbit
let registered_users = ["admin", "adm\u0456n", "alice", "bob", "al\u0456ce"]
let collisions = @moonspoof.find_confusable_groups(registered_users)

for group in collisions {
  println("骨架: \{group.skeleton}, 冲突名称列表: \{group.members}")
}
```

---

## 安全理念与设计边界

1. **标准驱动，拒绝臆测**：所有混淆映射严格生成自 Unicode 16.0.0 与 UTS #39 官方规范表，绝不用简易正则表达式替代标准检测。
2. **多语言平等，不预设立场**：中文汉字、日文假名、韩文谚文等属于合法的单一/高限制性字系，严禁默认标记为恶意。
3. **明确非目标**：本项目是安全基础算法库，不开发钓鱼网站云端黑名单、信誉评分系统或网络爬虫。

---

## 文档与技术索引

| 文档名称 | 对应英文文档 | 说明 |
| :--- | :--- | :--- |
| [架构设计](ARCHITECTURE_zh.md) | [ARCHITECTURE.md](ARCHITECTURE.md) | 系统管线、内存优化与 WASM 集成标准 |
| [接口规范](API_SPECIFICATION_zh.md) | [API_SPECIFICATION.md](API_SPECIFICATION.md) | 公共 API 参数、返回值与类型定义 |
| [规范对照](SPECIFICATION_zh.md) | [SPECIFICATION.md](SPECIFICATION.md) | UTS #39 覆盖范围与规则标识定义 |
| [品牌视觉规范](BRANDING_zh.md) | [BRANDING.md](BRANDING.md) | 极简单色设计规范与品牌资产说明 |

---

<details>
<summary><strong>从源码构建与测试</strong></summary>

需要安装 MoonBit 编译器工具链 (`moon`)。

```powershell
# 语法与类型检查
moon check

# 运行单元测试
moon test

# 运行命令行程序
moon run cmd/main
```

</details>

---

## 开源协议

基于 [Apache License, Version 2.0](../LICENSE) 开源发布。
