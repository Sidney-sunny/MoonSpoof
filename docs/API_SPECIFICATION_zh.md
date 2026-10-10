# MoonSpoof 公共接口规范 (API Specification)

本文档明确 MoonSpoof 导出的公共接口、数据类型定义、前置条件与行为保证。

---

## 1. 顶层公共 API

所有核心 API 均在 `Sidney-sunny/moonspoof` 根命名空间直接导出。

### 1.1 `skeleton`

计算给定 Unicode 字符串的 UTS #39 Confusable Skeleton（标准骨架字符串）。

```moonbit
pub fn skeleton(input : String) -> String
```

- **参数**：`input : String` — 原始待处理字符串。
- **返回值**：`String` — 规范化映射后的骨架字符串。
- **行为保证**：
  - 纯函数，不改变输入且无任何副作用。
  - 输入空字符串时安全返回 `""`。
  - 普通 ASCII 文本在无对应混淆规则时保持原样。

---

### 1.2 `are_confusable`

依据 UTS #39 骨架等价性判断两字符串是否存在视觉混淆。

```moonbit
pub fn are_confusable(a : String, b : String) -> Bool
```

- **参数**：
  - `a : String` — 待比对的第一个标识符。
  - `b : String` — 待比对的第二个标识符。
- **返回值**：`Bool` — 当且仅当 `skeleton(a) == skeleton(b)` 时返回 `true`。
- **说明**：明确区分字符串物理相等（`a == b`）与视觉混淆关系。

---

### 1.3 `analyze_scripts`

分析标识符中包含的 Unicode 字系，并依照 UTS #39 第 5 节规范评估其限制级别。

```moonbit
pub fn analyze_scripts(input : String) -> ScriptAnalysis
```

- **参数**：`input : String` — 待分析标识符。
- **返回值**：`ScriptAnalysis` 结构体：
  - `primary_script : Script` — 主导字系。
  - `scripts : Array[Script]` — 出现的非通用字系列表。
  - `is_mixed : Bool` — 是否包含两个及以上独立字系。
  - `level : RestrictionLevel` — 限制级别评级（`SingleScript`, `HighlyRestrictive`, `ModeratelyRestrictive`, `MinimallyRestrictive`, `Unrestricted`）。

---

### 1.4 `analyze_identifier`

对标识符执行字符级逐一深度诊断，并评估安全风险与规则触发情况。

```moonbit
pub fn analyze_identifier(input : String) -> DiagnosticReport
```

- **参数**：`input : String` — 待审计的标识符。
- **返回值**：`DiagnosticReport`：
  - `original : String` — 原始输入。
  - `skeleton : String` — 对应标准骨架。
  - `script_analysis : ScriptAnalysis` — 字系分析结构体。
  - `risk_level : SecurityRiskLevel` — 综合安全风险等级（`Safe`, `Low`, `Medium`, `High`, `Critical`）。
  - `char_diagnostics : Array[CharDiagnostic]` — 逐字符诊断数组。
  - `rules_triggered : Array[String]` — 命中的规则标识列表。

---

### 1.5 `find_confusable_groups`

对批量用户名或标识符进行 $O(N)$ 复杂度的冲突分桶检测。

```moonbit
pub fn find_confusable_groups(names : Array[String]) -> Array[ConfusableGroup]
```

- **参数**：`names : Array[String]` — 待扫描的名称集合。
- **返回值**：`Array[ConfusableGroup]` — 所有存在 2 个及以上互为混淆的冲突分组：
  - `skeleton : String` — 冲突对应的共享骨架键。
  - `members : Array[String]` — 包含在此冲突组内的所有原始名称。

---

## 2. 核心数据类型定义

### 2.1 `SecurityRiskLevel` (安全风险等级)

```moonbit
pub(all) enum SecurityRiskLevel {
  Safe
  Low
  Medium
  High
  Critical
}
```

### 2.2 `Script` (字系列表)

```moonbit
pub(all) enum Script {
  Common
  Inherited
  Latin
  Cyrillic
  Greek
  Arabic
  Hebrew
  Han
  Hiragana
  Katakana
  Hangul
  Unknown
}
```

### 2.3 `RestrictionLevel` (UTS #39 限制级别)

```moonbit
pub(all) enum RestrictionLevel {
  SingleScript
  HighlyRestrictive
  ModeratelyRestrictive
  MinimallyRestrictive
  Unrestricted
}
```

### 2.4 `CharDiagnostic` (字符诊断元数据)

```moonbit
pub(all) struct CharDiagnostic {
  char : Char
  codepoint : Int
  codepoint_hex : String
  script : Script
  is_invisible : Bool
  is_bidi : Bool
  is_confusable : Bool
  confusable_target : String
}
```
