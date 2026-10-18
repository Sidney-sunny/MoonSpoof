# 账号注册参考接入

[English](README.md)

应用示例导入公开的 `Sidney-sunny/moonspoof` API，提供单进程内存参考存储。它不是账号服务，也不代表已经有外部应用采用。

## 运行验收测试

在仓库根目录使用 [`.moon-version`](../../.moon-version) 指定的编译器执行：

```powershell
moon test -p Sidney-sunny/moonspoof/examples/registration
```

## 注册调用位置

创建 `Registry` 时指定敏感或折叠键策略、应用自己的语法校验函数，以及应用策略版本。在注册决策位置调用 `Registry::register`。默认使用允许混合字系的 Unicode 策略，调用方可明确选择更严格的策略。

`Decision` 区分 `Accepted`、`Duplicate`、`Collision` 和 `Rejected`。碰撞返回已有名称及候选名称的诊断，策略拒绝返回原因与诊断。被拒绝的请求不会占用名称或键，风险等级本身不直接拒绝名称。

`Registry::records` 返回按注册顺序排列的版本化记录副本。每条记录包含原始名称、计算键、库/数据版本、键策略、应用策略版本和 Unicode 策略。升级示例时，库版本常量需要与 `moon.mod` 同步。

## 应用职责

语法回调独立于 Unicode 策略，必须在所记录的应用策略版本内保持确定性。测试回调只拒绝空格与斜杠，并非完整账号名称语法或 Unicode 标识符标准。

此存储只支持单进程顺序调用。生产存储必须在选定的策略/版本命名空间中原子执行碰撞键唯一约束，并单独处理原始名称的唯一性。并发注册不能只依靠先查询再插入。

完整 M1 验收条件见[路线图](../../docs/ROADMAP_zh.md)。快照校验、迁移和可运行演示是尚待补齐的接入工作。
