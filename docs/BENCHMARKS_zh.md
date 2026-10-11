# MoonSpoof 性能报告

[English](BENCHMARKS.md)

于 2026-10-11 对重构后的 release JavaScript JSON ABI 测量。[benchmark-results.json](benchmark-results.json)保存环境与原始结果。旧实现的数字已被替换，不适合与本次结果直接比较。

## 环境与方法

Windows x64，Intel(R) Core(TM) i7-14650HX，Node v22.22.1，MoonBit 0.1.20260904。脚本为 `tools/bench.mjs`，在根目录执行 `pnpm --dir playground run bench`，先构建再测量。

每个场景预热后执行五轮。表格展示中位轮次总耗时及据此计算的每次调用平均耗时。字符串比较与诊断包括报告生成及 JSON 序列化，批量包括返回 JSON 的解析。不含线程通信、浏览器渲染与输入时间。这是本机测量，不是延迟保证、统计置信区间或 ICU/Python 速度对比。

| JSON ABI 场景 | 每轮调用数 | 中位轮次 ms | 每调用平均微秒 | 每秒单位数 |
| --- | --- | --- | --- | --- |
| spoof_compare(paypal, pаypal) | 10000 | 256.18 | 25.62 | 39,035 |
| spoof_batch_scan(1000) | 20 | 61.76 | 3088.11 | 323,823 |
| spoof_batch_scan(10000) | 20 | 701.29 | 35064.28 | 285,191 |
| spoof_analyze(pаypal_service+ZWSP) | 10000 | 526.76 | 52.68 | 18,984 |

比较与诊断的单位是调用，批次的单位是名称。1,000条数据产生40组冲突，10,000条产生200组；重复输入也计为冲突。10,000条测试直接调用 ABI，超过演示线程5,000条上限。

## 扩展性边界

查表使用二分搜索。NFD 会展开部分字符并排序组合片段，键归一化可能经过多轮。批量对每个键进行哈希分组，不逐对比较。成本取决于总代码点和键膨胀，不仅是名称数。这些数据不支持固定 O(N) 吞吐量保证或竞品速度排名。
