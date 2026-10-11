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
1. 遍历输入的 $N$ 个用户名，对每个名称计算骨架字符串 $\text{sk}_i = \text{skeleton}(S_i)$（或启用忽略大小写时的 $\text{skeleton\_case\_folded}(S_i)$），单次耗时 $O(L)$（$L$ 为字符串长度）。
2. 将用户名归入对应骨架的哈希桶：$\text{Buckets}[\text{sk}_i] \leftarrow \text{append}(S_i)$。
3. 提取所有容量大于 1 的哈希桶，即为存在混淆冒用风险的分组。
4. 全局时间复杂度线性降至 $O(N \cdot L)$，内存开销为 $O(N)$。
5. **大小写不敏感模式**：由 `find_confusable_groups_ignore_case` 原生提供，统一将诸如 `PAYPAL`、`pаypal`（西里尔字母 `а`）与 `Paypal` 汇聚至同一折叠规范特征 `paypal` 冲突簇中。

---

## 4. WebAssembly 架构与外部函数接口 (FFI)

MoonSpoof 提供跨运行时的零开销互操作契约：
- **MoonBit 核心编译为 WASM / 本地代码**：所有 Unicode 数据检索、Skeleton 算法、字系分析、标识符规范校验与规则引擎均运行在纯 MoonBit 编译产物内，保证各平台行为 100% 一致。
- **Web FFI 导出绑定 (`src/bindings/web`)**：
  - `spoof_skeleton(s : String) -> String`：计算 UTS #39 规范骨架。
  - `spoof_skeleton_case_folded(s : String) -> String`：计算忽略大小写的大小写折叠骨架。
  - `spoof_compare(a : String, b : String, ignore_case : Bool) -> String`：支持严格与大小写折叠两种模式的双标识符混淆比对。
  - `spoof_analyze(s : String) -> String`：导出字符级全量诊断报告（结构化 JSON）。
  - `spoof_batch_scan(raw_input : String) -> String`：对分隔符隔开的标识符集合执行 O(N) 批量冲突聚类。
  - `spoof_batch_scan_with_options(raw_input : String, ignore_case : Bool) -> String`：支持大小写折叠开关的高吞吐批量冲突扫描。
  - `spoof_validate_profile(s : String, is_permissive : Bool) -> String`：校验 UTS #39 第 3 节 IdentifierProfile 安全配置。
  - `spoof_get_restriction_info(s : String) -> String`：返回包含限制等级与字系数组的结构化 JSON。
- **离线安全沙箱**：无需将待检测的敏感用户名或代码标识符上传至任何后端服务器，完全在客户端沙箱内本地完成。

---

## 5. 命令行运行入口 (`cmd/main`)

MoonSpoof 随库附带纯 MoonBit 编写的命令行验证与演示套件：
- 通过 MoonBit 工具链直接运行：
  ```bash
  moon run cmd/main
  ```
- 覆盖五大核心检验流：
  1. 覆盖拉丁、西里尔、希腊、全角及零宽不可见字符的混淆等价比对；
  2. UTS #39 第 4 节大小写折叠混淆验证；
  3. 附带字符级码点十六进制、字系归属、映射目标的结构化安全诊断报告；
  4. UTS #39 第 3 节严格与宽松安全配置校验（IdentifierProfile）；
  5. 批量候选用户名集合的高吞吐 $O(N)$ 冲突聚类扫描。

---

## 6. 混合字系限制等级评定 (UTS #39 第 5 节)

MoonSpoof 完整实现 UTS #39 推荐的五级限制等级（RestrictionLevel）：
- **SingleScript（单一字系）**：标识符所有字符属于单一推荐字系（如全拉丁文、全汉字）。
- **HighlyRestrictive（高限制级）**：允许的混合字系组合，包括日文（`Latin + Han + Hiragana + Katakana`）和韩文（`Latin + Han + Hangul`）。
- **ModeratelyRestrictive（中限制级）**：拉丁文与任一非拉丁推荐字系的二元混合（`Latin + Cyrillic`、`Latin + Greek`、`Latin + Arabic`、`Latin + Hebrew`）。
- **MinimallyRestrictive（低限制级）**：所有字符均属于 Unicode 推荐字系集合的任意组合（如 `Cyrillic + Greek`）。
- **Unrestricted（无限制级）**：包含未分类（Unknown）字系或未分配码点。
- **三元字系攻击规则（`RULE_MIXED_SCRIPT_CONFUSABLE_TRIAD`）**：针对拉丁、西里尔、希腊字母之间普遍存在的欺骗性同形字符实施专属特征预警。

---

## 7. 双向文本与特洛伊木马源码防御 (CVE-2021-42574)

MoonSpoof 为双向文本（Bi-directional Text）安全设计了专属的防御管线：
- **强制方向覆盖符深度拦截**：专门识别从右至左覆盖符（`RLO` U+202E）与从左至右覆盖符（`LRO` U+202D），自动激活 `RULE_BIDI_OVERRIDE_CHARACTER`；
- **扩展名边界混淆防御**：当双向覆盖符与文件名分隔点（`.`）共同出现时，即刻触发 `RULE_BIDI_FILE_EXTENSION_SPOOF`，彻底阻止攻击者利用图形界面反向渲染伪装恶意可执行载荷（如将 `.exe` 视觉颠倒为 `.pdf`）；
- **工作台双重视角拆解 (Zone D)**：在 WebAssembly 演练平台中直观并列呈现人类图形界面渲染视觉序与系统物理内存字节序，让安全审计人员一目了然。
