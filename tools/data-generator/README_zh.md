# MoonSpoof Unicode 数据生成器

[English](README.md)

仅使用 Python 标准库，无须安装包。在仓库根目录执行：

```powershell
python tools/data-generator/generate.py
moon info
moon fmt
pnpm --dir playground run verify:unicode
```

生成器下载缺失的 Unicode 16.0.0 文件，在写入源码前验证已记录的 SHA-256，生成排序后的混淆、字系与归一化表。已有下载会复用，请求超时为60秒。原始 `.txt` 和归一化向量被忽略；MoonBit 表与 `sources.json` 纳入版本管理。

| 官方文件 | 用途 |
| --- | --- |
| confusables.txt | 单码点混淆映射 |
| Scripts.txt | 字系范围；十一类具名字系及 Unknown |
| UnicodeData.txt | 规范分解与组合类 |
| CaseFolding.txt | 默认完整 C/F 折叠 |
| DerivedCoreProperties.txt | 默认忽略码点范围 |
| NormalizationTest.txt | 官方 NFD 验证向量 |

准确 URL 与哈希在 `sources.json`，未使用 ScriptExtensions.txt。更新版本需要明确审核清单，不能通过换哈希接受来源不明的差异。重新生成并格式化应复现已提交表。详见[实现范围](../../docs/SPECIFICATION_zh.md)。
