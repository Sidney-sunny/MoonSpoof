# MoonSpoof 系统架构与技术设计说明书

本文档系统性阐述 MoonSpoof 的内部模块划分、数据管线、核心算法实现与性能优化设计。

---

## 1. 系统总体架构与处理管线

MoonSpoof 严格遵循 Unicode Technical Standard #39（UTS #39 Unicode 安全机制规范），建立分层、可解释的检测管线：

```text
[ 原始输入字符串 ]
        │
        ├──▶ [ Unicode 码点解析器 ]
        │         │
        │         ├──▶ 字符通用类别分类 (General Category)
        │         ├──▶ 不可见字符 / 零宽字符 / 双向控制符拦截
        │         └──▶ 码点格式化输出 (U+XXXX)
        │
        ├──▶ [ 字系分析引擎 (Script Engine) ]
        │         │
        │         ├──▶ Script 与 Script_Extensions 归属查询
        │         ├──▶ 混合字系识别
        │         └──▶ 限制级别评估 (UTS #39 Section 5)
        │
        ├──▶ [ 混淆骨架引擎 (Confusable Engine) ]
        │         │
        │         ├──▶ 规范分解与对齐 (NFD)
        │         ├──▶ UTS #39 Confusable 映射表匹配
        │         └──▶ 规范 Skeleton 组装
        │
        └──▶ [ 安全规则与诊断引擎 (Security Diagnostic) ]
                  │
                  ├──▶ 规则触发判定引擎
                  ├──▶ 风险等级定级 (Safe / Low / Medium / High / Critical)
                  └──▶ 结构化诊断报告输出 (DiagnosticReport)
```

---

## 2. 模块划分与职责契约

| 子系统模块 | 包路径 | 核心职责 |
| :--- | :--- | :--- |
| **Unicode Core** | `Sidney-sunny/moonspoof/src/unicode` | 码点属性提取、通用类别、不可见字符与双向控制符检测 |
| **Script Classifier** | `Sidney-sunny/moonspoof/src/script` | 字符字系归属、混合字系判定及 UTS #39 限制级别定级 |
| **Confusable Engine** | `Sidney-sunny/moonspoof/src/confusable` | UTS #39 Confusable Skeleton 转换与混淆关系比较 |
| **Security Diagnostic**| `Sidney-sunny/moonspoof/src/security` | 字符级可解释性诊断、规则命中评估与综合安全等级计算 |
| **Batch Scanner** | `Sidney-sunny/moonspoof/src/batch` | O(N) 复杂度的高吞吐量批量冲突分桶扫描 |

---

## 3. 核心算法与高吞吐量优化

### 3.1 UTS #39 Confusable Skeleton 转换

根据 UTS #39 第 4 节规范，判断两个字符串 $S_1$ 与 $S_2$ 是否在视觉上混淆，核心在于将其投影至标准骨架（Skeleton）：

$$\text{skeleton}(S) = \text{NFD}\left( \bigcup_{c \in \text{NFD}(S)} \text{confusable\_map}(c) \right)$$

MoonSpoof 的实现策略：
- 使用基于 Unicode 16.0.0 生成的标准数据映射。
- 绝大多数普通字符无混淆映射，零拷贝直通输出。
- 具有同形异码风险的字符（如西里尔字母 `а` U+0430、希腊字母 `ο` U+03BF）映射至标准目标（如拉丁字母 `a`、`o`）。
- 两字符串满足混淆条件当且仅当 $\text{skeleton}(S_1) = \text{skeleton}(S_2)$。

### 3.2 O(N) 批量用户名冲突分桶算法

若对 $N$ 个用户名进行两两逐对比较，算法复杂度为 $O(N^2)$。当用户名数量达到 10,000 至 100,000 时，比较次数将高达数亿次，无法在实际生产中运行。

MoonSpoof 采用**基于 Skeleton 的哈希分桶索引**：
1. 遍历输入的 $N$ 个用户名，对每个名称计算骨架字符串 $\text{sk}_i = \text{skeleton}(S_i)$，单次耗时 $O(L)$（$L$ 为字符串长度）。
2. 将用户名归入对应骨架的哈希桶：$\text{Buckets}[\text{sk}_i] \leftarrow \text{append}(S_i)$。
3. 提取所有容量大于 1 的哈希桶，即为存在混淆冒用风险的分组。
4. 全局时间复杂度线性降至 $O(N \cdot L)$，内存开销为 $O(N)$。

---

## 4. WebAssembly 架构与跨语言集成

- **MoonBit 核心编译为 WASM**：所有 Unicode 数据检索、Skeleton 算法与规则引擎均运行在纯 MoonBit 编译产物内，杜绝双重标准差异。
- **纯粹的前端展现层**：JavaScript 仅负责 DOM 交互、事件分发与组件渲染。
- **离线安全沙箱**：无需将待检测的敏感用户名或代码标识符上传至任何后端服务器，完全在客户端沙箱内本地完成。
