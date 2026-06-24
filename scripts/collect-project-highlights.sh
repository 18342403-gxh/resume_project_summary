#!/bin/bash
# ============================================================
# collect-project-highlights.sh
# 从项目全量信息中采集亮点数据（不限 author）
# 用法：bash collect-project-highlights.sh <项目路径>
# 输出：结构化数据，用于 AI 识别项目亮点
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ $# -eq 0 ]; then
    echo "用法：bash collect-project-highlights.sh <项目路径>"
    exit 1
fi

project_path="${1/#\~/$HOME}"

if [ ! -d "$project_path/.git" ]; then
    echo -e "${YELLOW}[错误] $project_path 不是 Git 仓库${NC}"
    exit 1
fi

cd "$project_path"
project_name=$(basename "$project_path")
author=$(git config user.name 2>/dev/null || echo "unknown")

echo "========================================"
echo "  项目亮点采集工具"
echo "  项目：$project_name"
echo "  路径：$project_path"
echo "  用户：$author"
echo "  采集时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
echo ""

# ======== 1. 项目全貌 ========
echo "## 1. 项目全貌"
echo ""

echo "### 贡献者列表"
git shortlog -sn --no-merges 2>/dev/null | head -20
echo ""

echo "### 全量模块分布（所有人的提交）"
git log --pretty=format:"%s" 2>/dev/null | grep -oE "^[a-z]+\([^)]*\)" | sort | uniq -c | sort -rn | head -30 || echo "无标准前缀"
echo ""

echo "### 项目时间跨度"
echo "首次提交：$(git log --format='%ad' --date=short | tail -1)"
echo "最近提交：$(git log --format='%ad' --date=short | head -1)"
echo "总提交数：$(git log --oneline | wc -l | tr -d ' ')"
echo ""

# ======== 2. 架构特征 ========
echo "## 2. 架构特征检测"
echo ""

echo "### 项目根目录结构"
ls -1 2>/dev/null | head -30
echo ""

echo "### src/ 顶层目录"
if [ -d "src" ]; then
    ls -1 src/ 2>/dev/null | head -20
else
    echo "无 src 目录"
fi
echo ""

# Monorepo 检测
echo "### Monorepo 检测"
if [ -d "packages" ]; then
    echo "✅ 存在 packages/ 目录（Monorepo）"
    ls packages/ 2>/dev/null
elif [ -f "pnpm-workspace.yaml" ]; then
    echo "✅ 存在 pnpm-workspace.yaml"
    cat pnpm-workspace.yaml 2>/dev/null
elif grep -q "workspaces" package.json 2>/dev/null; then
    echo "✅ package.json 中配置了 workspaces"
    python3 -c "import json; pkg=json.load(open('package.json')); print(pkg.get('workspaces','无'))" 2>/dev/null
else
    echo "❌ 未检测到 Monorepo 结构"
fi
echo ""

# 微前端检测
echo "### 微前端检测"
if grep -rlq "qiankun\|micro-app\|module-federation\|single-spa" . --include="*.json" --include="*.js" --include="*.ts" 2>/dev/null; then
    echo "✅ 检测到微前端相关依赖"
    grep -rl "qiankun\|micro-app\|module-federation\|single-spa" . --include="*.json" 2>/dev/null | head -5
else
    echo "❌ 未检测到微前端"
fi
echo ""

# SSR 检测
echo "### SSR/SSG 检测"
if grep -q "next\|nuxt\|gatsby\|astro" package.json 2>/dev/null; then
    echo "✅ 检测到 SSR/SSG 框架"
    grep -oE "\"(next|nuxt|gatsby|astro)\"" package.json 2>/dev/null
else
    echo "❌ 未检测到 SSR/SSG"
fi
echo ""

# ======== 3. 技术栈深度 ========
echo "## 3. 技术栈与依赖"
echo ""

if [ -f "package.json" ]; then
    echo "### dependencies"
    python3 -c "
