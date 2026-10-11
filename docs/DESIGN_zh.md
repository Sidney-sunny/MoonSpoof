---
name: MoonSpoof
description: 用于核验 Unicode 字符证据的哑光字形检查台。
colors:
  primary: "#78dce8"
  signal-hover: "#a9edf4"
  ground: "#0e1824"
  surface: "#152333"
  line: "#526a80"
  ink: "#eef5fa"
  muted: "#b0c4d5"
  selected: "#203c50"
  error: "#ffb7c3"
  code-string: "#bddbdc"
typography:
  display:
    fontFamily: "Manrope, ui-sans-serif, sans-serif"
    fontSize: "clamp(50px, 5.8vw, 80px)"
    fontWeight: 500
    lineHeight: 1.1
    letterSpacing: "-.04em"
  headline:
    fontFamily: "Manrope, ui-sans-serif, sans-serif"
    fontSize: "36px"
    fontWeight: 500
    lineHeight: 1.2
    letterSpacing: "-.035em"
  title:
    fontFamily: "Manrope, ui-sans-serif, sans-serif"
    fontSize: "15px"
    fontWeight: 600
  body:
    fontFamily: "Manrope, ui-sans-serif, sans-serif"
    fontSize: "13px"
    lineHeight: 1.9
  label:
    fontFamily: "Manrope, ui-sans-serif, sans-serif"
    fontSize: "11px"
  mono:
    fontFamily: "Cascadia Code, SFMono-Regular, Consolas, monospace"
  specimen:
    fontFamily: "Georgia, Times New Roman, serif"
    fontSize: "clamp(40px, 5.7vw, 80px)"
    lineHeight: 1.6
    letterSpacing: "-.04em"
rounded:
  square: "0"
spacing:
  compact: "8px"
  small: "12px"
  base: "16px"
  mobile-inset: "20px"
  inset: "24px"
  wide-inset: "32px"
  section-gap: "64px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.ground}"
    rounded: "{rounded.square}"
    padding: "14px 18px"
    width: "100%"
  button-primary-hover:
    backgroundColor: "{colors.signal-hover}"
  button-language:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    rounded: "{rounded.square}"
    padding: "0 12px"
  button-text:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
  input-identifier:
    backgroundColor: "{colors.ground}"
    textColor: "{colors.ink}"
    rounded: "{rounded.square}"
    padding: "12px 14px"
    width: "100%"
  tab:
    backgroundColor: "transparent"
    textColor: "{colors.muted}"
    padding: "22px 0"
  tab-selected:
    textColor: "{colors.ink}"
  container:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.square}"
  glyph-selector:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    rounded: "{rounded.square}"
  candidate-glyph:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
  candidate-glyph-hover:
    backgroundColor: "{colors.selected}"
  evidence-row-selected:
    backgroundColor: "{colors.selected}"
---

[English](../DESIGN.md)

# MoonSpoof 设计系统

## 概览

**创作核心：“字形检查台”**

字形检查台把字符外形作为标本，把码点作为证据。整个界面保持深色、哑光、细线分区与方形控件。放大的衬线字形提出视觉问题，紧凑的无衬线控件与等宽诊断数据提供可核验的答案。信息密度服务于评委检查实际代码的任务。

墨蓝画布与稍亮的工作面形成安静的层次。冰青色连接操作、选中字符与检测结果，冷白色承载主要文字。原始新月与双环栅格标志继续作为身份资产。项目负责人已否决重新绘制的替代符号与先前的琥珀色方案。当前实现没有装饰性图片、渐变表面或阴影。

**主要特征：**

- 哑光墨蓝表面，冰青色操作与证据。
- 细线行列、方形控件、平面色调层次。
- Manrope 界面文字、衬线字形标本、等宽源数据。
- 中英文共用控件，并保留当前工具状态。

本记录仅覆盖已交付的网页展示。标记值来自[样式表](../playground/src/style.css)、[应用组件](../playground/src/App.jsx)、[工具组件](../playground/src/components)与[语言实现](../playground/src/i18n.jsx)，并与 `.impeccable/review` 中最终的中英文桌面和移动截图核对。截图证明静态外观，源码证明键盘行为与状态保留；本次文档工作没有重新进行运行时或标准符合性验证。[Tailwind 语义颜色](../playground/tailwind.config.js)引用同一组 CSS 自定义属性，字体族也与实际无衬线和等宽字体栈一致。

## 颜色

配色采用冷色哑光工作面，青色统一承担操作与证据强调。文件头保留准确的 CSS 值；以下名称解释用途。侧车中的八级 OKLCH 色阶是合成的色板预览，并非额外交付的配色标记。

### 主色

