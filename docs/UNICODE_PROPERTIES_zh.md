# 完整 Unicode 字系属性

[English](UNICODE_PROPERTIES.md)

新增 API 使用 Unicode 16.0.0 数据，补充旧 `Script` 枚举和 `analyze_scripts`，不改变骨架、持久化键、默认策略、风险规则或限制等级估计。

## 属性查询

```moonbit
@moonspoof.get_unicode_script(0x0905) // "Devanagari"
@moonspoof.get_script_extensions(0x30FC) // ["Hiragana", "Katakana"]
```

`get_unicode_script(Int) -> String` 返回 Script 属性的规范长名称。生成表覆盖所有显式分配范围，未列出的码点返回 `"Unknown"`，包括未分配、代理、私用码点及超出 0..0x10FFFF 的输入。完整表达 170 个显式分配字系值，不扩展旧枚举。

`get_script_extensions(Int) -> Array[String]` 返回按字典序排列的规范长名称，通过固定的 PropertyValueAliases 文件解析别名。依据 [UAX #24 修订版 37](https://www.unicode.org/reports/tr24/tr24-37.html)，缺省继承单个 Script 值。每次调用返回新数组。

## 解析字系集合

```moonbit
@moonspoof.resolve_script_set("ねガ") // Scripts(["Jpan"])
@moonspoof.resolve_script_set("中文가") // Scripts(["Kore"])
@moonspoof.is_mixed_script_resolved("aー") // true
```

`resolve_script_set(String) -> ScriptSet` 实现 [UTS #39 修订版 30 第 5.1 节](https://www.unicode.org/reports/tr39/tr39-30.html#Mixed_Script_Detection)的增广集合求交，返回两种变体：

| 变体 | 含义 |
| --- | --- |
| `All` | 没有字符约束字系；包括空串及没有具体扩展集合的 Common/Inherited 字符串 |
| `Scripts(names)` | 字符增广集合的交集，按字典序排列；空数组表示混合字系 |

增广时保留规范长名称，增加书写系统标识 `Hanb`、`Jpan`、`Kore`。Han 增加全部三者，Hiragana/Katakana 增加 Jpan，Hangul 增加 Kore，Bopomofo 增加 Hanb。包含 Common 或 Inherited 的集合不施加约束。Unknown 是明确的属性值，不作为 All 处理。

`is_mixed_script_resolved(String) -> Bool` 只在结果为 `Scripts([])` 时返回 true。例如，`ねガ` 解析为 Jpan；`aー` 的交集为空，因为长音符的扩展集合限定为 Hiragana/Katakana。

## 兼容性与边界

旧 API 保持不变，仍提供十一类命名字系及 Unknown 和有限的限制等级估计。它与解析集合检查可能不同：旧 Script 检查不认为 `aー` 混用，却认为 `ねガ` 混用；新检查将后者解析为同一个日文书写系统。应用应明确选择所需策略对应的 API。

解析集合本身不验证标识符语法，不限制 Identifier_Status，不检查混合数字系统，不给出限制等级，也不保证名称安全。未分配字符可能得到单元素 Unknown 集合；空串解析为 All，但仍无法通过普通标识符校验。属性 API 不进行输入规范化或双向重排。

## 可选 Identifier_Status 过滤

`get_identifier_status(Int) -> IdentifierStatus` 按官方属性返回 `Allowed` 或 `Restricted`，缺省及无效码点均为 Restricted。`validate_identifier_status(String) -> Result[Unit, IdentifierStatusError]` 拒绝空输入（`Empty`）或首个 Restricted 字符（`RestrictedCharacter(issue)`）。issue 包含 `codepoint_index`（从零开始的 Unicode 标量序号）、`codepoint`、`codepoint_hex`。

这是显式启用的原始码点过滤器，与 `validate_identifier` 及其不变的策略分开。它不检查 XID 语法、首字符、字系限制、碰撞策略或 Identifier_Type 原因。属性允许的标点及纯数字串可能通过，应用仍需组合自己的语法和碰撞检查。

过滤器未实现通用安全配置要求的规范等价闭包。例如 U+01EE 通过原始属性检查，其规范分解 U+01B7 U+030C 却无法通过。该行为已明确记录并测试，不得宣传为完整 UTS #39 General Security Profile 验证。[状态回归测试](../moonspoof_status_test.mbt)覆盖这一差异。

[注册示例](../examples/registration/README_zh.md)展示通过语法回调及新的应用策略版本选择启用过滤；已有账号若被新过滤器拒绝，重建时需要复核，不会被静默删除。

## 验证

生成数据后运行 `pnpm --dir playground run verify:unicode`。验证器独立读取已校验的官方文件，展开完整 0..0x10FFFF 空间，对照 Script、Script_Extensions、原始 Identifier_Status 属性及[十进制零字符代表](NUMBER_SYSTEMS_zh.md)：共 1,114,112 个码点、4,456,448 项属性断言。覆盖缺省值和代理码点，补充已有归一化/映射检查。

[公开 API 回归测试](../moonspoof_scripts_test.mbt)覆盖日文、韩文、Han/Bopomofo、Devanagari、Thai、共享/继承字符、Unknown 及旧行为兼容性。浏览器 ABI 另提供用于参考验证的 `spoof_unicode_script(cp)`、`spoof_script_extensions(cp)`（JSON 数组）和 `spoof_identifier_status_allowed(cp)`（布尔值）。
