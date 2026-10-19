# MoonSpoof Unicode 数据生成器

[English](README.md)

仅使用 Python 标准库，无须安装包。在仓库根目录执行：

```powershell
python -m unittest discover -s tools/data-generator -p 'test_*.py'
python tools/data-generator/generate.py
moon info
moon fmt
pnpm --dir playground run verify:unicode
```

生成器要求预先存在已审核的 `sources.json` 清单；来源条目缺失或多余、Unicode 版本或 URL 改变、SHA-256 字段无效时，会在联网前终止。随后下载缺失的 Unicode 16.0.0 文件，在写入源码前验证全部九份文件的校验值，生成排序后的混淆、字系与归一化表。再生成过程只读取清单；清单缺失时应从版本控制恢复，不能根据缓存文件重新建立校验值。已有下载会复用，请求超时为 60 秒。原始 `.txt` 下载被忽略；MoonBit 表与 `sources.json` 纳入版本管理。

验证器直接从已通过校验值检查的 `NormalizationTest.txt` 读取归一化向量，拒绝空测试集、列格式错误和无效 Unicode 标量值。旧的 `normalization-vectors.json` 缓存不再生成或读取。

| 官方文件 | 用途 |
| --- | --- |
| confusables.txt | 单码点混淆映射 |
| Scripts.txt | 完整字系范围及兼容枚举 |
| UnicodeData.txt | 规范分解与组合类 |
| CaseFolding.txt | 默认完整 C/F 折叠 |
| DerivedCoreProperties.txt | 默认忽略码点范围 |
| NormalizationTest.txt | 官方 NFD 验证向量 |
| ScriptExtensions.txt | 显式共享字系集合；缺省继承 Script |
| PropertyValueAliases.txt | 字系别名对应的规范长名称 |
| IdentifierStatus.txt | Allowed 范围；缺省为 Restricted |

新下载必须先匹配固定的校验值，再通过同目录临时文件原子写入缓存；下载或写入失败不会留下不完整的缓存文件。已有缓存仍会在生成任何源码前进行校验。

准确 URL 与哈希在 `sources.json`，ScriptExtensions.txt 和 PropertyValueAliases.txt 提供完整扩展集合，IdentifierStatus.txt 提供 Allowed 范围，默认值为 Restricted。更新版本需要明确审核清单，不能通过换哈希接受来源不明的差异。重新生成并格式化应复现已提交表。详见[实现范围](../../docs/SPECIFICATION_zh.md)。
