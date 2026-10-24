% ============================================================================
%  lonetrailbook.cls — 孤星 · 书籍出版物类
%
%  从「明日方舟·孤星」笔记模板改造而来的书籍出版基类：把 A4 单面、学生姓名/
%  学号/课程表的报告形制，换成物理书的形制——
%    · twoside 双面印刷 + 真页眉页脚（页眉双线、切口页码、页脚丛书行）
%    · frontmatter / mainmatter / backmatter 三段结构与罗马页码前装
%    · 环衬→扉页→版权页→目录→正文→封底 的完整出版家具
%    · 章/节标题走 titlesec 安静形制，六色定理环境按主题配色编码
%    · 全部颜色 token 来自 palettes/themes.tex 的 \SelectTheme，可一键换肤
%    · 页面背景与封面均为随纸张尺寸自适应的实时 TikZ，不再依赖预渲染素材，
%      因此换肤即时生效，无需重跑素材渲染脚本
%
%  本类由模板工程维护，经 tools/lonetrail.py sync_template 部署到各书籍工程。
%
%  用法（书籍工程 main.tex）：
%      \documentclass[trim=185x260,theme=000,bg=grid]{lonetrailbook}
%      \input{config/preamble.tex}
%      \title{...}\author{...}\publisher{...}
%      \begin{document}
%      \maketitle
%      \tableofcontents
%      \mainmatter
%      \chapter{...}
%      \backmatter
%      \printindex
%      \BackCover
%      \end{document}
% ============================================================================
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{lonetrailbook}[2026/10/24 v1.0 Lonetrail book publication class]

% ============================================================================
%  选项
% ============================================================================
\RequirePackage{expl3}
\ExplSyntaxOn
\keys_define:nn { LT / opt }
  {
    theme    .tl_gset:N = \g_lt_theme_tl,
    trim     .tl_gset:N = \g_lt_trim_tl,
    bg       .tl_gset:N = \g_lt_bg_tl,
    fontsize .tl_gset:N = \g_lt_fontsize_tl,
    unknown  .code:n =
      { \typeout { LONETRAILBOOK: unknown key '\l_keys_key_str' ignored } },
  }
\tl_gset:Nn \g_lt_theme_tl    { 000 }
\tl_gset:Nn \g_lt_trim_tl     { 185x260 }
\tl_gset:Nn \g_lt_bg_tl       { grid }
\tl_gset:Nn \g_lt_fontsize_tl { 10pt }
% 包装器：\DeclareOption* 的体在 expl3 之外被词法化，必须先包一层
\cs_new_protected:Npn \lt@setkeys #1 { \keys_set:nx { LT / opt } {#1} }
\ExplSyntaxOff

\newif\ifLT@twoside   \LT@twosidetrue
\newif\ifLT@screen    \LT@screenfalse
\newif\ifLT@noanswer  \LT@noanswerfalse
\newif\ifLT@cleangrid \LT@cleangridfalse
% boxart：定理盒用原版孤星预渲染标题栏图（assets/pdf/<色>_1/2.pdf，随主题重渲）。
% 需要工程内有 assets/tikz 源并跑过 python tools/lonetrail.py 渲染。
\newif\iflt@boxart    \lt@boxartfalse

\DeclareOption{oneside}{\LT@twosidefalse\PassOptionsToClass{oneside}{ctexbook}}
\DeclareOption{twoside}{\LT@twosidetrue\PassOptionsToClass{twoside}{ctexbook}}
\DeclareOption{screen} {\LT@screentrue}
\DeclareOption{print}  {\LT@screenfalse}
\DeclareOption{noanswer}{\LT@noanswertrue}
\DeclareOption{boxart} {\lt@boxarttrue}
\DeclareOption{draft}  {\PassOptionsToClass{draft}{ctexbook}}
\DeclareOption{bg=grid} {\LT@cleangridfalse}
\DeclareOption{bg=clean}{\LT@cleangridtrue}
\DeclareOption*{\lt@setkeys{\CurrentOption}}
\ProcessOptions\relax

% 把 l3 变量导出为普通宏：后续类代码在非 expl3 语境使用，避免 _ 词法问题。
% tl 变量本质是宏，\edef 一层展开即可把字面值取出来，不残留 l3 名字。
\ExplSyntaxOn
\edef\LT@themeid{\g_lt_theme_tl}
\edef\LT@trim   {\g_lt_trim_tl}
\edef\LT@bg     {\g_lt_bg_tl}
\edef\LT@fs     {\g_lt_fontsize_tl}
\ExplSyntaxOff

