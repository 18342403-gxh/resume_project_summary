#!/bin/bash
# ============================================================
# collect-git-data.sh
# 从一个或多个 Git 仓库中采集当前用户的贡献数据
# 用法：bash collect-git-data.sh <项目路径1> [项目路径2] ...
# 输出：结构化文本，可直接喂给 AI 进行总结
# ============================================================

set -euo pipefail

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查参数
if [ $# -eq 0 ]; then
    echo "用法：bash collect-git-data.sh <项目路径1> [项目路径2] ..."
    echo "示例：bash collect-git-data.sh ~/projects/app-a ~/projects/app-b"
    exit 1
fi

# 输出分隔线
separator() {
    echo ""
    echo "================================================================"
    echo ""
}

# 采集单个项目数据
collect_project() {
    local project_path="$1"
    local project_name
    project_name=$(basename "$project_path")

    # 验证路径是否为 git 仓库
    if [ ! -d "$project_path/.git" ]; then
        echo -e "${YELLOW}[跳过] $project_path 不是 Git 仓库${NC}" >&2
        return 1
    fi

    cd "$project_path"

    local author
    author=$(git config user.name 2>/dev/null || echo "unknown")

    echo -e "${GREEN}[采集] 项目：$project_name | 用户：$author${NC}" >&2

    echo "# 项目：$project_name"
    echo "# 路径：$project_path"
    echo "# 用户：$author"
    echo ""

    # 1. 项目时间范围
    echo "## 时间范围"
    local first_commit last_commit
    first_commit=$(git log --author="$author" --format="%ad" --date=short 2>/dev/null | tail -1 || echo "N/A")
    last_commit=$(git log --author="$author" --format="%ad" --date=short 2>/dev/null | head -1 || echo "N/A")
    echo "首次提交：$first_commit"
    echo "最近提交：$last_commit"
    echo ""

    # 2. Git remote（用于组织归属判断）
    echo "## Git Remote"
    git remote -v 2>/dev/null | head -2 || echo "无 remote"
    echo ""

    # 3. 提交总数
    echo "## 提交统计"
    local total_commits
    total_commits=$(git log --author="$author" --oneline 2>/dev/null | wc -l | tr -d ' ')
    echo "总提交数：$total_commits"
    echo ""

    # 4. 按模块统计（commit message 前缀）
    echo "## 模块贡献分布"
    git log --author="$author" --pretty=format:"%s" 2>/dev/null | grep -oE "^[a-z]+\([^)]*\)" | sort | uniq -c | sort -rn || echo "无标准前缀"
    echo ""

    # 5. 按月统计工作量
    echo "## 月度工作量"
    git log --author="$author" --pretty=format:"%ad" --date=format:"%Y-%m" 2>/dev/null | sort | uniq -c || echo "无数据"
    echo ""

    # 6. 高频修改文件 Top 30
    echo "## 高频修改文件 Top 30"
    git log --author="$author" --pretty=format:"" --name-only 2>/dev/null | grep -v "^$" | sort | uniq -c | sort -rn | head -30 || echo "无数据"
    echo ""

    # 7. 最近 50 条 commit message
    echo "## 最近 50 条提交"
    git log --author="$author" --pretty=format:"%h %ad %s" --date=short 2>/dev/null | head -50 || echo "无数据"
    echo ""

    # 8. package.json 依赖
    if [ -f "package.json" ]; then
        echo "## package.json 核心依赖"
        # 提取 dependencies 和 devDependencies 的 key
        python3 -c "
import json, sys
try:
    with open('package.json') as f:
        pkg = json.load(f)
    print('### dependencies')
    for k in sorted(pkg.get('dependencies', {}).keys()):
        print(f'  - {k}: {pkg[\"dependencies\"][k]}')
    print('### devDependencies')
    for k in sorted(pkg.get('devDependencies', {}).keys()):
        print(f'  - {k}: {pkg[\"devDependencies\"][k]}')
except Exception as e:
    print(f'解析失败: {e}')
" 2>/dev/null || echo "无法解析 package.json"
        echo ""
    fi

    # 9. 目录结构（src 下第一层）
    if [ -d "src" ]; then
        echo "## src/ 目录结构"
        find src -maxdepth 2 -type d 2>/dev/null | head -40 || echo "无 src 目录"
        echo ""
    fi
}

# 主流程
echo "========================================"
echo "  简历项目总结 - 数据采集工具"
echo "  采集时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo "  项目数量：$#"
echo "========================================"
echo ""

for path in "$@"; do
    # 展开 ~ 路径
    expanded_path="${path/#\~/$HOME}"

    if [ -d "$expanded_path" ]; then
        collect_project "$expanded_path"
        separator
    else
        echo -e "${YELLOW}[跳过] 路径不存在：$expanded_path${NC}" >&2
    fi
done

echo ""
echo "# ======== 采集完成 ========"
echo "# 共处理 $# 个项目路径"
echo "# 请将以上内容提供给 AI 进行总结"