- **冰青色**（`primary`，来自 `--signal`）：主操作、发生映射的字形、检测结果、选中标签下划线、光标、文字选择、焦点轮廓与有限的标题强调。
- **浅冰色**（`signal-hover`）：可用主操作的悬停反馈。

### 中性色与功能色

- **墨蓝**（`ground`）：页面画布与内嵌输入区域。
- **工作台蓝**（`surface`）：工作台、代码样例与 MoonSpoof 对比列。
- **钢灰蓝**（`line`）：结构边框、标本分隔、表格线与滚动条。
- **冷白**（`ink`）：主要文字、活动标签与未修改标本。
- **雾蓝**（`muted`）：说明文字、标签、非活动导航与诊断元数据。
- **选中石板蓝**（`selected`）：选中的字符证据行与待测字形的悬停背景。
- **错误玫瑰色**（`error`）：工作线程与任务错误文字，是主强调色之外的功能例外。
- **代码雾色**（`code-string`）：MoonBit 样例中的字符串常量。

**统一信号规则。** 操作、选中证据与检测结果使用同一冰青色；同时保留文字与选择标记，避免仅靠颜色传达含义。

## 字体

**展示字体：** Manrope，后接 CSS 无衬线回退栈。项目本地打包了拉丁字符字体，字重为 400、500、600、700。

**正文字体：** Manrope；未覆盖字符由系统字体回退。中文首屏标题显式加入 Microsoft YaHei 与 PingFang SC。

**标签与等宽字体：** Cascadia Code、SFMono-Regular、Consolas、monospace。这些是已安装字体的回退选择，并非打包保证。

**标本字体：** Georgia、Times New Roman、serif。首屏字形对照与焦点字符也使用 Georgia。

**字体性格：** 无衬线界面保持清晰紧凑，衬线标本展示字形差异。等宽字体用于实际保存的数据、码点、源码与运行元数据；表格数字便于纵向扫描。

### 层级

- **展示标题：** 中等字重（500），英文采用流动字号与紧凑字距；移动断点下固定为（52px）。中文采用独立范围 `clamp(44px, 5vw, 70px)`、行高（1.2）与字距（-.02em）；更高优先级的语言规则在移动端继续有效。
- **章节标题：** 中等字重（500），紧凑屏幕下常见章节标题缩小至（30px）。
- **区域标题：** 半粗字重（600），用于表单与证据标题；结果标题行高为（1.5）。
- **正文：** 章节说明文字。首屏说明更大（15px，行高 1.7），移动端缩小至（13px）。实现说明限制行宽（43ch），实现边界说明更宽（85ch）。
- **标签与数据：** 紧凑标签及等宽数据，部分次要元数据使用更小字号（10px）。这些是已有密度选择，不是未来页面统一的最小字号要求。

**标本规则。** 衬线字形是被检查的内容；保留标识符与码点各自的可读角色，不把标本效果变成装饰图标。

## 布局

展示页使用居中容器，上限（1280px），桌面两侧空间（48px）。实际公式为 `min(1280px, calc(100% - 96px))`。中等断点（1100px）下，两侧空间变为（28px）；紧凑断点（760px）下变为（18px）。页面最小宽度为（320px）。

可复用的空间语言是带边框、以细线划分的单一工作面：内部紧凑，章节之间留出更大空间。双字符串检查台采用两列 `minmax(0, 1.15fr)` 与 `minmax(0, 1fr)`；紧凑布局改为标本在上、控件在下，并用横线替代竖线。其他双列说明与工具区域也在紧凑断点堆叠。桌面章节间距（104px）缩至（64px）；这些是当前展示页的实际值，并非所有未来页面必须遵循的距离。页面的章节顺序和具体构图由[表面说明](../.impeccable/surfaces/playground-index-html.md)管理。

证据与竞品表格保留有意义的列宽，最小宽度分别为（580px）与（940px）。溢出限制在具有名称的横向滚动区域内。只有列超宽时才显示本地化提示，并使区域可获得键盘焦点。标签、段落与源码换行，不撑宽页面。紧凑页头隐藏演示锚点与版本，保留竞品、源码与语言操作。

## 层次与深度

界面没有盒阴影。深度来自墨蓝画布、较亮的工作面、选中行色调与钢灰蓝细线。输入区域回到画布色，产生嵌入工作台的层次。悬停仅改变颜色，不抬升或缩放控件。

**平面工作台规则。** 使用色调、细线与间距建立层级；保持平面表面与方形控件。

## 形状

可复用控件与容器采用直角。边框和表格线较细（1px），标签及标本选择使用更强的下划线（2px）。焦点为外置青色轮廓（2px），间隔（5px），不使用内嵌光晕。字符选择按钮保持带边框的正方形；原生复选框保留浏览器形状，强调色为青色。

