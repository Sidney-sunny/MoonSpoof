# 账号注册参考接入

[English](README.md)

应用示例导入公开的 `Sidney-sunny/moonspoof` API，提供单进程内存参考存储。它不是账号服务，也不代表已经有外部应用采用。

## 运行完整接入演示

在仓库根目录使用 [`.moon-version`](../../.moon-version) 指定的编译器执行：

```powershell
moon run cmd/registration
moon test -p Sidney-sunny/moonspoof/examples/registration
```

第一条命令加载 `paypal`、`admin`、`用户`，检查注册候选名称，恢复快照，更换策略版本后重建索引，并阻止会使 `I` 和 `l` 碰撞的迁移。无须前端依赖或账号服务器。CI 在 WASM、JavaScript、native 三个目标运行它。

| 候选名称 | 预期决策 | 证据 |
| --- | --- | --- |
| `alice中文` | 允许 | 所选应用策略允许的混合字系名称 |
| `paypal` | 重复 | 完全相同的已有名称 |
| `p\u0430ypal` | 碰撞 | 已有 `paypal`，西里尔 U+0430 字符诊断 |
| `admin\u200B` | 拒绝 | 不可见格式字符策略与触发规则 |
| `user name` | 拒绝 | 应用语法回调 |

## 注册调用位置

创建 `Registry` 时指定敏感或折叠键策略、应用自己的语法校验函数，以及应用策略版本。在注册决策位置调用 `Registry::register`。默认使用允许混合字系的 Unicode 策略，调用方可明确选择更严格的策略。

`Decision` 区分 `Accepted`、`Duplicate`、`Collision` 和 `Rejected`。碰撞返回已有名称及候选名称的诊断，策略拒绝返回原因与诊断。被拒绝的请求不会占用名称或键，风险等级本身不直接拒绝名称。

`Registry::records` 返回按注册顺序排列的版本化记录副本。每条记录包含原始名称、计算键、库/数据版本、键策略、应用策略版本和 Unicode 策略。升级示例时，库版本常量需要与 `moon.mod` 同步。

接入实现在 [registry.mbt](registry.mbt)，[可执行程序](../../cmd/registration/main.mbt)导入这一应用示例；示例本身只导入 MoonSpoof 根包的公开 API。这是可供应用改写的源码，不是核心库新增的稳定 API。

## 快照恢复与迁移

`Registry::snapshot` 返回独立的记录数组及版本头，空索引也保留版本头。`Snapshot`、`StoredIdentifier` 定义持久化适配层应保存的数据。本示例在内存中演示这些值，没有提供磁盘存储或序列化文件格式。

用当前应用配置调用 `Registry::restore(snapshot, key_policy, validate_syntax=..., application_policy_version=...)`。恢复时比较完整版本头，检查每条记录的元数据，重新计算键并重新校验原始名称。旧版本、篡改键、重复记录、碰撞及无效名称都会被拒绝，不会返回部分加载的索引。

更换库、Unicode 数据、碰撞策略、语法规则或配置后，使用旧快照和新配置调用 `Registry::rebuild`。它忽略旧键及旧元数据，将原始名称重新校验到独立的新索引。只有收到 `Ok(new_index)` 才替换活动索引。`Err(decisions)` 包含需要复核的重复、碰撞或拒绝决策，原索引保持不变。显式处理冲突，不能通过丢弃账号解决。

例如，`I` 和 `l` 在折叠键策略下可以共存，在敏感键策略下发生碰撞。把这一对名称迁移到敏感策略会返回碰撞，同时保留原有的两个账号。迁移不会只给旧键改版本标签而跳过重算。

验收证据见[注册测试](registry_test.mbt)和[快照/迁移测试](snapshot_test.mbt)。

## 应用职责

语法回调独立于 Unicode 策略，必须在所记录的应用策略版本内保持确定性。测试回调只拒绝空格与斜杠，并非完整账号名称语法或 Unicode 标识符标准。

此存储只支持单进程顺序调用。生产存储必须在选定的策略/版本命名空间中原子执行碰撞键唯一约束，并单独处理原始名称的唯一性。并发注册不能只依靠先查询再插入。

示例默认允许混合字系，以便应用区分真实键碰撞与策略允许的多语言名称。选择更严格的策略后，混合字系名称可能在碰撞查询前就被拒绝。这属于应用策略选择，不代表完整 UTS #39 合规，也不保证被接受的名称没有风险。

回调函数不会被持久化，应用需要恢复与策略版本相符的实现。快照元数据用于检查兼容性，不用于认证；持久化数据应另行认证。切换索引前，需要协调迁移与并发写入；内存重建成功不等于数据库事务完成。

## 选择启用 Identifier_Status

演示另定义 `status_checked_syntax`，先调用 `@moonspoof.validate_identifier_status`，再执行应用语法检查，并将类型化失败转换为码点/序号原因。它接受 `alice中文`，在标量序号 5 的 U+1F600 处拒绝 `hello😀`。这是可选的原始属性过滤，[规范等价与语法边界](../../docs/UNICODE_PROPERTIES_zh.md)保持明确。

对已有账号启用时，使用新的 `application_policy_version`。恢复会拒绝旧快照，重建列出需复核账号并保留原索引。[接入测试](status_test.mbt)验证这一迁移。

里程碑证据及后续标准工作见[路线图](../../docs/ROADMAP_zh.md)。
