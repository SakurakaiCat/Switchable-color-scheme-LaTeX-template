# 可切换配色 · 书籍出版物 LaTeX 模板（明日方舟·孤星 · Lonetrail Book Template）

Arknights Lone Trail 风格的**书籍出版物**模板，基于 XeLaTeX 编译。
在原笔记模板的基础上完成书籍化改造：报告形制（A4 单面、课程表、学生学号）
换成物理书的形制（双面印刷、真页眉页脚、完整出版家具）。

> **致谢**：本项目基于 [ARKNIGHT-LONETRAIL-LATEX-TEMPLATE](https://github.com/M0nster-3/ARKNIGHT-LONETRAIL-LATEX-TEMPLATE) 修改而来，致敬原作者的惊艳设计。

---

## 📖 书籍化改造了什么

* **开本**：16 开正式出版物（185×260mm）双面印刷，订口/切口不对称版心，切口页码；
  另备 170×240 与 A4 两档，`documentclass` 选项 `trim=185x260|170x240|a4` 切换。
* **出版家具全套**：封面 → 扉页 → 版权页 → 目录 → 正文（章扉页）→ 封底；
  多卷合订本另有卷隔页（`\VolumeDivider`）。原「课程名 / 学生姓名 / 学号」
  信息表替换为「丛书行 / 卷次行 / 作者 / 出版方 / 版次 / 书号」。
* **页面结构**：`frontmatter / mainmatter / backmatter` 三段结构，前装罗马页码。
* **版式**：`lonetrailbook.cls` 统一承担——章/节标题安静形制（titlesec）、
  页眉双线 + 丛书行、六色定理环境、边注（sidenote）与通栏（fullwidth）。
* **换肤即时生效**：页面背景与封面全部改为随纸张尺寸自适应的实时 TikZ，
  不再依赖预渲染素材；换主题只改 `theme=NNN`，无需重跑素材脚本。
* **六色定理编码完整保留**：定义 / 定理 / 命题 / 推论 / 引理 / 例题盒子按
  主题色编码，读者扫一眼即可分辨环境类型。

---

## ⚡ 30 秒极简上手

1. **环境准备**：TeX Live 2023+（需 `xelatex`）。
2. **写书**：`chapters/` 下写正文，`main.tex` 顶部改封面/版权/封底信息。
3. **编译**：

```bash
xelatex main.tex          # 日常快速查看（按需再跑 1–2 遍稳定目录/引用）
python tools/lonetrail.py quick    # 同上，封装版
```

---

## 🎨 换肤与自定义主题

* **切换主题**：改 `main.tex` 里 documentclass 的 `theme=000`（或运行
  `python tools/lonetrail.py theme 042 --no-open`）。
* **预览选色**：`palettes/PDF Previews/` 收录 144 套主题的完整编译样例
  （含索引表），`palettes/PNG Previews/` 是效果长图。
* **自制主题**：复制 `palettes/tex/theme_template.tex` 改 RGB 数值，
  放回 `palettes/tex/` 即被自动识别（`tools/lonetrail.py` 启动时同步到
  `palettes/themes.tex`）。

### 🎨 孤星色彩速查与避坑指南

| 颜色名称 | 出现位置 / 作用 | 选色建议与避坑 |
| :--- | :--- | :--- |
| **`qiancheng`** | 封面主标题、大章节标题、页眉页脚线、标题盒 | **中深主色**（明度 30%~55%），保证浅底上对比分明，切忌过浅 |
| **`lv` / `huang` / `hong`** | 封面及正文经典三色条带（左/中/右） | **明度均衡**（冷/暖/点睛三段式），避免某一颜色过于刺眼 |
| **`qianbai`** | 页面物理纸张底色 | **极高明度**（RGB 242~252），可微偏暖米或冷灰，切忌偏灰暗 |
| **`mibai`** | 背景网格点阵、暗纹水印 | **仅比 `qianbai` 深 3%~8%**，作为背景呼吸感，太深会干扰阅读 |
| **`heise`** | 正文字体颜色（段落、公式、表格） | **极低明度**（RGB 0~35），推荐纯黑或深墨色，确保久读不累 |
| **6大定理色** | 定义/定理/命题/推论/引理/例题盒子 | **色相错开 + 中等明度**（40%~60%），读者扫一眼即可秒辨环境 |

---

## 📝 封面 / 版权 / 封底 信息（main.tex）

在 `main.tex` 的元数据区直接修改即可：

```tex
\documentclass[trim=185x260, theme=000, bg=grid]{lonetrailbook}

\title{测度论讲义}              % 封面主标题
\subtitle{Lecture Notes on Measure Theory}  % 封面副标题（西文）
\seriesname{孤星学术丛书}        % 丛书行（封面/章扉页顶部）
\author{莱茵实验室}
\publisher{Rhine Lab Pioneer Project}
\isbn{978-7-0000-0000-0}        % 留空则版权页/封底不显示书号
\edition{2026 年 10 月第 1 版}
\volumeline{第一卷 · 可测空间}   % 卷次行（合订本写「四卷合订本」）
\volumelineEN{Volume I · Measurable Spaces}
\coverline{$\displaystyle\int_X f\,\mathrm{d}\mu$}  % 封面代表公式槽
\watermark{$\displaystyle\int$}   % 封面/封底数学水印
\blurb{封底内容简介……}
\shelflist{分卷列表……}           % 封底分卷列表，可留空

% 页眉丛书行 / 页脚注脚行（留空即不显示）
\renewcommand{\LoneSeriesMark}{孤星学术丛书 · 测度论讲义}
\renewcommand{\LoneFootnoteLine}{\kaishu 书籍出版物模板}
```

* `\DisplayCover` / `\DisplayTOC` 已由 `\maketitle` / `\tableofcontents` 取代，
  注释对应行即可隐藏。
* 章扉页槽位：`\LonePlateSymbol / \LonePlatePartCN / \LonePlateQuote /
  \LonePlateQuoteBy / \LonePlateImage` 按章号提供母题、篇名、题记与肖像；
  卷隔页槽位：`\LoneVolumeTitle / \LoneVolumeBlurb / \LoneVolumeMark`。

---

## 📂 目录结构速览

```text
├── lonetrailbook.cls      书籍出版物基类（版心/页眉页脚/标题/出版家具总装）
├── main.tex               主入口：类选项、封面信息、正文入口
├── chapters/              正文各章
├── styles/                版式家具
│   ├── background.tex     页面背景（实时 TikZ 网格 + 三色角标）
│   ├── cover.tex          封面/扉页/版权页/封底/卷隔页/章扉页
│   ├── contents.tex       目录版式（章行主题色短线）
│   └── boxes.tex          六色定理环境 / 例题 / 习题 / 注 / 题解收集
├── palettes/
│   ├── tex/               单套主题独立配色文件（新增/删除主题放这里）
│   ├── themes.tex         主题配色总控（脚本启动自动同步）
│   ├── PNG Previews/      各主题效果长图
│   └── PDF Previews/      144 套主题完整编译样例与索引表
├── assets/fonts/          模板自带字体（Avant Garde 展示字 + 思源黑体）
└── tools/lonetrail.py     编译与主题同步脚本
```

---

## 💡 常见问题与避坑

1. **换主题后正文哪些地方会变？**
   全部会变：纸色、背景网格、三色角标、定理六色、目录短线、封面/封底。
   这些都是实时 TikZ / 颜色 token，换 `theme=NNN` 后编译即生效，
   不再需要旧版的「素材重渲」步骤。
2. **A4 草稿模式**：`trim=a4` 可用 A4 纸打样；`bg=clean` 可关掉背景网格。
3. **屏幕阅读**：`screen` 类选项会给纸面铺主题米色（`qianbai`），
   印刷默认保持白纸。
4. **美术标题栏（boxart）**：类选项 `boxart` 让六大定理盒回到原版笔记
   模板的标题盒形制（Rhine logo 戳 + 竖排环境名 + 英文大字 + 三色条）。
   需要工程内有 `assets/tikz/` 源并渲染出 `assets/pdf/`（换主题后重跑
   `python tools/lonetrail.py` 的渲染即同步换色）。不开启则用学术形制
   （粗左线 + 彩色标签），无需任何素材。
5. **单面排版**：`oneside` 类选项（订口/切口对称化、无空白反页；
   oneside/twoside 经类选项传给 ctexbook，geometry 不认 oneside key）。

---

<details>
<summary><b>🛠️ 命令行与脚本参数（点击展开）</b></summary>

```bash
python tools/lonetrail.py quick              # 仅编译正文 1 遍
python tools/lonetrail.py theme 042          # 切换主题并编译
python tools/lonetrail.py theme --list       # 打印全部主题清单及当前应用
```
常用可选参数：
- `--passes N`：正文编译遍数
- `--no-open`：编译后不自动启动 PDF 阅读器
- `-p/--project`：指向书籍工程目录（把模板同步/换肤跑在别的书上）
- `-t/--template`：`build` 子命令同步用的模板目录

</details>

---

## 📜 字体与许可

- **ITC Avant Garde Gothic Bold**：商业字体，版权归 Monotype / ITC 所有，仅供个人学习研究。
- **思源黑体（Source Han Sans）**：遵循 SIL Open Font License (OFL)。
- 模板代码遵循原项目开源许可，原项目版权归原作者所有。
