import { createContext, useContext, useEffect, useMemo, useState } from 'react';

const Chinese = {
  'No elevated risk signal': '无升高的风险信号',
  'Scroll sideways to see all columns. Keyboard: Left / Right.': '左右滑动查看全部列；键盘可用左 / 右方向键。',
  'Character evidence table': '字符证据表，可横向滚动',
  'Competitor comparison table': '竞品对比表，可横向滚动',
  'MoonSpoof — Looks the same. Is it?': 'MoonSpoof — 看起来一样，真的一样吗？',
  'Skip to workbench': '跳转到演示工作台', 'Main navigation': '主导航', 'Live demo': '现场演示', 'Comparison': '竞品对比', 'Source': '源代码',
  'Looks the same.': '看起来一样。', 'Is it?': '真的一样吗？',
  'Unicode spoof detection, built in MoonBit.': '用 MoonBit 构建的 Unicode 混淆检测引擎。',
  'Turn a convincing lookalike into inspectable evidence.': '把难以察觉的字符伪装，变成可核验的证据。',
  'Different codepoints.': '不同的码点。', 'One visual identity.': '相同的视觉外形。', 'Examine the difference': '检查字符差异',
  'Engine tools': '引擎工具', 'Pair comparison': '双字符串对比', 'Collision scanner': '批量冲突扫描', 'Glyph inspector': '字符诊断', 'Bidi audit': '双向文本审计',
  'JS engine / local': 'JS 引擎 / 本地运行', 'Starting engine…': '引擎启动中…', 'Engine unavailable': '引擎不可用',
  'The engine failed to start.': '引擎启动失败。', 'Retry engine': '重新启动引擎',
  'Input stays on this device. No API request.': '输入保留在此设备，不发送 API 请求。', 'MoonBit source → JavaScript → Web Worker': 'MoonBit 源码 → JavaScript → Web Worker',
  'A different integration.': '不同的集成方式。', 'An honest comparison.': '有依据的竞品对比。',
  'MoonSpoof brings Unicode security primitives to MoonBit. ICU remains the broader standards implementation; the difference here is integration and inspectability.': 'MoonSpoof 为 MoonBit 提供 Unicode 安全基础能力。ICU 的标准覆盖更完整；本项目的差异在于原生集成与可解释诊断。',
  'Documented capabilities, not a measured speed ranking': '根据文档比较能力，不代表实测速度排名', 'Capability': '能力',
  'Primary runtime': '主要运行环境', 'MoonBit · JS / WASM / native': 'MoonBit · JS / WASM / 原生', 'C / C++ · Java': 'C / C++ · Java',
  'Pair matching': '双字符串匹配', 'Canonical skeleton keys': '规范化混淆骨架键', 'SpoofChecker + skeleton API': 'SpoofChecker 与骨架 API', 'Glyphs against preferred scripts': '按偏好字系检查混淆字符',
  'Character evidence': '字符级证据', 'Codepoint, script, target, rules': '码点、字系、映射目标与规则', 'Check flags and restriction results': '检查标记与限制等级结果', 'Confusable glyph candidates': '可混淆字符候选',
  'Batch grouping': '批量分组', 'Built-in skeleton buckets': '内置骨架哈希分桶', 'Compose with skeleton API': '用骨架 API 自行组合', 'Application-defined grouping': '由应用层实现分组',
  'Standards coverage': '标准覆盖', 'Scoped implementation; gaps below': '范围有限；缺项见下文', 'Broader Unicode security implementation': '更完整的 Unicode 安全实现', 'Mixed-script and homoglyph checks': '混合字系与同形字符检查',
  'API references · reviewed 11 Oct 2026': 'API 参考资料 · 核对日期：2026 年 10 月 11 日',
  'Small surface.': '简洁的接口。', 'Inspectable core.': '可审查的内核。',
  'Generated, version-pinned Unicode data. Pure MoonBit algorithms. The same facade serves the browser, command line, and library integrations.': '固定版本的 Unicode 生成数据，纯 MoonBit 算法。同一组公开接口服务于浏览器、命令行与库集成。',
  'Explore the architecture': '查看代码架构', 'MoonBit / pair comparison': 'MoonBit / 双字符串对比',
  'Know the boundary.': '明确实现边界。',
  'This is a scoped UTS #39 implementation, not a phishing verdict. NFD, full case folding, confusable mappings, and default ignorables use Unicode 16.0 data. Script analysis currently exposes eleven script categories; other scripts are reported as Unknown. Full Script_Extensions resolution, Identifier_Status validation, mixed-number detection, and bidi skeleton reordering are not implemented. Fullwidth ASCII folding and repeated normalization to a stable key are application extensions.': '本项目实现 UTS #39 的部分机制，不能据此判定钓鱼攻击。NFD、完整大小写折叠、混淆映射与默认忽略字符使用 Unicode 16.0 数据。字系分析目前公开十一类字系，其余标为 Unknown。尚未实现完整 Script_Extensions 解析、Identifier_Status 校验、混合数字系统检测和双向骨架重排。全角 ASCII 折叠与重复归一化至稳定键属于应用扩展。',
  'Read the implementation scope': '查看实现范围', 'MoonBit Hackathon 2026 · Apache-2.0': 'MoonBit 黑客松 2026 · Apache-2.0',
  'Reference / candidate': '参考文本 / 待测文本', 'Reference: {text}': '参考文本：{text}', 'Candidate: {text}': '待测文本：{text}',
  'Inspect {hex} at position {position}': '检查第 {position} 位字符 {hex}',
  'Custom input. Run the comparison to inspect character evidence.': '自定义输入。运行对比以查看字符证据。',
  'bidi control': '双向控制符', 'invisible': '不可见字符', 'Prototype': '映射目标', 'removed': '已移除',
  'Run comparison to reveal codepoints.': '运行对比以显示码点。', 'Try the engine': '操作检测引擎', 'Local execution': '本地执行',
  'Test case': '测试场景', 'Custom input': '自定义输入', 'Reference identifier': '参考标识符', 'Candidate identifier': '待测标识符',
  'Ignore case using a folded skeleton key': '使用折叠骨架键忽略大小写', 'Comparing…': '对比中…', 'Compare identifiers': '对比标识符',
  'Analyzing input': '正在分析输入', 'Ready to compare': '等待运行对比', 'Identical identifiers': '标识符完全相同',
  'Same skeleton. Different text.': '骨架相同，文本不同。', 'Distinct skeletons': '混淆骨架不同',
  'Equality alone is not a spoof signal.': '文本相同本身不构成伪装信号。',
  'These identifiers collide under the selected policy.': '这两个标识符在所选策略下发生骨架冲突。',
  'No skeleton collision for this pair.': '这组文本没有发生骨架冲突。', 'Edit either identifier and run comparison.': '编辑任一标识符后运行对比。',
  'Reference key': '参考骨架键', 'Candidate key': '待测骨架键', 'Candidate risk': '待测文本风险',
  'Cyrillic substitution': '西里尔字符替换', 'A Latin a and a Cyrillic а. Same shape, different identity.': '拉丁字母 a 与西里尔字母 а：外形相同，字符身份不同。',
  'Invisible character': '不可见字符', 'A zero-width space leaves no visible trace. Inspect the codepoints.': '零宽空格不会留下可见痕迹，可通过码点检查发现。',
  'Bidi filename': '双向文本文件名', 'A right-to-left override changes display order. The control is flagged.': '从右到左覆盖控制符改变显示顺序，引擎会标记该控制符。',
  'Canonical equivalence': '规范等价文本', 'One accented character or a base plus combining mark. Both normalize equally.': '预组合重音字符与字母加组合标记，规范化后等价。',
  'Multilingual identifier': '合法多语言标识符', 'A legitimate Japanese script combination. Mixed scripts alone do not prove an attack.': '合法的日文字系组合。混合字系本身不证明恶意攻击。',
  'Distinct identifiers': '不同标识符', 'Different skeletons. Confusable analysis does not measure reputation.': '不同的混淆骨架。混淆分析不判断信誉或恶意程度。',
  'No rules triggered': '未触发规则', 'Mapped glyph': '字符发生映射', 'Review advised': '建议检查', 'Cross-script signal': '跨字系风险信号', 'Control character signal': '控制字符风险信号',
  'Safe': '无规则风险', 'Low': '低', 'Medium': '中', 'High': '高', 'Critical': '严重',
  'Common': '通用', 'Inherited': '继承', 'Latin': '拉丁', 'Cyrillic': '西里尔', 'Greek': '希腊', 'Arabic': '阿拉伯', 'Hebrew': '希伯来', 'Han': '汉字', 'Hiragana': '平假名', 'Katakana': '片假名', 'Hangul': '韩文', 'Unknown': '未知',
  'SingleScript': '单一字系', 'HighlyRestrictive': '高度限制', 'ModeratelyRestrictive': '中度限制', 'MinimallyRestrictive': '最低限制', 'Unrestricted': '不受限制',
  '{count} codepoints': '{count} 个码点', 'Character mappings and security signals': '字符映射与安全信号',
  'Position': '位置', 'Glyph': '字形', 'Codepoint': '码点', 'Script': '字系', 'Prototype / signal': '目标 / 信号',
  'Inspect position {position}, {hex}': '检查第 {position} 位字符，{hex}', 'Bidi control': '双向控制符', 'Default ignorable': '默认忽略字符', 'Control': '控制字符', 'mapped': '已映射', 'Unchanged': '未改变',
  'mixed script identifier': '混合字系标识符', 'mixed script confusable triad': '拉丁 / 希腊 / 西里尔字系混用', 'cross script confusable glyph': '跨字系混淆字符',
  'invisible or format character': '不可见或格式字符', 'bidi control character': '双向控制字符', 'bidi override character': '双向覆盖字符', 'bidi file extension spoof': '文件扩展名双向伪装信号', 'control character': '控制字符',
  '{time} ms · worker execution on this device': '{time} 毫秒 · 此设备的工作线程执行时间',
  'One list. Every collision.': '一份名单，找出冲突。', 'Skeleton buckets group colliding identifiers without comparing every pair.': '利用骨架哈希分桶聚合冲突标识符，避免逐对比较。',
  'Identifiers · one per line or comma separated': '标识符列表 · 每行一个或以逗号分隔', 'Ignore case': '忽略大小写', 'Scanning…': '扫描中…', 'Scan for collisions': '扫描标识符冲突',
  '{count} collision groups': '{count} 组冲突', '{count} identifiers': '{count} 个标识符', '{count} entries': '{count} 条记录', 'No collisions in this list.': '此列表未发现冲突。', 'Repeated identical entries also count as collisions.': '完全相同的重复记录也计入冲突分组。',
  'Expose hidden direction.': '揭示隐藏的文本方向。', 'Inspect an identifier.': '逐字符检查标识符。',
  'Browser display follows bidi rules. Escaped source exposes the stored control characters.': '浏览器按双向规则显示文本，转义后的源文本揭示实际保存的控制字符。',
  'Inspect the script, mapping, and policy result for every codepoint.': '检查每个码点的字系、映射和策略校验结果。',
  'Source text or filename': '源文本或文件名', 'Identifier': '标识符', 'Allow mixed scripts in identifier policy': '允许标识符包含混合字系', 'Inspecting…': '检查中…', 'Inspect codepoints': '检查字符码点',
  '{level} risk signal': '{level}风险信号', 'Browser visual rendering': '浏览器视觉显示', 'Stored source · controls escaped': '实际存储文本 · 控制符已转义',
  'Skeleton': '混淆骨架', 'Restriction estimate': '限制等级估计', 'Identifier policy': '标识符策略', 'Accepted': '通过', 'Rejected': '拒绝',
  'Identifier cannot be empty': '标识符不能为空', 'Identifier length exceeds maximum allowed length': '标识符超过允许的字符数',
  'Identifier contains disallowed control character': '标识符包含不允许的控制字符', 'Identifier contains disallowed invisible format character': '标识符包含不允许的不可见格式字符',
  'Identifier contains disallowed bidirectional control character': '标识符包含不允许的双向控制字符', 'Identifier contains disallowed mixed scripts': '标识符包含当前策略不允许的混合字系',
  'An identifier must be text.': '标识符必须为文本。', 'Use at most 512 codepoints per identifier.': '每个标识符最多 512 个码点。',
  'The identifier list must be text.': '标识符列表必须为文本。', 'Use at most 200,000 characters per scan.': '每次扫描最多输入 200,000 个字符。', 'Use at most 5,000 identifiers per scan.': '每次扫描最多 5,000 个标识符。',
  'Engine startup timed out. Retry the engine.': '引擎启动超时，请重新启动引擎。', 'Engine worker failed. Retry the engine.': '引擎工作线程失败，请重新启动引擎。',
  'Engine response could not be decoded. Retry the engine.': '无法解析引擎响应，请重新启动引擎。', 'Scan timed out. Shorten the input and retry.': '扫描超时，请缩短输入后重试。',
};

const Context = createContext(null);

export function I18nProvider({ children }) {
  const [language, setLanguage] = useState(() => {
    try { return localStorage.getItem('moonspoof-language') === 'en' ? 'en' : 'zh'; }
    catch { return 'zh'; }
  });
  const value = useMemo(() => ({
    language, setLanguage,
    t(key, replacements = {}) {
      const text = language === 'zh' ? Chinese[key] ?? key : key;
      return text.replace(/\{(\w+)\}/g, (_, name) => replacements[name] ?? `{${name}}`);
    },
  }), [language]);
  useEffect(() => {
    document.documentElement.lang = language === 'zh' ? 'zh-CN' : 'en';
    document.title = value.t('MoonSpoof — Looks the same. Is it?');
    try { localStorage.setItem('moonspoof-language', language); } catch { /* Storage may be disabled. */ }
  }, [language, value]);
  return <Context.Provider value={value}>{children}</Context.Provider>;
}

export function useI18n() { return useContext(Context); }