% 纸张尺寸档位 → 版心规格。185x260 为 16 开正式出版物开本（本书采用）。
\newcommand{\LT@ApplyTrim}{%
  \edef\LT@trimval{\LT@trim}%
  \ifx\LT@trimval\LT@strA
    \geometry{paperwidth=185mm,paperheight=260mm,
             inner=25mm,outer=32mm,top=22mm,bottom=22mm}%
  \else\ifx\LT@trimval\LT@strB
    \geometry{paperwidth=170mm,paperheight=240mm,
             inner=20mm,outer=24mm,top=20mm,bottom=20mm}%
  \else\ifx\LT@trimval\LT@strC
    \geometry{paperwidth=210mm,paperheight=297mm,
             inner=25mm,outer=25mm,top=24mm,bottom=24mm}%
  \else
    \PackageWarning{lonetrailbook}{Unknown trim '\LT@trim'; using 185x260}%
    \geometry{paperwidth=185mm,paperheight=260mm,
             inner=25mm,outer=32mm,top=22mm,bottom=22mm}%
  \fi\fi\fi
}
\def\LT@strA{185x260}
\def\LT@strB{170x240}
\def\LT@strC{a4}

% ============================================================================
%  字体：有本地字库则自建（无系统依赖），否则退回 ctex 自带 fandol 字库，
%  保证模板在任何 TeX Live 上都能直接编译。
% ============================================================================
\newcommand{\LT@fontdir}{assets/fonts/}
\newif\ifLT@owncjk \LT@owncjkfalse
\IfFileExists{\LT@fontdir NotoSerifSC-Regular.otf}      {\LT@owncjktrue}{}
\IfFileExists{\LT@fontdir SourceHanSerifSC-Regular.otf}  {\LT@owncjktrue}{}
\IfFileExists{\LT@fontdir LXGWNeoZhiSongPlus.ttf}        {\LT@owncjktrue}{}
\IfFileExists{\LT@fontdir SimSun.ttf}                    {\LT@owncjktrue}{}
\ifLT@owncjk
  \PassOptionsToClass{fontset=none}{ctexbook}%
\else
  \PassOptionsToClass{fontset=fandol}{ctexbook}%
\fi
\LoadClass[\LT@fs]{ctexbook}

% ============================================================================
%  宏包
% ============================================================================
\RequirePackage{amsmath}
\RequirePackage{amssymb}
\RequirePackage{amsthm}
\RequirePackage{geometry}
\RequirePackage{xcolor}
\RequirePackage{graphicx}
\RequirePackage{tikz}
\usetikzlibrary{calc}
\RequirePackage[most]{tcolorbox}
\RequirePackage{fontspec}
\RequirePackage{enumitem}
\RequirePackage{etoolbox}
\RequirePackage{marginfix}
\RequirePackage{titlesec}
\RequirePackage{fancyhdr}
\RequirePackage{setspace}
\RequirePackage{multicol}
\RequirePackage{pifont}
\RequirePackage{eso-pic}
\RequirePackage[hidelinks]{hyperref}

% 被加载的类与宏包都以 \makeatother 收尾，会把 @ 关掉（.cls 内部本是 letter）。
% 所有 \RequirePackage 之后统一重新打开，此后整段不再加载宏包。
\makeatletter

% ============================================================================
%  主题配色（全部颜色 token 的唯一来源）
% ============================================================================
\IfFileExists{./palettes/themes.tex}{%
  \input{./palettes/themes.tex}%
  \SelectTheme{\LT@themeid}%
}{%
  \PackageError{lonetrailbook}{palettes/themes.tex not found}{%
    The class needs palettes/themes.tex from the template project.\MessageBreak
    Re-deploy with: python tools/lonetrail.py sync}%
}
% themes.tex 自带 \makeatother 收尾，会把 @ 关掉；再打开
\makeatletter

