# 十进制数字系统检查

[English](NUMBER_SYSTEMS.md)

这些可选 API 使用已固定校验值的 Unicode 16.0.0 UnicodeData.txt，属于已有九份审核来源。十进制值读取自字段 6，不使用宿主运行时的 Unicode 数据库。生成器写出任何产物前验证每个系统包含十个完整数字：共 760 个数字、76 个系统。

## 公开契约

| API | 返回结果 |
| --- | --- |
| `get_decimal_zero(Int) -> Int?` | Nd 数字所属系统的零字符码点；其他字符或无效码点返回 None |
| `get_decimal_systems(String) -> Array[Int]` | 按码点升序排列的去重零字符代表；每次调用返回新数组 |
| `has_mixed_numbers(String) -> Bool` | 存在多个十进制数字系统时为 true |
| `validate_number_systems(String) -> Result[Unit, MixedNumberIssue]` | 首个与输入中第一个十进制数字所属系统不同的数字 |

`MixedNumberIssue` 公开字段为 `codepoint_index`（从零开始的 Unicode 标量位置）、`codepoint`、`codepoint_hex`、`first_decimal_zero` 和 `decimal_zero`。非 BMP 字符按一个标量计数。空串或不含十进制数字的字符串没有数字系统，通过此项检查。

```moonbit
@moonspoof.get_decimal_zero(0x0665) // Some(0x0660)
@moonspoof.get_decimal_systems("user1١") // [0x0030, 0x0660]
@moonspoof.has_mixed_numbers("١۲") // true
```

## 算法与边界

检查使用 [UTS #39 修订版 30 第 5.3 节](https://www.unicode.org/reports/tr39/tr39-30.html#Mixed_Number_Detection)的十进制系统比较：用数字码点减去十进制值，得到所属系统的零字符，再比较不同代表。属性字段由 [UAX #44 修订版 34](https://www.unicode.org/reports/tr44/tr44-34.html#UnicodeData.txt)定义。

检查直接使用原始输入。ASCII、全角和数学字体数字属于不同系统，即使应用骨架将它们折叠为相同字符也不会合并。相邻的数学数字系列保留各自的零字符。阿拉伯数字与扩展阿拉伯数字虽然字系均为 Arabic，仍属于不同系统。

只有 General_Category=Nd 参与。上标、分数、罗马数字和具有数值的汉字不贡献数字系统。标准的标识符流程假定其他数字已被单独排除；本 API 只报告十进制混用，不拒绝这些字符。通过检查不代表语法有效或名称安全；应用语法、可选 Identifier_Status 过滤和碰撞检查仍分别执行。

默认策略、诊断风险分数、限制等级估计和存储骨架键保持不变。新增机制不代表完整 UTS #39 合规。

## 注册接入与迁移

运行 `moon run cmd/registration`。`number_checked_syntax` 回调组合数字检查、状态过滤与示例语法。`account12` 通过；`user1١` 在 U+0661、标量位置 5 被拒绝。可执行示例使用明确的应用策略版本。

为已有账号启用检查时，修改 `application_policy_version` 并从原始名称重建。[接入回归](../examples/registration/numbers_test.mbt)验证拒绝证据、旧快照恢复不兼容、重建复核及原索引保留。不要沿用旧元数据静默切换策略。这仍是参考接入，不是外部采用证据。

## 验证

运行 `moon test` 和 `moon test --target js` 验证[公开 API 回归](../moonspoof_numbers_test.mbt)，覆盖单一/混用系统、相同字系的不同系统、非 BMP 字符、Unicode 16 新增数字、检查范围外数字类型、标量位置、排序去重和默认行为兼容。

`pnpm --dir playground run verify:unicode` 独立读取已校验的 UnicodeData 来源，通过 `spoof_decimal_zero` 对全部 1,114,112 个码点验证 `get_decimal_zero`，包含缺省值和代理码点；ABI 以 -1 表示 None。连同 Script、Script_Extensions、Identifier_Status，属性套件运行 4,456,448 项断言。这是直接来源验证，[固定 ICU 对照](REFERENCE_COMPARISON_zh.md)另行验证已提交语料中的数字代表及混用。
