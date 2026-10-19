# MoonSpoof 公共接口规范 (API Specification)

[English](API_SPECIFICATION.md)

可选 `get_decimal_zero`、`get_decimal_systems`、`has_mixed_numbers` 和 `validate_number_systems` API、类型化标量证据及迁移要求见[十进制数字系统契约](NUMBER_SYSTEMS_zh.md)。

新增完整字系 API `get_unicode_script`、`get_script_extensions`、`resolve_script_set`、`is_mixed_script_resolved` 及 `ScriptSet::All` 与空交集的区别，见 [Unicode 属性契约](UNICODE_PROPERTIES_zh.md)。旧 `ScriptAnalysis` 与限制等级估计保持原行为。

同一文档定义 `get_identifier_status` 和显式启用的 `validate_identifier_status`，包含首个失败字符的类型化证据及原始码点/规范闭包边界。`IdentifierProfile` 字段与默认值不变。

本文档明确 MoonSpoof 导出的公共接口、数据类型定义、前置条件与行为保证。

---

## 1. 顶层公共 API

所有核心 API 均在 `Sidney-sunny/moonspoof` 根命名空间直接导出。

### 1.1 `skeleton`

使用 Unicode 16.0 NFD、默认忽略字符与混淆映射计算稳定应用骨架。全角折叠与稳定化属于应用扩展，见[实现范围](SPECIFICATION_zh.md)。

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
- **说明**：相同文本（`a == b`）也会返回 true，调用方应区别相同输入与不同文本的冲突。

---

### 1.3 `are_confusable_ignore_case` 与 `skeleton_case_folded`

使用完整默认 C/F Unicode 大小写折叠计算稳定应用键。

```moonbit
pub fn are_confusable_ignore_case(a : String, b : String) -> Bool
pub fn skeleton_case_folded(input : String) -> String
```

- **参数**：
  - `a : String`, `b : String` — 待比对候选标识符。
- **返回值**：`Bool` — 仅当双方折叠键相等时返回 `true`，不与敏感匹配结果做 OR。
- **行为保证**：完整折叠与骨架变换重复至稳定键。两种模式是独立等价策略：敏感模式下 `I` / `l` 相同，折叠模式下不同。

---

### 1.4 `analyze_scripts`

分析标识符中包含的 Unicode 字系，估计限制级别，未覆盖完整 Script_Extensions 与 Identifier_Status 前提。

```moonbit
pub fn analyze_scripts(input : String) -> ScriptAnalysis
```

- **参数**：`input : String` — 待分析标识符。
- **返回值**：`ScriptAnalysis` 结构体：
  - `primary_script : Script` — 首个已识别的非 Common/Inherited 字系；无则为 Common。
  - `scripts : Array[Script]` — 具名字系列表，不包括 Common、Inherited、Unknown。
  - `is_mixed : Bool` — 是否包含两个及以上独立字系。
  - `level : RestrictionLevel` — 限制级别评级（`SingleScript`, `HighlyRestrictive`, `ModeratelyRestrictive`, `MinimallyRestrictive`, `Unrestricted`）。

---

### 1.5 `analyze_identifier`

对标识符执行字符级逐一深度诊断，并评估安全风险与规则触发情况。

```moonbit
pub fn analyze_identifier(input : String) -> DiagnosticReport
```

- **参数**：`input : String` — 待审计的标识符。
- **返回值**：`DiagnosticReport`：
  - `original : String` — 原始输入。
  - `skeleton : String` — 稳定应用骨架。
  - `script_analysis : ScriptAnalysis` — 字系分析结构体。
  - `risk_level : SecurityRiskLevel` — 综合安全风险等级（`Safe`, `Low`, `Medium`, `High`, `Critical`）。
  - `char_diagnostics : Array[CharDiagnostic]` — 逐字符诊断数组。
  - `rules_triggered : Array[String]` — 命中的规则标识列表。

---

### 1.6 `validate_identifier` 与 `is_allowed_identifier`

执行自定义标识符检查，不是完整 Identifier_Status 或语法验证。默认策略拒绝混合字系和忽略字符，最多128码点；宽松策略允许混合字系、拒绝忽略字符，最多256码点。两者均拒绝空值及 C0/C1 控制字符。Unknown 字系与标点不会仅因分类而被拒绝。

```moonbit
pub fn validate_identifier(
  input : String,
  profile? : IdentifierProfile = IdentifierProfile::default()
) -> Result[Unit, String]

pub fn is_allowed_identifier(
  input : String,
  profile? : IdentifierProfile = IdentifierProfile::default()
) -> Bool
```

- **参数**：
  - `input : String` — 候选标识符。
  - `profile? : IdentifierProfile` — 可配置的合法性校验规则。
- **返回值**：`Result[Unit, String]` 或布尔值，指示是否合规。

---

### 1.7 `find_confusable_groups`

对批量用户名或标识符进行 按键哈希分组 复杂度的冲突分桶检测。

```moonbit
pub fn find_confusable_groups(names : Array[String]) -> Array[ConfusableGroup]
```

- **参数**：`names : Array[String]` — 待扫描的名称集合。
- **返回值**：`Array[ConfusableGroup]` — 所有存在 2 个及以上互为混淆的冲突分组：
  - `skeleton : String` — 冲突对应的共享骨架键。
  - `members : Array[String]` — 包含在此冲突组内的所有原始名称。

---

### 1.8 `find_confusable_groups_ignore_case`

依据 应用折叠键策略规范，利用大小写折叠骨架（`skeleton_case_folded`）对批量候选名称执行大小写不敏感的 按键哈希分组 冲突聚类分桶。

```moonbit
pub fn find_confusable_groups_ignore_case(names : Array[String]) -> Array[ConfusableGroup]
```

- **参数**：`names : Array[String]` — 待扫描的名称集合。
- **返回值**：`Array[ConfusableGroup]` — 所有在忽略大小写与同形替换后发生碰撞的分组（如 `PAYPAL`、`pаypal`、`Paypal` 汇聚至同一分组）。

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