% --- 语义色层：把主题 token 映射成排版语义名 --------------------------------
% 主题只负责给色，语义层负责「这是什么用途的颜色」，二者解耦，
% 这样换肤不需要改动任何版式代码。
\colorlet{PaperIvory}{qianbai}          % 纸面底色
\colorlet{InkBrown}{heise}              % 主墨色
\colorlet{InkMuted}{mibai!42!heise}     % 次级墨色（规则线、页眉、辅文）
\colorlet{InkWash}{mibai}               % 淡底（盒子填充）
\colorlet{InkJoint}{heise}              % 正文混排墨色
\colorlet{main}{qiancheng}              % 强调主色（结构、标签）
\colorlet{second}{InkMuted}
\colorlet{third}{InkMuted}
\colorlet{structurecolor}{qiancheng}    % 标题结构色

% ============================================================================
%  字体设置（本地字库在位时覆盖 fandol 默认）
% ============================================================================
\ifLT@owncjk
  \newcommand{\LT@song}{}
  \IfFileExists{\LT@fontdir NotoSerifSC-Regular.otf}%
    {\renewcommand{\LT@song}{NotoSerifSC-Regular.otf}}{%
    \IfFileExists{\LT@fontdir SourceHanSerifSC-Regular.otf}%
      {\renewcommand{\LT@song}{SourceHanSerifSC-Regular.otf}}{%
      \IfFileExists{\LT@fontdir LXGWNeoZhiSongPlus.ttf}%
        {\renewcommand{\LT@song}{LXGWNeoZhiSongPlus.ttf}}{\renewcommand{\LT@song}{}}}}
  \newcommand{\LT@hei}{}
  \IfFileExists{\LT@fontdir NotoSansSC-Regular.otf}%
    {\renewcommand{\LT@hei}{NotoSansSC-Regular.otf}}{%
    \IfFileExists{\LT@fontdir SiYuan.otf}%
      {\renewcommand{\LT@hei}{SiYuan.otf}}{%
      \IfFileExists{\LT@fontdir SimHei.ttf}%
        {\renewcommand{\LT@hei}{SimHei.ttf}}{%
        \IfFileExists{\LT@fontdir LXGWNeoXiHeiPlus.ttf}%
          {\renewcommand{\LT@hei}{LXGWNeoXiHeiPlus.ttf}}{\renewcommand{\LT@hei}{}}}}}
  \newcommand{\LT@kai}{}
  \IfFileExists{\LT@fontdir STKaiti.ttf}%
    {\renewcommand{\LT@kai}{STKaiti.ttf}}{%
    \IfFileExists{\LT@fontdir ChillKai.ttf}%
      {\renewcommand{\LT@kai}{ChillKai.ttf}}{\renewcommand{\LT@kai}{}}}

  \ifdefstring{\LT@song}{}{}{%
    \setCJKmainfont{\LT@song}[Path=\LT@fontdir,Scale=1.05,
      BoldFont={\LT@song},AutoFakeBold=2.5,AutoFakeSlant=0.2]%
  }
  \ifdefstring{\LT@hei}{}{}{%
    \setCJKsansfont{\LT@hei}[Path=\LT@fontdir,Scale=1.05,
      BoldFont={\LT@hei},AutoFakeBold=2.5,AutoFakeSlant=0.2]%
  }
  \ifdefstring{\LT@kai}{}{}{%
    \setCJKmonofont{\LT@kai}[Path=\LT@fontdir,Scale=1.05,AutoFakeBold=2.5]%
  }
  \newCJKfontfamily\kaishu{\LT@kai}[Path=\LT@fontdir,Scale=1.05,AutoFakeBold=2.5]
  \newCJKfontfamily\songti{\LT@song}[Path=\LT@fontdir,Scale=1.05,AutoFakeBold=2.5]
  \newCJKfontfamily\heiti{\LT@hei}[Path=\LT@fontdir,Scale=1.05,AutoFakeBold=2.5]
\fi

% 西文衬线：模板自己的 ITC Avant Garde 只作标题展示字，正文西文用衬线。
\IfFileExists{\LT@fontdir TimesNewRoman.ttf}{%
  \setmainfont{TimesNewRoman.ttf}[Path=\LT@fontdir,Scale=1.0,Ligatures=TeX,
    BoldFont=TimesNewRomanBold.ttf,ItalicFont=TimesNewRomanItalic.ttf,
    BoldItalicFont=TimesNewRomanBoldItalic.ttf]%
}{%
  \IfFileExists{\LT@fontdir EBGaramond-Regular.ttf}{%
    \setmainfont{EBGaramond-Regular.ttf}[Path=\LT@fontdir,Scale=1.0,Ligatures=TeX,
      BoldFont=EBGaramond-Bold.ttf,ItalicFont=EBGaramond-Italic.ttf]%
  }{}%
}

