# MoonSpoof 路线图

[English](../ROADMAP.md)

规划更新于 2026-10-30。根据项目负责人反馈，项目已通过初审。本文不代表已经通过终审或投入生产使用。[验收检查](ACCEPTANCE_zh.md)记录已完成的 0.10.18 及 0.2.0 分发验证。

## 目标

将 MoonSpoof 做成可供 MoonBit 项目接入的账号与包名混淆检测库。先完成一个完整的账号注册接入，再完善决定检测结果的 Unicode 机制。浏览器演示用于查看证据；库的正确性与可接入性决定开发进度。

## 当前基线

- 已发布 [v0.2.0](https://github.com/Sidney-sunny/MoonSpoof/releases/tag/v0.2.0)及 Mooncakes 包，提供经过验证的源码/引擎/站点产物与完整声明。
- 已实现 Unicode 16.0.0 NFD、完整默认大小写折叠、应用骨架键、字符诊断、自定义策略和批量碰撞分组。
- 已有验证覆盖 19,965 条官方 NFD 向量、99,825 项断言，以及混淆映射、大小写折叠、键稳定性和完整码点空间的 4,456,448 项字系/状态/十进制属性断言。参见[实现范围与证据](SPECIFICATION_zh.md)。
- 已固定九份 Unicode 来源及其校验值，支持校验后原子下载、直接读取官方规范化测试源，并固定 MoonBit 编译器版本。
- 尚存缺口：旧诊断保持十一类命名字系，新增独立的完整字系、解析集合及可选原始码点 Identifier_Status API；可选十进制混用检查也已实现；规范等价闭包与双向骨架重排仍待实现；尚未记录真实应用接入。

## 里程碑顺序

M1–M4 已随 0.2.0 在下文声明范围内完成，不声称已有外部应用采用。保留的初始估算属于规划历史，不是日历承诺；没有提供比赛截止时间。

| 顺序 | 交付内容 | 完成证据 | 工作量估算 |
| --- | --- | --- | --- |
| M1 — 已完成 | 可运行的账号注册接入示例 | [指南](../examples/registration/README_zh.md)、可执行程序与验收测试 | 2026-10-18 交付 |
| M2 — 在声明范围内完成 | 字系集合与明确的标识符状态过滤 | [API 契约](UNICODE_PROPERTIES_zh.md)、[状态回归](../moonspoof_status_test.mbt)、[迁移测试](../examples/registration/status_test.mbt) | 2026-10-19 交付 |
| M3 — 在声明范围内完成 | 混合数字检查与参考实现对照 | [固定 ICU 对照与覆盖矩阵](REFERENCE_COMPARISON_zh.md)、对抗回归 | 2026-10-22 交付 |
| M4 — 已完成 | 接入复核与 v0.2.0 发布 | [发布](https://github.com/Sidney-sunny/MoonSpoof/releases/tag/v0.2.0)、[验收证据](ACCEPTANCE_zh.md)、注册表及产物验证 | 2026-10-30 交付 |

## M1：完成一个接入闭环

已在[注册示例](../examples/registration/README_zh.md)中实现，通过公开 API 接入。在仓库根目录执行 `moon run cmd/registration`。真实应用采用前继续明确称为参考接入，不将仓库示例描述为外部使用。

验收条件：

- [x] 一条命令加载已有名称并检查候选名称，无须演示站：[可执行程序](../cmd/registration/main.mbt)。已从干净源码导出验证，CI 在三个编译目标运行。
- [x] 允许、重复、碰撞和策略不通过均返回明确决策及证据：[参考存储](../examples/registration/registry.mbt)。
- [x] 公开 API 用例覆盖 `paypal` / `p\u0430ypal`、多语言名称、默认可忽略字符、`I` / `l` 策略差异及独立的语法/Unicode 策略选择：[注册测试](../examples/registration/registry_test.mbt)。
- [x] 存储键包含版本与策略元数据，恢复校验键，重建重新检查原始名称且不返回部分索引：[迁移实现](../examples/registration/snapshot.mbt)及[测试](../examples/registration/snapshot_test.mbt)。指南记录生产原子性要求。
- [x] [英文](../examples/registration/README.md)与[中文](../examples/registration/README_zh.md)说明包含导入、调用位置、预期决策与限制；20 项验收测试验证公开 API 接入，包括可选状态/数字过滤与迁移。

## M2：完善字系与标识符决策

优先补齐字系分析限制，再考虑增加启发式风险分数。引入更精确的 Unicode 检查时，继续明确记录现有应用行为。

已完成范围：完整属性、解析字系集合，以及可选的原始码点状态过滤。过滤器不是完整的 UTS #39 General Security Profile，规范等价闭包仍延后实现。旧限制等级估计保留已记录的缺口与行为。

验收条件：

- [x] 已在[审核清单](../tools/data-generator/sources.json)中固定 ScriptExtensions、PropertyValueAliases、IdentifierStatus，包含严格解析、离线测试与可复现生成。
- [x] 已提供完整属性名称和明确的 All/交集类型；[API 与兼容性契约](UNICODE_PROPERTIES_zh.md)保留旧枚举、估计值及默认策略，[回归测试](../moonspoof_scripts_test.mbt)覆盖集合解析。
- [x] 已新增可选 Identifier_Status 过滤，提供首个失败字符的类型化证据：[实现](../src/security/identifier_status.mbt)与[测试](../moonspoof_status_test.mbt)。保持独立于应用语法和现有默认策略。
- [x] 已补充共享/继承字符、CJK 组合及原先 Unknown 字系的[回归](../moonspoof_scripts_test.mbt)，以及[受限名称回归](../moonspoof_status_test.mbt)；[范围复核](SPECIFICATION_zh.md)记录旧限制等级估计保持不变及尚未完整实现的原因。
- [x] 已同步更新 [API 契约](UNICODE_PROPERTIES_zh.md)、范围及双语接入说明。已有键保持不变；[迁移测试](../examples/registration/status_test.mbt)要求启用过滤时明确变更应用策略版本，并复核新增拒绝。

## M3：验证数字混用与参考行为

参考对照使用相同的固定 Unicode 版本。由 MoonSpoof 应用扩展引起的差异必须单独列出，不能变成无法解释的通过或失败。

已完成 42 组 ICU4J 76.1 / Unicode 16 语料、逐字段精确差异基线和下列覆盖矩阵。这是限定范围的对照证据；规范等价闭包、双向骨架实现、完整合规及外部采用不属于该里程碑。

验收条件：

- [x] 已基于固定 UnicodeData 来源实现[十进制混用 API](NUMBER_SYSTEMS_zh.md)，[公开回归](../moonspoof_numbers_test.mbt)覆盖单一/混用系统和范围外数字类型；包含完整码点空间属性验证及[注册迁移测试](../examples/registration/numbers_test.mbt)。
- [x] 已新增校验值固定的 ICU4J 76.1 参考程序，检查运行时 Unicode 版本，包含[语料](../tools/icu-reference/corpus.json)、[命令与 API 范围](REFERENCE_COMPARISON_zh.md)及独立 CI 作业；Java/ICU 仅作为库运行时以外的可选验证依赖。
- [x] 已在语料中为全部 12 处字段差异固定精确输出与原因；[复核](REFERENCE_COMPARISON_zh.md)区分全角折叠、稳定键、折叠策略及延后的双向行为。默认忽略字符移除与 ICU 一致。[工具测试](../tools/icu-reference/reference.test.mjs)拒绝新增、改变或失效的差异。
- [x] 已新增[公开对抗回归](../moonspoof_adversarial_test.mbt)，覆盖长组合输入、非 BMP/控制字符证据、稳定键及两种策略的双字符串/批量等价关系；ICU 语料另行覆盖多语言案例。
- [x] 已发布双语[覆盖矩阵](REFERENCE_COMPARISON_zh.md)，区分实现、官方来源测试、抽样 ICU 对照及延后工作，不作完整合规声明。

## M4：复核接入并发布

0.2.0 发布已完成 M1–M3 及以下门槛；后续版本需单独审核范围与兼容性。

验收条件：

- [x] 已从 `3051c64` 干净跟踪源码导出，在 0.10.18 下运行 M1 接入及 97 项测试；[验收检查](ACCEPTANCE_zh.md)记录结果及注册表消费复现。采用状态仍为仅参考接入，尚无外部应用调用位置证据。
- [x] [发布提交 CI](https://github.com/Sidney-sunny/MoonSpoof/actions/runs/41044994373)通过 WASM/JS/native 检查/构建/测试，以及生成器、官方 Unicode、ABI/Worker、生产构建和 ICU 门槛。Info/fmt 与再生成准确复现表，公开接口经审核新增库版本身份。
- [x] 已发布 [0.2.0 键/批量测量](BENCHMARKS_zh.md)，包含固定多语言/唯一名称语料、哈希、全部 40 轮计时、编译器/运行时及硬件，覆盖两种键策略，不作竞品性能声明。
- [x] 已复核[兼容性与重建](RELEASE_0.2.0_zh.md)、双语安装、日志及范围；Mooncakes 0.2.0 公开消费通过 WASM/JS 和许可证验证，下载的 GitHub 附件另行通过清单/校验值验证。
- [x] 已从 `a30e36f969c221efc443bc9f1788f021dd7f6891` 发布 [v0.2.0](https://github.com/Sidney-sunny/MoonSpoof/releases/tag/v0.2.0)，核验 Sidney 提交/标签/推送/发布身份，附说明、三份归档、清单及 SHA256SUMS。

## 0.2.0 之后

M1–M4 在声明范围内完成。后续工作应从真实接入用途及其回归语料开始；规范等价闭包与双向骨架仍延后，本次发布不代表外部采用或完整标准合规。

## 范围控制

- 核心保持为可复用的 MoonBit 库；证明接入不需要新增账号服务器、数据库框架或 UI 平台。
- 此阶段继续固定 Unicode 16.0.0；后续 Unicode 升级单独安排数据与兼容性审核。
- 延后标识符状态的规范等价闭包、完整双向骨架重排、NFKC/NFKD、IDNA/域名校验、区域相关大小写及完整合规声明；只有明确用途和验收语料后才重新评估。
- 优先修复正确性和接入阻碍；单纯 CI 加固与视觉打磨不构成产品里程碑完成。
- 只有链接到可执行证据后才勾选里程碑；外部采用只在实际发生后记录。
