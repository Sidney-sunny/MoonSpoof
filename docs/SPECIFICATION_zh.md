# Unicode 安全实现范围

[English](SPECIFICATION.md)

MoonSpoof 使用固定的 Unicode 16.0.0 数据实现部分 Unicode 安全机制，不声明完整 UTS #39 合规。骨架相同或存在风险信号，不能证明输入具有恶意。

## 数据与复现

参考 [UTS #39 修订版 30](https://www.unicode.org/reports/tr39/tr39-30.html)。`tools/data-generator/sources.json` 保存六个官方数据文件的 URL 与 SHA-256：confusables、Scripts、UnicodeData、CaseFolding、DerivedCoreProperties、NormalizationTest。运行 `python tools/data-generator/generate.py`，随后执行 `moon info`、`moon fmt` 与 `pnpm --dir playground run verify:unicode`。

| 机制 | 已实现 | 边界 |
| --- | --- | --- |
| NFD | 递归规范分解、Hangul 算法分解、稳定组合类排序 | 不提供 NFKC/NFKD |
| 混淆键 | NFD、移除默认忽略字符、映射、NFD，重复至稳定 | 应用键，未实现完整 bidiSkeleton |
| 忽略大小写键 | 完整默认 C/F 折叠，再生成骨架，重复至稳定 | 不使用 Turkic T 或地区大小写规则；是独立等价策略 |
| 字系分析 | Scripts.txt 查询，十一类具名字系及 Unknown | 无 Script_Extensions；很多字系归入 Unknown |
| 标识符策略 | 空值、长度、控制字符、默认忽略字符、混合字系检查 | 自定义策略，不提供 Identifier_Status、XID 或语法验证 |
| 诊断 | 码点、原始映射目标、字系、规则、风险 | 单字符原始目标不一定等于最终归一化键 |
| 双向文本 | 控制字符及覆盖符检测 | 无 UBA 重排和双向骨架；演示使用浏览器排版 |
| 批量扫描 | 与双字符串比较使用同一键进行哈希分组 | 重复的相同输入也计为冲突 |

## 应用扩展与兼容性

全角 ASCII U+FF01–U+FF5E 与 U+3000 转为 ASCII。重复归一化与映射至稳定，处理目标经分解后再次落入映射表的情况，包括 Hangul。这两项是应用扩展。持久化键应同时记录库版本与 Unicode 数据版本。

`are_confusable_ignore_case(a,b)` 现在仅比较折叠键，不再与大小写敏感结果做 OR。例如 `I` 与 `l` 的大小写敏感键相同，但折叠键不同。双字符串比较与批量分组使用相同的等价关系。

## 限制等级估计

`primary_script` 是第一个识别到的非 Common/Inherited 字系，不是出现最多的字系。Unknown 字符会使等级变为 Unrestricted，但不会加入具名字系列表。

| 等级 | 已识别字系集合 |
| --- | --- |
| SingleScript | 无 Unknown，零或一个已识别字系 |
| HighlyRestrictive | 多字系，属于 Latin/Han/Hiragana/Katakana 或 Latin/Han/Hangul 的子集 |
| ModeratelyRestrictive | 恰好 Latin+Arabic 或 Latin+Hebrew |
| MinimallyRestrictive | 其他已识别字系组合，包括 Latin+Cyrillic 与 Latin+Greek |
| Unrestricted | 存在 Unknown |

估计未覆盖标准要求的完整 Identifier_Status 与 Script_Extensions 前提。默认标识符策略拒绝所有已识别的混合字系，包括等级为 HighlyRestrictive 的 CJK 组合；调用方可选宽松策略。Unknown 字系与标点可能通过该策略，调用方须自行验证业务语法。

## 风险规则

| 规则 | 触发条件 |
| --- | --- |
| RULE_INVISIBLE_OR_FORMAT_CHARACTER | 默认忽略码点 |
| RULE_CONTROL_CHARACTER | C0 U+0000–001F 或 C1 U+007F–009F |
| RULE_BIDI_CONTROL_CHARACTER | 受支持的双向控制字符 |
| RULE_BIDI_OVERRIDE_CHARACTER | LRO 或 RLO |
| RULE_BIDI_FILE_EXTENSION_SPOOF | LRO/RLO 加任意点号；启发式，不解析扩展名 |
| RULE_MIXED_SCRIPT_IDENTIFIER | 多个已识别字系 |
| RULE_MIXED_SCRIPT_CONFUSABLE_TRIAD | Latin、Cyrillic、Greek 中任意两个 |
| RULE_CROSS_SCRIPT_CONFUSABLE_GLYPH | 原始映射目标使用不同的已识别字系；忽略 Common/Inherited/Unknown |

控制字符、默认忽略字符、双向控制符触发 Critical。跨字系映射或三字系规则伴随混合字系触发 High。单独跨字系映射或不在允许集合中的混合字系触发 Medium。其余骨架改变触发 Low，否则 Safe。HighlyRestrictive 的 CJK 组合不会仅因混合字系而升为 Medium。

尚未实现混合数字系统、Identifier_Status、完整 Script_Extensions、双向骨架重排。低层 `get_general_category` 是遗留的粗略分类器，不是完整 UCD General_Category 查询。

## 验证证据

归一化向量直接从已通过校验值检查的官方 `NormalizationTest.txt` 解析；派生 JSON 缓存无法减少实际检查的测试集。空输入、行格式错误和无效标量值会导致验证失败。

验证器检查 19,965 条官方 NFD 向量（99,825 个断言）、6,355 条混淆映射与参考流水线的对应、1,557 条 C/F 大小写映射以及 7,561 个源码点的键稳定性。参考流水线在官方 NFD 验证后复用该 NFD 实现。这些证据不等于完整 UTS #39 合规，也不证明所有字符串性质。单元测试另外覆盖 JSON 控制字符、补充平面长度、分组顺序、CJK 限制等级与工作线程故障。
