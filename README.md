<div align="center">

# 📝 Resume Project Summary

**让 AI 帮你写出比你自己写得还好的项目经历**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/18342403-gxh/resume_project_summary/pulls)

一套开箱即用的 AI Skill，基于 Git 记录和源码自动生成简历级项目描述。
<br/>
告别"不知道写什么"和"写出来像流水账"。

</div>

---

## ✨ 它能做什么

| 能力 | 说明 |
|------|------|
| 🎯 **三段式输出** | 项目简介 + 技术栈 + 个人贡献，格式统一、措辞专业 |
| 🔍 **深度代码扫描** | 不只看 commit message，还会扫描组件复用度、业务流程复杂度、工具函数抽象度 |
| 🧠 **智能多项目合并** | 自动检测关联项目，合并为一段更有分量的经历 |
| 💎 **可选贡献挖掘** | 从项目全局发现你"可以写但不知道怎么写"的内容 |
| ✅ **自校验机制** | 输出后自动校验 18 条规则，不合格自动修正 |
| 🤖 **弱模型友好** | 填空式模板设计，即使模型能力一般也能产出合格结果 |

---

## 🚀 快速开始

### 方式一：作为 Kiro Skill 使用

将 `resume-project-summary.md` 复制到目标项目的 `.kiro/skills/` 或 `.kiro/steering/` 目录下。

然后在对话中说：

```
帮我总结项目
```

或者指定多个项目：

```
帮我总结这几个项目并合并：~/work/app-a ~/work/app-b
```

### 方式二：脚本先行，数据喂给任意 AI

```bash
# 采集单个项目
bash scripts/collect-git-data.sh ~/work/my-project

# 采集多个项目
bash scripts/collect-git-data.sh ~/work/project-a ~/work/project-b

# 检测项目关联性
bash scripts/merge-projects.sh ~/work/project-a ~/work/project-b

# 扫描项目亮点（含代码级分析）
bash scripts/collect-project-highlights.sh ~/work/my-project
```

将脚本输出复制给任意 AI（ChatGPT / Claude / 通义 / Kimi），配合 `resume-project-summary.md` 中的模板即可生成结果。

---

## 📂 项目结构

```
.
├── resume-project-summary.md          # 核心 Skill 文件（AI 指令 + 模板）
├── scripts/
│   ├── collect-git-data.sh            # 个人贡献数据采集
│   ├── collect-project-highlights.sh  # 项目亮点全量扫描（含代码级）
│   └── merge-projects.sh             # 多项目关联性检测
├── config/
│   ├── validation-rules.yaml          # 18 条输出校验规则
│   ├── merge-rules.yaml              # 合并评分规则
│   └── packaging-dictionary.yaml     # 互联网包装词库
└── examples/
    ├── single-project.md             # 单项目输出示例
    └── merged-projects.md            # 合并项目输出示例
```

---

## 🎯 输出示例

<details>
<summary><b>点击展开完整输出示例</b></summary>

### 项目简介

面向新能源车企的智慧出行 B 端 SaaS 平台，基于一码多端架构提供车主全生命周期服务能力，涵盖车辆绑定、充电管理、远程控车等核心场景，支持多租户配置化运营，实现业务能力的标准化输出与规模化复制。

### 项目技术

- **跨端架构**：Taro 3 + React，一套代码产出小程序/H5/App 内嵌，解决多端一致性问题
- **状态管理**：Zustand + React Query，轻量方案配合服务端缓存，降低全局复杂度
- **UI 体系**：基于 NutUI 二次封装业务组件库，统一设计语言
- **工程化**：pnpm Monorepo + Turborepo 编排 + ESLint/Prettier 统一规范

### 个人贡献

1. **车辆服务模块**：独立主导车辆绑定、远程控车等核心功能，覆盖 5 个页面与 12 个交互流程，配合后端完成全链路联调。
2. **充电业务模块**：端到端负责充电桩地图、扫码充电等功能，接入高德地图 SDK 并实现聚合渲染。
3. **JSBridge 桥接层**：参与桥接 SDK 能力扩展，新增 8 个原生接口，配合双端完成适配。
4. **组件库与规范**：配合团队沉淀 6 个业务组件，参与 ESLint 规则定制与 CR 规范落地。

---

### 可选贡献

1. **地图选点组件**：封装通用 MapPicker，集成双引擎切换/POI 搜索/逆地理编码，被 8 个页面复用。 `#组件`
2. **支付全链路**：打通微信/支付宝支付流程，封装 usePayment hook 管理支付状态机与超时重试。 `#业务流程`
3. **请求中间件体系**：设计统一请求层，封装 Token 刷新/请求去重/接口缓存/错误码处理。 `#工具封装`
4. **多租户配置架构**：参与多租户隔离方案，动态下发主题包与功能开关，支撑 10+ 车企运营。 `#架构`

</details>

---

## 🔧 设计理念

### 为什么要做填空式模板？

不同 AI 模型能力差异大。GPT-4 级别可以自由发挥写出好结果，但 GPT-3.5 或更弱的模型经常：
- 输出格式混乱
- 编造不存在的技术栈
- 写出过于具体的实现细节
- 忘记某些必要板块

**填空式模板**让模型只需要做"选择和填入"，而非"从零创作"，大幅降低了对模型能力的要求。

### Token 优化策略

- 指令压缩：用条目式代替散文式说明，减少约 40% 冗余
- 配置外置：校验规则、合并规则、词库独立为 yaml，Skill 主文件只引用
- 脚本先采：数据采集用 bash 完成，不占用 AI token
- 按需加载：单项目时不加载合并相关逻辑

---

## 📋 触发词速查

| 场景 | 说什么 |
|------|--------|
| 总结当前项目 | "总结项目" / "写简历" / "我做了什么" |
| 总结多个项目 | "总结这几个项目" + 路径 |
| 合并项目 | "合并项目经历" |
| 挖掘亮点 | "有什么可以写的" / "项目亮点" |
| 调整输出 | "黑话不够" / "太具体了" / "合并一下" |

---

## 🤝 Contributing

欢迎 PR。如果你有更好的包装词、校验规则、或适配其他语言（Java/Go/Python）项目的需求，直接提 issue 或 PR。

---

## 📄 License

MIT