import json
with open('package.json') as f:
    pkg = json.load(f)
deps = pkg.get('dependencies', {})
for k in sorted(deps.keys()):
    print(f'  {k}: {deps[k]}')
" 2>/dev/null || echo "解析失败"
    echo ""

    echo "### devDependencies"
    python3 -c "
import json
with open('package.json') as f:
    pkg = json.load(f)
deps = pkg.get('devDependencies', {})
for k in sorted(deps.keys()):
    print(f'  {k}: {deps[k]}')
" 2>/dev/null || echo "解析失败"
    echo ""
fi

# ======== 4. 工程化特征 ========
echo "## 4. 工程化特征"
echo ""

echo "### CI/CD"
if [ -d ".github/workflows" ]; then
    echo "✅ GitHub Actions"
    ls .github/workflows/ 2>/dev/null
elif [ -f ".gitlab-ci.yml" ]; then
    echo "✅ GitLab CI"
    head -20 .gitlab-ci.yml 2>/dev/null
else
    echo "❌ 未检测到 CI/CD 配置"
fi
echo ""

echo "### Docker"
if [ -f "Dockerfile" ]; then
    echo "✅ 存在 Dockerfile"
    head -10 Dockerfile 2>/dev/null
else
    echo "❌ 无 Dockerfile"
fi
echo ""

echo "### 测试"
test_count=$(find . -name "*.test.*" -o -name "*.spec.*" -o -name "__tests__" 2>/dev/null | grep -v node_modules | wc -l | tr -d ' ')
echo "测试文件数：$test_count"
if [ -f "jest.config.js" ] || [ -f "jest.config.ts" ]; then
    echo "测试框架：Jest"
elif [ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ]; then
    echo "测试框架：Vitest"
fi
echo ""

echo "### Lint & 格式化"
[ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f "eslint.config.js" ] && echo "✅ ESLint"
[ -f ".prettierrc" ] || [ -f ".prettierrc.js" ] && echo "✅ Prettier"
[ -f ".stylelintrc" ] || [ -f ".stylelintrc.js" ] && echo "✅ Stylelint"
[ -f "commitlint.config.js" ] && echo "✅ Commitlint"
[ -f ".husky" ] || [ -d ".husky" ] && echo "✅ Husky (Git Hooks)"
echo ""

# ======== 5. 性能相关特征 ========
echo "## 5. 性能相关"
echo ""

echo "### 构建工具"
if grep -q "\"vite\"" package.json 2>/dev/null; then
    echo "构建工具：Vite"
elif grep -q "\"webpack\"" package.json 2>/dev/null; then
    echo "构建工具：Webpack"
elif grep -q "\"turbopack\|\"rspack\"" package.json 2>/dev/null; then
    echo "构建工具：Turbopack/Rspack"
fi
echo ""

echo "### 性能优化信号"
# 检测懒加载
lazy_count=$(grep -r "lazy\|React.lazy\|import(" src/ --include="*.ts" --include="*.tsx" --include="*.js" 2>/dev/null | grep -v node_modules | wc -l | tr -d ' ')
echo "懒加载使用次数：$lazy_count"

# 检测虚拟滚动
if grep -rq "virtual-list\|react-virtualized\|react-window\|vue-virtual-scroller" package.json 2>/dev/null; then
    echo "✅ 使用虚拟滚动"
fi

# 检测 Web Worker
worker_count=$(find . -name "*.worker.*" 2>/dev/null | grep -v node_modules | wc -l | tr -d ' ')
echo "Web Worker 文件数：$worker_count"

# 检测缓存策略
if grep -rq "service-worker\|workbox\|sw.js" . --include="*.json" --include="*.js" --include="*.ts" 2>/dev/null | grep -v node_modules; then
    echo "✅ 使用 Service Worker"
fi
echo ""

# ======== 6. 安全与监控 ========
echo "## 6. 安全与监控"
echo ""

