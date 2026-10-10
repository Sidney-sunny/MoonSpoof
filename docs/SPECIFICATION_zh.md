# UTS #39 Unicode 安全规范与合规矩阵

本文档系统说明 MoonSpoof 对 Unicode Technical Standard #39（UTS #39）规范的覆盖范围，以及与 Unicode 字符数据库（UCD）16.0.0 的对照关系。

---

## 1. 规范基准与固定数据版本

| 规范与数据源 | 官方标准名称 | 固定版本 | 官方上游来源 |
| :--- | :--- | :--- | :--- |
| **UTS #39** | Unicode Security Mechanisms | Revision 30 / 16.0.0 | [unicode.org/reports/tr39/](https://www.unicode.org/reports/tr39/) |
| **Confusables 数据**| 视觉混淆字符映射表 | 16.0.0 | [confusables.txt](https://www.unicode.org/Public/security/16.0.0/confusables.txt) |
| **UCD Scripts** | Unicode 字符字系属性表 | 16.0.0 | [Scripts.txt](https://www.unicode.org/Public/16.0.0/ucd/Scripts.txt) |
| **UCD ScriptExtensions** | 扩展字系属性表 (scx) | 16.0.0 | [ScriptExtensions.txt](https://www.unicode.org/Public/16.0.0/ucd/ScriptExtensions.txt) |

---

## 2. 标准条款实现覆盖范围

### 2.1 UTS #39 第 4 节：混淆骨架识别 (Confusable Detection)

- **已实现**：单码点至目标骨架的映射转换（`skeleton(S)`）。
- **已实现**：跨字系高危视觉冒用识别（如利用西里尔字母 `а`、希腊字母 `ο` 仿冒拉丁字母 `a`、`o`）。
- **已实现**：全角 ASCII（U+FF01–U+FF5E）规范化还原至半角标准 ASCII。
- **不变式要求**：混淆判断与底层编码相等、Unicode 规范化相等严格分离。

### 2.2 UTS #39 第 5 节：混合字系识别与限制级别 (Restriction Levels)

- **单一字系 (Single Script)**：仅包含单一有效字系（除 `Common` 与 `Inherited` 外）。
- **高度受限 (Highly Restrictive)**：
  - `Latin` + `Han` / `Hiragana` / `Katakana`（标准日文标识符场景）
  - `Latin` + `Han`（标准中文标识符场景）
  - `Latin` + `Hangul`（标准韩文标识符场景）
- **中度受限 (Moderately Restrictive)**：混合 `Latin` 与 `Cyrillic` 或 `Greek`。
- **低度受限 / 不受限 (Unrestricted)**：无序多字系任意混合。

---

## 3. 安全检测规则标识

MoonSpoof 输出标准、机器可读的规则标识，确保诊断报告的可追踪性：

| 规则标识 | 触发条件 | 风险定级 |
| :--- | :--- | :--- |
| `RULE_INVISIBLE_OR_FORMAT_CHARACTER` | 包含零宽空格 (U+200B)、连字控制符 (U+200C/D) 或软连字符等不可见格式字符 | **Critical** (极高) |
| `RULE_BIDI_CONTROL_CHARACTER` | 包含 LRM、RLM 或双向文本覆盖控制符 (U+202A–202E, U+2066–2069) | **Critical** (极高) |
| `RULE_CROSS_SCRIPT_CONFUSABLE_GLYPH` | 包含假借非拉丁字符冒用拉丁字符外观的同形异义字 | **High** (高) |
| `RULE_MIXED_SCRIPT_IDENTIFIER` | 包含两个或以上无合理语言关联的跨字系混合字符 | **Medium** (中) |