% 展示字（封面大字、条带标签）：优先模板自带的 Avant Garde。
\newcommand{\LT@display}{}
\IfFileExists{\LT@fontdir ITC Avant Garde Gothic Bold.otf}{%
  \renewcommand{\LT@display}{ITC Avant Garde Gothic Bold.otf}}{%
  \IfFileExists{\LT@fontdir GoogleSans-Regular.ttf}{%
    \renewcommand{\LT@display}{GoogleSans-Regular.ttf}}{\renewcommand{\LT@display}{}}}
\providecommand{\LoneDisplay}{}
\ifdefstring{\LT@display}{}{%
  \renewcommand{\LoneDisplay}{\sffamily\bfseries}%
}{%
  \newfontfamily\LT@displayfont[Path=\LT@fontdir,UprightFont=*,
    BoldFont=*]{\LT@display}%
  \renewcommand{\LoneDisplay}{\LT@displayfont}%
}

% ============================================================================
%  版面：物理书开本 + 订口/切口
% ============================================================================
\LT@ApplyTrim
% oneside/twoside 由类选项传给 ctexbook（geometry 无 oneside key，只认类选项）；
% 这里只补边注栏与页眉页脚尺寸。
\geometry{
  marginparwidth=25mm,
  marginparsep=5mm,
  headheight=22pt,
  headsep=10pt,
  footskip=14mm
}
\setlength{\headwidth}{\textwidth}

% ============================================================================
%  排版默认值
% ============================================================================
\setstretch{1.32}
\setlength{\parindent}{2\ccwd}
\setlength{\parskip}{0pt plus 0.5pt}
\setlength{\parskip}{0pt}
\raggedbottom
\tolerance=1000
\emergencystretch=0.8em
\widowpenalty=10000
\clubpenalty=10000
\displaywidowpenalty=10000
\XeTeXlinebreaklocale "zh"
\XeTeXlinebreakskip = 0pt plus 0.2pt minus 0.1pt
\setlist{
  topsep=6pt plus 2pt minus 2pt,
  itemsep=3pt plus 1pt minus 1pt,
  parsep=0pt,
  partopsep=0pt
}
\setlist[enumerate,1]{leftmargin=2.4em,labelsep=0.5em}
\setlist[itemize,1]{leftmargin=2em,labelsep=0.5em}

% ============================================================================
%  页眉页脚：页眉双线 + 切口页码；页脚丛书行
% ============================================================================
\newcommand{\LoneSeriesMark}{高考数学之旅}
\newcommand{\LoneFootnoteLine}{}
\newcommand{\LonePageBadge}{\small\sffamily\thepage}

\newcommand{\LoneHeadRule}{{\color{InkMuted}%
  \hrule height 0.6pt width\headwidth
  \vspace{1.1pt}%
  \hrule height 0.25pt width\headwidth}}
\newcommand{\LoneFootRule}{{\color{InkMuted}%
  \hrule height 0.25pt width\textwidth
  \vspace{1.0pt}%
  \hrule height 0.6pt width\textwidth}}

