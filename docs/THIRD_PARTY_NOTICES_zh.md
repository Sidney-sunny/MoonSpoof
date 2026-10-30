# 第三方声明

[English](../THIRD_PARTY_NOTICES.md)

MoonSpoof 原创源码采用 [Apache-2.0](../LICENSE)。上游数据和字体保留各自许可证，模块的 Apache 声明不替代这些条款。

| 组件 | 用途 | 许可证及保留声明 |
| --- | --- | --- |
| Unicode 16.0.0 UCD 与安全数据 | 生成混淆、字系、规范化、大小写折叠、忽略字符、状态和十进制表 | [Unicode License v3](../licenses/UNICODE-3.0.txt)；来源文件标注 © 2024 Unicode, Inc. |
| `@fontsource/manrope` 提供的 Manrope 字体 | 浏览器演示字体 | [SIL Open Font License 1.1](../licenses/Manrope-OFL-1.1.txt)，Copyright 2019 The Manrope Project Authors |
| React、react-dom、scheduler | 浏览器 UI 运行时 | [MIT 许可证](../licenses/React-MIT.txt)，Copyright Meta Platforms, Inc. and affiliates；保留这些运行时包共享的声明 |
| Vite modulepreload 辅助代码 | 注入生产浏览器产物的运行时辅助代码 | 随站点保留 [Vite 许可证与声明](../licenses/Vite-LICENSE.txt) |
| ICU4J 76.1 | 单独下载的可选验证参考，不随库或演示打包 | [对应版本的上游许可证与声明](https://github.com/unicode-org/icu/blob/release-76-1/LICENSE)；再分发 ICU 时需保留 |

Unicode 许可证取自[官方文件](https://www.unicode.org/license.txt)，SHA-256 为 `e7a93b009565cfce55919a381437ac4db883e9da2126fa28b91d12732bc53d96`。当前许可声明含 Copyright © 1991–2026 Unicode, Inc.；生成数据保留 2024 年来源署名。[审核过的 URL 与哈希](../tools/data-generator/sources.json)明确每份数据输入。生成表属于经过转换的数据，生成器会写入署名。

包归档包含本声明与许可证全文。演示公开产物的 `licenses/` 提供 Unicode、Manrope、React 和 Vite 声明副本。分发生成源码、引擎或站点包时保留这些声明。其他安装依赖保留各自包内声明；本文不对上游源码重新授权。
