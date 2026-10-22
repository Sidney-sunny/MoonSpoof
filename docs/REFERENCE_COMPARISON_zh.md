# ICU 参考对照与机制覆盖

[English](REFERENCE_COMPARISON.md)

2026-10-22 已使用 ICU4J 76.1.0.0、Unicode 16.0.0.0 验证，与 MoonSpoof 固定的 Unicode 16.0.0 数据一致。这是限定范围的对照证据，不代表完整 UTS #39 合规、性能对比或生产采用。

## 运行对照

需要固定版本 MoonBit 编译器、Node 22、JDK 21（PATH 中提供 `java`、`javac`）。仓库根目录执行：

```powershell
pnpm --dir playground run verify:icu
```

命令重新构建 JavaScript 引擎，将可选 ICU jar 下载到忽略的 `_build/icu-reference`，先校验 SHA-256 再缓存或执行，编译独立参考程序并比较已提交语料。每次运行都会检查已有缓存；缓存损坏时直接失败，不自动替换。下载超时为 60 秒。MoonBit 库和浏览器产物均不引入 Java 或 ICU 依赖。

[参考清单](../tools/icu-reference/manifest.json)固定 Maven 产物、ICU 与 Unicode 版本。SHA-256 为 `732cdf18121b1642899da1f5e37e52cc7f48e3ec07fa737105d4603976781b33`，已与[发布校验值](https://repo.maven.apache.org/maven2/com/ibm/icu/icu4j/76.1/icu4j-76.1.jar.sha256)核对。参见 [ICU 76 官方发布](https://unicode-org.github.io/icu/download/76.html)及[对应版本 SpoofChecker 源码](https://github.com/unicode-org/icu/blob/release-76-1/icu4j/main/core/src/main/java/com/ibm/icu/text/SpoofChecker.java)。

## 对照操作与结果

[42 组语料](../tools/icu-reference/corpus.json)覆盖规范化、混淆映射、折叠、忽略/控制字符、双向顺序、CJK、共享字系、非 BMP 与新增字系、原始状态、数字系统及重复 512 次的长输入。语料 SHA-256 为 `b4325b674bf29e693acec6d1ffacd02a54e2c7bc5192cbf787ec97602a7ea49a`。

| 对照项 | 证据 |
| --- | --- |
| NFD 与 `Normalizer2.getNFDInstance` | 42 项完全一致 |
| 应用键与 ICU 加已记录的全角/稳定化/折叠操作 | 84 项完全一致；适配参考与原始 ICU 行为分别呈现 |
| 数字代表及混用与 `SpoofChecker.MIXED_NUMBERS`、`CheckResult.numerics` | 84 项完全一致 |
| Script、Script_Extensions、原始 Identifier_Status、十进制零代表与 ICU 属性 | 500 项断言；每组内部按码点去重，不是全码点 ICU 验证 |
| 原始骨架、默认折叠后骨架、LTR 双向骨架与应用键 | 126 项比较：114 项一致，12 项差异逐一复核 |

原始操作分别为 `getSkeleton(text)`、`getSkeleton(UCharacter.foldCase(text, true))`、`getBidiSkeleton(LEFT_TO_RIGHT, text)`。折叠操作是明确选择的参考策略，不表示 ICU 普通骨架忽略大小写。`_build/icu-reference/report.json` 记录 Java 运行时版本、语料哈希及每项差异；运行时 ICU、Unicode 版本必须与清单及库来源清单一致。

## 全部已观察差异

| 语料 | 差异字段 | 解释 |
| --- | --- | --- |
| `fullwidth` | 三项 | 全角折叠属于应用扩展；原始 ICU 保留全角数字 U+FF11，折叠参考还保留 U+FF42 |
| `ideographic-space` | 三项 | 应用将 U+3000 折叠为 U+0020，原始 ICU 保留 U+3000 |
| `hangul-prototype` | 三项 | U+321D 单轮映射分解后的末尾为 U+11AB；应用键稳定化继续将其映射为 U+1102 |
| `mathematical-digits` | 仅折叠项 | 映射产生 `OO`，重复应用折叠得到稳定的 `oo` |
| `bidi-control` | 仅 LTR 双向项 | ICU 将 `abc`、RLO、`.txt` 重排后得到骨架 `abctxt.`；应用键仍为 `abc.txt` |
| `arabic-order` | 仅 LTR 双向项 | ICU 对阿拉伯文字/数字执行双向排序；应用键不重排 |

每个差异字段都在语料中固定双方精确输出与原因。新增、改变或已经消失的差异均使验证失败，原因不是整类豁免。默认忽略字符移除与 ICU 一致，不计为应用独有差异。[工具测试](../tools/icu-reference/reference.test.mjs)离线验证这些约束，以及清单、产物和缓存失败情形。

## 机制覆盖矩阵

| 机制 | 已实现与验证 | 剩余边界 |
| --- | --- | --- |
| NFD | 19,965 条官方向量、99,825 项断言；ICU 语料 | 不提供 NFKC/NFKD |
| 混淆键 | 官方映射、键稳定性、ICU 原始/适配语料 | 全角/闭包扩展；不做双向重排 |
| 完整默认折叠 | 全部 1,557 条 C/F 映射、稳定折叠键、ICU 语料 | 不提供地区/Turkic 策略 |
| 完整 Script / Script_Extensions | 官方全码点属性检查；ICU 语料 | 旧枚举和限制等级估计仍有范围限制 |
| 解析字系集合 | 多语言增广/交集回归 | ICU 对照验证属性，不调用 ICU 私有解析集合方法 |
| 原始 Identifier_Status | 官方全码点检查；ICU 语料 | 可选原始过滤；无规范等价闭包或完整 General Security Profile |
| 十进制混用 | 76 个完整 Nd 系统、全码点查询检查、ICU 数字语料 | 可选；其他数字类型由独立语法策略处理 |
| 双向控制字符 | 拒绝/诊断回归；明确记录 ICU 双向差异 | 未实现 bidiSkeleton |
| 双字符串/批量接入 | [对抗回归](../moonspoof_adversarial_test.mbt)、两种键策略、长组合序列、标量证据 | 仓库参考接入，不声称外部采用 |

官方全码点套件执行 4,456,448 项属性断言，独立于较小的 ICU 语料。另行运行 `pnpm --dir playground run verify:unicode`。[实现范围](SPECIFICATION_zh.md)记录旧估计和风险规则；[路线图](ROADMAP_zh.md)保留 M4 接入、测量、兼容性及发布门槛。独立 CI 作业执行固定 ICU 对照，原有三目标测试继续运行。
