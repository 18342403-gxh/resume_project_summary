# 简历项目总结 Skill

基于工作区源码与 Git 记录，帮助用户总结个人贡献，生成可直接用于简历、述职、周报、晋升材料的项目描述。

## 核心能力

- **单项目总结**：扫描单个仓库，输出三段式（项目简介 + 技术栈 + 个人贡献）
- **多项目批量总结**：指定多个仓库路径，逐一采集并输出
- **智能合并**：自动检测关联项目（相同技术栈、共享模块、同一业务线），合并为一段完整的项目经历
- **项目亮点挖掘**：从项目全量信息中发现有价值的技术方案、架构设计、工程实践，不限于个人提交，帮你发现"可以写但不知道怎么写"的内容

## 项目结构

```
resume_project_summary/
├── README.md                        # 本文件
├── resume-project-summary.md        # Skill 主文件（完整执行流程）
├── scripts/
│   ├── collect-git-data.sh          # 数据采集脚本（支持多项目）
│   ├── collect-project-highlights.sh # 项目亮点采集脚本（全量扫描）
│   └── merge-projects.sh            # 关联性检测脚本
├── config/
│   ├── merge-rules.yaml             # 合并规则配置
│   ├── validation-rules.yaml        # 输出校验规则（生成后自动校验）
│   └── packaging-dictionary.yaml    # 互联网包装词库
└── examples/
    ├── single-project.md            # 单项目输出示例
    └── merged-projects.md           # 合并项目输出示例
```

## 使用方式

### 方式一：作为 Kiro Skill 使用

将 `resume-project-summary.md` 复制到目标工作区的 `.kiro/skills/` 或 `.kiro/steering/` 下，触发词：

- "总结项目" / "写简历" / "写项目经历" / "项目包装" / "我做了什么"
- "总结多个项目" / "合并项目经历"

### 方式二：脚本辅助采集

```bash
# 单项目采集
bash scripts/collect-git-data.sh /path/to/project

# 多项目采集
bash scripts/collect-git-data.sh /path/to/project1 /path/to/project2 /path/to/project3

# 关联性检测
bash scripts/merge-projects.sh /path/to/project1 /path/to/project2

# 项目亮点采集（全量扫描，不限个人提交）
bash scripts/collect-project-highlights.sh /path/to/project
```

脚本会输出结构化的 JSON 数据，可直接喂给 AI 进行总结。

## 合并逻辑

当多个项目满足以下任一条件时，建议合并为一段经历：

1. **技术栈重叠 ≥ 60%**（核心依赖相同）
2. **同一业务域**（commit message 中出现相同业务关键词）
3. **共享代码模块**（存在 git submodule 或 npm workspace 引用关系）
4. **时间线连续**（项目时间段重叠或首尾相接）
5. **同一团队/组织**（git remote 指向同一 org）

合并后以"主项目"为骨架，将子项目贡献归入对应模块。

## 触发词

| 场景 | 触发词 |
|------|--------|
| 单项目 | 总结项目、写简历、写项目经历、项目包装、我做了什么 |
| 多项目 | 总结多个项目、批量总结、合并项目经历 |
| 亮点挖掘 | 项目亮点、有什么可以写的、挖掘亮点 |
| 调整 | 再包装一下、黑话不够、太具体了、合并一下 |