规范身份资产是 `docs/assets/logo.jpg`，原样复制至 `playground/public/logo.jpg`。应用在两处文字标志中显示它，桌面（48px）、紧凑屏幕（36px）；同一栅格资产也是网站图标。原有方形底色属于资产内容。不得描摹成新标志、重新着色或制造替代身份图。页面通过内联 SVG 箭头表示导航与执行，数学等号作为实际比较内容使用。

## 组件

### 按钮

执行按钮方正、宽且明确。主操作横贯表单，采用冰青色底与墨蓝文字，实际 SVG 箭头位于末端。内边距（14px 18px）、最小高度（48px）、字号（12px）、字重（700）。可用状态悬停切换为浅冰色，背景色过渡（160ms ease）。焦点使用公共外置轮廓。禁用状态显示等待光标，透明度降至（.55）。

语言按钮透明、带钢灰蓝边框，水平内边距（12px）、最小高度（40px），悬停时边框和文字变为青色。重试操作是带下划线的文字按钮，最小高度（40px）。没有额外实现按下缩放或抬升状态。

### 容器

工作台与源码样例是细线容器，不是悬浮卡片。使用工作台蓝、直角与钢灰蓝边框（1px）。分隔线区分导航、内容、证据与底部。桌面内部边距常为（24px–36px），移动端工作台和工具为（20px）。错误文字使用错误玫瑰色及警告语义，不额外添加装饰容器。

### 输入与字段

标识符与文本域使用等宽字体、墨蓝背景、冷白文字、钢灰蓝边框、直角、内边距（12px 14px）与最小高度（46px）。标识符方向固定为从左到右，关闭拼写检查与自动完成。选择框保留原生行为，使用 Manrope（12px）。文本域可以垂直调整大小，行高为（1.8）。标签可见并关联控件，焦点使用公共青色轮廓。原生复选框强调色为青色。

### 导航

页头采用紧凑文字链接与原始栅格标志。工作台标签默认为雾蓝；选中时白色文字加青色下划线，悬停时文字变白。桌面标签半粗（12px）、最小高度（48px）、上下内边距（22px）。紧凑布局在一行均匀分布，字号（10px）、内边距（18px）、宽度上限（78px）。空间不足时引擎状态换到标签行下方。

标签使用 `tablist`、`tab` 与 `tabpanel` 语义。左右方向键循环选择，Home 与 End 选择首尾。只有活动标签进入 Tab 焦点序列，面板也可独立获得焦点。所有面板在隐藏时仍挂载，因此保留各工具输入。跳转链接在获得键盘焦点时显示，并指向工作台。

语言按钮切换完整译文、更新文档语言与标题，并在存储可用时保存 `moonspoof-language`。没有英文偏好时默认中文。语言切换不会重建工具树。这是语言偏好持久化，不表示刷新后保留分析输入。

### 字形证据

点击待测字形或表格字符按钮会更新同一个选中索引。衬线标本获得青色下划线，证据行获得选中石板蓝，焦点栏显示字形、码点、字系与映射目标，结果仍保持可见。悬停待测字形时使用同一选中石板蓝背景，不改变选择；证据表格的字符按钮则使用青色边框与文字反馈。字符按钮提供位置、码点与按下状态的可访问名称。不可见字符、双向控制符与所有 C0/C1 控制字符显示具有功能含义的空集标记。C0/C1 控制字符还有文字标签“控制字符”；Safe 风险级别的说明为“无升高的风险信号”，不表示没有触发任何描述性规则。

只有未请求减少动效时，选中标本下划线才以（220ms）和 `cubic-bezier(.16, 1, .3, 1)` 出现。检测结果与错误通过文字状态或警告输出。浏览器引擎运行于本地模块工作线程，界面显示就绪、重试与忙碌状态。设计继续展示实际结果，不制造诊断内容。

### 表格

表格折叠边框，使用细线分行与可见列标题。字符行提供带边框的选择按钮，最小正方形（36px）；选中或悬停时边框与文字变青。语义表题与行列标题范围保留上下文。溢出提示及命名、可聚焦区域属于紧凑屏幕下的组件行为，不是装饰说明。

## 应做与禁做

### 应做

- 复用哑光墨蓝配色与统一青色操作、证据信号。
- 保持方形控件、细线分组与平面色调层次。
- 保留原始栅格标志与其资产身份。
- 保留双语、键盘导航、可见焦点、工具状态及溢出提示。
- 区分视觉标本与等宽存储数据，展示真实诊断证据。

### 禁做

- 不以新绘制符号替换原标志，不恢复已否决的琥珀色方案。
- 不向哑光视觉加入光晕、渐变表面或阴影。
- 不在缺少命名滚动区域与本地化提示时隐藏超宽表格列。
- 不添加装饰性起始建议标签，不制造诊断或性能结论。