if grep -q "sentry\|bugsnag\|fundebug\|arms\|aegis" package.json 2>/dev/null; then
    echo "✅ 错误监控"
    grep -oE "\"(sentry|@sentry|bugsnag|fundebug|arms|aegis)[^\"]*\"" package.json 2>/dev/null
fi

if grep -rq "埋点\|track\|analytics\|sensors\|growing" . --include="*.json" --include="*.ts" --include="*.js" 2>/dev/null | head -3; then
    echo "✅ 数据埋点"
fi
echo ""

# ======== 7. 代码级亮点扫描 ========
echo "## 7. 代码级亮点"
echo ""

echo "### 高复用组件 Top 20（被 import 次数最多）"
if [ -d "src" ]; then
    grep -r "from.*components/" src/ --include="*.ts" --include="*.tsx" --include="*.vue" --include="*.js" 2>/dev/null | grep -oE "components/[^'\"]*" | sort | uniq -c | sort -rn | head -20 || echo "无数据"
fi
echo ""

echo "### 复杂组件 Top 20（代码行数最多）"
if [ -d "src/components" ]; then
    find src/components -name "*.tsx" -o -name "*.vue" -o -name "*.jsx" 2>/dev/null | xargs wc -l 2>/dev/null | sort -rn | head -20 || echo "无数据"
fi
echo ""

echo "### 通用 Hooks Top 15（被引用次数）"
if [ -d "src" ]; then
    grep -r "from.*hooks/" src/ --include="*.ts" --include="*.tsx" 2>/dev/null | grep -oE "hooks/[^'\"]*" | sort | uniq -c | sort -rn | head -15 || echo "无数据"
fi
echo ""

echo "### 工具函数 Top 15（被引用次数）"
if [ -d "src" ]; then
    grep -r "from.*utils/" src/ --include="*.ts" --include="*.tsx" --include="*.js" 2>/dev/null | grep -oE "utils/[^'\"]*" | sort | uniq -c | sort -rn | head -15 || echo "无数据"
fi
echo ""

echo "### 核心业务页面 Top 20（代码量最大 = 通常最复杂）"
if [ -d "src/pages" ] || [ -d "src/views" ]; then
    find src/pages src/views -name "*.tsx" -o -name "*.vue" -o -name "*.jsx" 2>/dev/null | xargs wc -l 2>/dev/null | sort -rn | head -20 || echo "无数据"
fi
echo ""

echo "### 请求层/服务层"
find src -path "*/api/*" -o -path "*/services/*" -o -path "*/request*" 2>/dev/null | grep -v node_modules | head -15 || echo "无数据"
echo ""

echo "### 状态管理模块"
find src -path "*/store/*" -o -path "*/stores/*" -o -path "*/models/*" 2>/dev/null | grep -v node_modules | head -15 || echo "无数据"
echo ""

echo "### 中间件/拦截器"
find src -path "*/middleware*" -o -path "*/interceptor*" 2>/dev/null | grep -v node_modules | head -10 || echo "无数据"
echo ""

# ======== 8. 用户个人在此项目的参与度 ========
echo "## 8. 用户参与度对照"
echo ""
echo "### 用户提交数 vs 总提交数"
total=$(git log --oneline 2>/dev/null | wc -l | tr -d ' ')
user_total=$(git log --author="$author" --oneline 2>/dev/null | wc -l | tr -d ' ')
echo "总提交：$total | 用户提交：$user_total | 占比：$(echo "scale=1; $user_total * 100 / $total" | bc 2>/dev/null || echo "N/A")%"
echo ""

echo "### 用户高频修改文件 Top 20"
git log --author="$author" --pretty=format:"" --name-only 2>/dev/null | grep -v "^$" | sort | uniq -c | sort -rn | head -20
echo ""

echo ""
echo "# ======== 采集完成 ========"
echo "# 请将以上数据提供给 AI 进行亮点识别"
