#!/bin/bash
# ============================================================
# merge-projects.sh
# 检测多个项目之间的关联性，输出合并建议
# 用法：bash merge-projects.sh <项目路径1> <项目路径2> [项目路径3] ...
# 输出：关联性评分与合并建议
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ $# -lt 2 ]; then
    echo "用法：bash merge-projects.sh <项目路径1> <项目路径2> [项目路径3] ..."
    echo "至少需要 2 个项目路径"
    exit 1
fi

# 提取项目信息的辅助函数
get_dependencies() {
    local path="$1"
    if [ -f "$path/package.json" ]; then
        python3 -c "
import json
with open('$path/package.json') as f:
    pkg = json.load(f)
deps = list(pkg.get('dependencies', {}).keys())
print('\n'.join(deps))
" 2>/dev/null || echo ""
    fi
}

get_org() {
    local path="$1"
    cd "$path"
    git remote get-url origin 2>/dev/null | grep -oE '(github\.com|gitlab\.com|gitee\.com)[:/][^/]+' | head -1 || echo "unknown"
}

get_time_range() {
    local path="$1"
    local author
    cd "$path"
    author=$(git config user.name 2>/dev/null || echo "")
    if [ -n "$author" ]; then
        local first last
        first=$(git log --author="$author" --format="%ad" --date=format:"%Y%m" 2>/dev/null | tail -1 || echo "000000")
        last=$(git log --author="$author" --format="%ad" --date=format:"%Y%m" 2>/dev/null | head -1 || echo "000000")
        echo "$first $last"
    else
        echo "000000 000000"
    fi
}

get_business_keywords() {
    local path="$1"
    local author
    cd "$path"
    author=$(git config user.name 2>/dev/null || echo "")
    # 从 commit message 中提取括号内的模块名作为业务关键词
    git log --author="$author" --pretty=format:"%s" 2>/dev/null | grep -oE "\([^)]+\)" | tr -d '()' | sort -u || echo ""
}

echo "========================================"
echo "  项目关联性检测工具"
echo "  检测时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo "  项目数量：$#"
echo "========================================"
echo ""

# 收集每个项目的基础信息
declare -a project_names=()
declare -a project_paths=()

for path in "$@"; do
    expanded_path="${path/#\~/$HOME}"
    if [ -d "$expanded_path/.git" ]; then
        project_names+=("$(basename "$expanded_path")")
        project_paths+=("$expanded_path")
    else
        echo -e "${YELLOW}[跳过] $expanded_path 不是 Git 仓库${NC}"
    fi
done

project_count=${#project_paths[@]}

if [ "$project_count" -lt 2 ]; then
    echo -e "${RED}[错误] 有效 Git 仓库不足 2 个，无法进行关联性检测${NC}"
    exit 1
fi

echo "## 检测到的有效项目"
echo ""
for i in "${!project_names[@]}"; do
    echo "  $((i+1)). ${project_names[$i]} -> ${project_paths[$i]}"
done
echo ""

# 两两对比
echo "## 关联性分析"
echo ""

for ((i=0; i<project_count-1; i++)); do
    for ((j=i+1; j<project_count; j++)); do
        echo "---"
        echo "### ${project_names[$i]} <-> ${project_names[$j]}"
        echo ""

        path_a="${project_paths[$i]}"
        path_b="${project_paths[$j]}"

        score=0

        # 1. 技术栈重叠（权重 30）
        deps_a=$(get_dependencies "$path_a")
        deps_b=$(get_dependencies "$path_b")

        if [ -n "$deps_a" ] && [ -n "$deps_b" ]; then
            overlap=$(comm -12 <(echo "$deps_a" | sort) <(echo "$deps_b" | sort) | wc -l | tr -d ' ')
            total=$(comm <(echo "$deps_a" | sort) <(echo "$deps_b" | sort) | wc -l | tr -d ' ')
            if [ "$total" -gt 0 ]; then
                tech_score=$((overlap * 30 / total))
            else
                tech_score=0
            fi
        else
            tech_score=0
        fi
        score=$((score + tech_score))
        echo "  技术栈重叠：${tech_score}/30"

        # 2. 业务域关联（权重 25）
        keywords_a=$(get_business_keywords "$path_a")
        keywords_b=$(get_business_keywords "$path_b")

        if [ -n "$keywords_a" ] && [ -n "$keywords_b" ]; then
            kw_overlap=$(comm -12 <(echo "$keywords_a" | sort) <(echo "$keywords_b" | sort) | wc -l | tr -d ' ')
            if [ "$kw_overlap" -gt 3 ]; then
                biz_score=25
            elif [ "$kw_overlap" -gt 1 ]; then
                biz_score=15
            elif [ "$kw_overlap" -gt 0 ]; then
                biz_score=8
            else
                biz_score=0
            fi
        else
            biz_score=0
        fi
        score=$((score + biz_score))
        echo "  业务域关联：${biz_score}/25"

        # 3. 组织归属（权重 10）
        org_a=$(get_org "$path_a")
        org_b=$(get_org "$path_b")

        if [ "$org_a" = "$org_b" ] && [ "$org_a" != "unknown" ]; then
            org_score=10
        else
            org_score=0
        fi
        score=$((score + org_score))
        echo "  组织归属：${org_score}/10（$org_a vs $org_b）"

        # 4. 时间线连续性（权重 15）
        range_a=$(get_time_range "$path_a")
        range_b=$(get_time_range "$path_b")
        # 简单判断：时间范围是否有交叉
        start_a=$(echo "$range_a" | awk '{print $1}')
        end_a=$(echo "$range_a" | awk '{print $2}')
        start_b=$(echo "$range_b" | awk '{print $1}')
        end_b=$(echo "$range_b" | awk '{print $2}')

        if [ "$start_a" != "000000" ] && [ "$start_b" != "000000" ]; then
            # 检查是否有时间重叠
            if [ "$start_a" -le "$end_b" ] && [ "$start_b" -le "$end_a" ]; then
                time_score=15
            else
                # 检查间隔是否 ≤ 2 月
                if [ "$end_a" -lt "$start_b" ]; then
                    gap=$((start_b - end_a))
                else
                    gap=$((start_a - end_b))
                fi
                if [ "$gap" -le 2 ]; then
                    time_score=10
                else
                    time_score=0
                fi
            fi
        else
            time_score=0
        fi
        score=$((score + time_score))
        echo "  时间线连续：${time_score}/15（A: $start_a~$end_a, B: $start_b~$end_b）"

        # 5. 代码引用关系（权重 20）—— 简化检测
        ref_score=0
        # 检查是否存在 workspace 引用
        if [ -f "$path_a/package.json" ] && [ -f "$path_b/package.json" ]; then
            name_b=$(python3 -c "import json; print(json.load(open('$path_b/package.json')).get('name',''))" 2>/dev/null || echo "")
            if [ -n "$name_b" ] && grep -q "$name_b" "$path_a/package.json" 2>/dev/null; then
                ref_score=20
            fi
        fi
        score=$((score + ref_score))
        echo "  代码引用：${ref_score}/20"

        echo ""
        echo "  **总分：${score}/100**"

        # 判断建议
        if [ "$score" -ge 60 ]; then
            echo -e "  ${GREEN}✅ 强烈建议合并为一段项目经历${NC}"
        elif [ "$score" -ge 40 ]; then
            echo -e "  ${YELLOW}⚠️  建议合并，但请确认业务关联性${NC}"
        else
            echo -e "  ${RED}❌ 不建议合并，独立描述更佳${NC}"
        fi
        echo ""
    done
done

echo ""
echo "# ======== 检测完成 ========"