\renewcommand{\chaptermark}[1]{\markboth{#1}{}}
\renewcommand{\sectionmark}[1]{\markright{#1}}

\fancyhf{}
% 页码在切口外侧（偶数页居左、奇数页居右），书名/章名贴订口
\fancyhead[EL]{\color{structurecolor}\LonePageBadge}
\fancyhead[OR]{\color{structurecolor}\LonePageBadge}
\fancyhead[ER]{\color{InkMuted}\footnotesize\sffamily\LoneSeriesMark}
\fancyhead[OL]{\color{InkMuted}\footnotesize\sffamily\nouppercase{\leftmark}}
\renewcommand{\headrule}{\LoneHeadRule}
\renewcommand{\headrulewidth}{0.6pt}
\fancyfoot[C]{\LoneFootRule\par\vspace{2.5pt}%
  {\footnotesize\kaishu\color{InkMuted}\LoneFootnoteLine}}
\pagestyle{fancy}
\fancypagestyle{plain}{%
  \fancyhf{}%
  \renewcommand{\headrule}{\LoneHeadRule}%
  \renewcommand{\headrulewidth}{0.6pt}%
  \fancyhead[EL]{\color{structurecolor}\LonePageBadge}%
  \fancyhead[OR]{\color{structurecolor}\LonePageBadge}%
  \fancyfoot[C]{\LoneFootRule\par\vspace{2.5pt}%
    {\footnotesize\kaishu\color{InkMuted}\LoneFootnoteLine}}%
}

% ============================================================================
%  标题格式：书名级安静形制，颜色走主题
% ============================================================================
% 章标题由「章扉页」承担展示，正文页上的 \chapter 只作紧凑承接。
\titleformat{\chapter}[hang]
  {\normalfont\bfseries\LARGE}
  {\color{structurecolor}\thechapter\enspace}
  {0.5em}
  {\color{InkBrown}}
\titlespacing*{\chapter}{0pt}{0pt plus 2pt}{1.2\baselineskip}

\titleformat{\section}[hang]
  {\normalfont\bfseries\large}
  {\color{structurecolor}\thesection\enspace}
  {0.5em}
  {\color{InkBrown}}
\titlespacing*{\section}{0pt}{18pt plus 3pt minus 2pt}{8pt plus 2pt minus 1pt}

\titleformat{\subsection}[hang]
  {\normalfont\bfseries\normalsize}
  {\color{structurecolor}\thesubsection\enspace}
  {0.5em}
  {\color{InkBrown}}
\titlespacing*{\subsection}{0pt}{13pt plus 2pt minus 2pt}{6pt plus 1pt minus 1pt}

\titleformat{\subsubsection}[hang]
  {\normalfont\bfseries\normalsize}
  {\color{structurecolor}\thesubsubsection\enspace}
  {0.5em}
  {\color{InkMuted}}
\titlespacing*{\subsubsection}{0pt}{10pt plus 2pt minus 1pt}{4pt plus 1pt minus 1pt}

% ============================================================================
%  书籍元数据
% ============================================================================
\newcommand{\LT@title}{}
\newcommand{\LT@subtitle}{}
\newcommand{\LT@author}{}
\newcommand{\LT@publisher}{}
\newcommand{\LT@series}{}
\newcommand{\LT@isbn}{}
\newcommand{\LT@edition}{}
\newcommand{\LT@coverline}{}
\newcommand{\LT@blurb}{}
\newcommand{\LT@watermark}{$\displaystyle\sum$}
\newcommand{\LT@volumeline}{}
\newcommand{\LT@volumelineEN}{}
\newcommand{\LT@shelflist}{}

\renewcommand{\title}[1]{\renewcommand{\LT@title}{#1}}
\def\subtitle#1{\renewcommand{\LT@subtitle}{#1}}   % book/ctexbook 未定义 \subtitle
\renewcommand{\author}[1]{\renewcommand{\LT@author}{#1}}
\newcommand{\publisher}[1]{\renewcommand{\LT@publisher}{#1}}
\newcommand{\seriesname}[1]{\renewcommand{\LT@series}{#1}}
\newcommand{\isbn}[1]{\renewcommand{\LT@isbn}{#1}}
\newcommand{\edition}[1]{\renewcommand{\LT@edition}{#1}}
\newcommand{\coverline}[1]{\renewcommand{\LT@coverline}{#1}}
\newcommand{\blurb}[1]{\renewcommand{\LT@blurb}{#1}}
\newcommand{\watermark}[1]{\renewcommand{\LT@watermark}{#1}}
\newcommand{\volumeline}[1]{\renewcommand{\LT@volumeline}{#1}}
\newcommand{\volumelineEN}[1]{\renewcommand{\LT@volumelineEN}{#1}}
\newcommand{\shelflist}[1]{\renewcommand{\LT@shelflist}{#1}}

% 兼容旧入口：elegantbook 时代留下的元数据宏在新类下只入目录/元数据
\newcommand{\version}[1]{\hypersetup{pdfsubject={#1}}}
\newcommand{\institute}[1]{\renewcommand{\LT@publisher}{#1}}
\newcommand{\extrainfo}[1]{\renewcommand{\LT@blurb}{#1}}
\newcommand{\mascot}[1]{}
\newcommand{\logo}[1]{}
\newcommand{\cover}[1]{}

% ============================================================================
%  边注 / 通栏（保留 tufte 阅读文化：短注进边栏）
% ============================================================================
\newcommand{\SeriesMarginText}{%
  \normalfont\footnotesize
  \raggedright
  \setlength{\parindent}{0pt}%
  \setlength{\parskip}{2pt}%
  \color{InkMuted}%
}
\newcommand{\sidenote}[2][0pt]{%
  \mparshift{#1}%
  \marginpar{\SeriesMarginText\strut #2\par}%
}
\NewDocumentEnvironment{marginfigure}{O{0pt} +b}{%
  \mparshift{#1}%
  \marginpar{\begin{minipage}{\marginparwidth}\centering\footnotesize #2\end{minipage}}%
}{}

\newlength{\SeriesFullwidthOverhang}
\AtBeginDocument{\setlength{\SeriesFullwidthOverhang}{\dimexpr\marginparwidth+\marginparsep\relax}}
\newenvironment{fullwidth}{%
  \par\noindent
  \begin{list}{}{%
    \setlength{\topsep}{0.5\baselineskip}%
    \setlength{\partopsep}{0pt}%
    \setlength{\listparindent}{\parindent}%
    \setlength{\itemindent}{0pt}%
    \setlength{\parsep}{0pt}%
    \ifodd\value{page}
      \setlength{\leftmargin}{0pt}%
      \setlength{\rightmargin}{-\SeriesFullwidthOverhang}%
    \else
      \setlength{\leftmargin}{-\SeriesFullwidthOverhang}%
      \setlength{\rightmargin}{0pt}%
    \fi
  }%
  \item\relax
}{\end{list}\par}

% ============================================================================
%  出版家具：环衬 / 扉页 / 版权页 / 封面 / 封底 / 卷隔页 / 章扉页
%  \ifLT@fullbleedpage：全出血页标志（\LT@FullPage 置位），
%  供 styles/background.tex 的 shipout 钩子跳过网格与三色角标。
% ============================================================================
\newif\ifLT@fullbleedpage
\input{styles/background.tex}
\input{styles/cover.tex}
\input{styles/contents.tex}
\input{styles/boxes.tex}

% ============================================================================
%  \maketitle：封面 → 扉页 → 版权页，进入前装（罗马页码）
%  期间 \pagestyle{empty}：\cleardoublepage 自动补出的空白反页不带页眉页脚。
% ============================================================================
\renewcommand{\maketitle}{%
  \hypersetup{pageanchor=false}%
  \pagenumbering{Alph}%
  \pagestyle{empty}%
  \FrontCover
  \cleardoublepage
  \HalfTitle
  \cleardoublepage
  \Imprint
  \cleardoublepage
  \pagestyle{fancy}%
  \ifLT@twoside
    \@twosidetrue
    \@mparswitchtrue
  \fi
}

% ============================================================================
%  \chapter 包装：正文编号章前插章扉页
%  章级 \label 依赖 \refstepcounter 写下的 \@currentlabel，该赋值是局部的，
%  因此恢复 \cleardoublepage 只能用 \let，不能把原 \chapter 包进 \begingroup。
% ============================================================================
\AtBeginDocument{%
  \let\LT@origchapter\chapter
  \RenewDocumentCommand{\chapter}{s o m}{%
    \IfBooleanTF{#1}{\LT@origchapter*{#3}}{%
      \let\LT@savedcdp\cleardoublepage
      \if@mainmatter
        \ChapterPlate{\the\numexpr\value{chapter}+1\relax}{#3}%
        \let\cleardoublepage\clearpage
      \fi
      \typeout{BT: mainmatter=\if@mainmatter true\else false\fi\space chapterbefore=\the\c@chapter\space orig=\meaning\LT@origchapter}%
      \IfNoValueTF{#2}{\LT@origchapter{#3}}{\LT@origchapter[#2]{#3}}%
      \typeout{BT: chapterafter=\the\c@chapter}%
      \let\cleardoublepage\LT@savedcdp
    }%
  }%
  \typeout{LONETRAILBOOK: chapter-plate-hook=ok}%
}

% 无答案模式开关（与 elegantbook 的 \ELEGANT@result{noanswer} 等效）。
% 必须在类加载时就定义：styles/boxes.tex 的 exsol 检查钩子注册于本块之前
% （styles 先 input），挂 AtBeginDocument 会晚于检查执行而失效。
\ifLT@noanswer
  \def\ELEGANT@result{noanswer}%
\fi

% 让类选项在日志里可见，便于排障
\ExplSyntaxOn
\AtBeginDocument{%
  \typeout{LONETRAILBOOK: theme=\g_lt_theme_tl\space trim=\g_lt_trim_tl\space bg=\g_lt_bg_tl}%
}
\ExplSyntaxOff

\makeatother
