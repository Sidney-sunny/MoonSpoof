# 更新日志

[English](../CHANGELOG.md)

## 未发布

### 修复

- Unicode 再生成现在要求预先存在完整且已审核的来源清单，在下载或生成前校验固定版本、URL 和校验值字段，不再根据缓存数据重写清单；离线回归检查已接入 CI。
- CI、Pages 和 Copilot 环境统一安装 `.moon-version` 中记录的编译器版本，避免最新工具链变化引入未经审核的格式化和接口变更。

## [0.1.0](https://github.com/Sidney-sunny/MoonSpoof/releases/tag/v0.1.0) - 2026-10-12

MoonSpoof 首个公开版本：使用纯 MoonBit 实现 Unicode 易混淆字符与标识符风险分析引擎，并提供双语浏览器演示站。

### 新增

- 固定使用 Unicode 16.0.0 的易混淆映射、脚本、规范分解、完整默认大小写折叠和默认可忽略字符数据；六份官方来源文件均记录 SHA-256 校验值。
- 稳定的应用 skeleton：支持 NFD 规范化、Hangul 算法分解、默认可忽略字符移除，以及全角 ASCII 和表意空格折叠。
- 大小写敏感和不敏感的双字符串比较，以及基于哈希的批量碰撞分组；保留首次出现顺序和重复条目。
- 逐字符证据、混合脚本限制等级估计、可配置标识符策略，以及不可见字符、控制字符、双向覆盖和文件扩展名伪装启发式规则。
- MoonBit 公共 API、命令行演示、JavaScript 浏览器绑定，以及 WASM、JavaScript 和 native 编译目标支持。
- 中文/英文 React 演示站，包含字符串比较、字符诊断、批量扫描、双向文本渲染、Worker 引擎和 GitHub Pages 部署。
- 单元、回归、白盒、属性、浏览器 ABI 和 Worker 生命周期测试；官方 Unicode 规范化与映射校验，以及可复现的基准工具。
- 双语 API、架构、实现范围、基准和品牌文档。

### 发布前开发阶段的修正

- 使用 Unicode 数据支持的 NFD 和完整默认 C/F 折叠替代不完整的规范化与大小写处理。
- 大小写不敏感比较仅依据折叠键相等，与对应批量分组保持一致。例如，`I` 与 `l` 在敏感模式下碰撞，在折叠模式下不同；两种模式是独立的等价关系。
- 使映射与规范化输出达到稳定状态，覆盖 Hangul 和规范化后再次命中映射的目标字符。
- 修正诊断 JSON 控制字符转义、非 BMP 码点处理、CJK 限制等级估计、批量顺序和 Worker 失败处理。
- 使生成的 Unicode 来源清单排序在不同平台上保持一致。

### 范围与兼容性

- MoonSpoof 实现部分 UTS #39 机制，不声称完整符合标准；键匹配或风险信号不代表恶意意图。
- 脚本分析提供十一类命名脚本和 Unknown。本版本不实现 Script_Extensions、Identifier_Status、混合数字检测、NFKC/NFKD 或双向 skeleton 重排。
- 标识符策略属于应用层检查，调用方需要自行校验标识符语法；文件扩展名伪装检测属于启发式规则。
- 全角折叠和稳定键规范化属于应用扩展。持久化键时应同时保存库版本和 Unicode 数据版本，并在升级时重新计算。

参阅[实现范围](SPECIFICATION_zh.md)、[API 契约](API_SPECIFICATION_zh.md)和[在线演示](https://sidney-sunny.github.io/MoonSpoof/)。
