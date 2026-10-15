# 开发指南

本文档介绍如何在本地搭建 NowenReader 开发环境，并提供完整的项目结构与技术栈说明。

## 前置条件

- **Go 1.23+** — 后端开发
- **Node.js 20+** — 前端开发
- **Flutter 3.2+ / Dart 3.2+** — 移动端开发（可选）

## 快速上手

```bash
# 安装 Go 依赖
go mod download

# 后端开发模式（直接运行，无需编译前端）
make dev

# 前端开发模式（另一个终端）
cd frontend && npm install && npm run dev

# 或：后端 + 指定前端构建产物目录
make dev-with-frontend
```

## 前端开发

Vite 开发服务器自动代理 API 请求到后端（`localhost:3000`）：

```bash
cd frontend
npm install
npm run dev      # 启动 http://localhost:5173
npm run build    # 类型检查 + 构建到 frontend/dist/
npm run preview  # 本地预览生产构建
```

## Flutter 客户端开发

```bash
cd flutter_app
flutter pub get
flutter run                          # 运行到模拟器/真机
flutter build apk --release          # 构建 Android APK
flutter build appbundle --release    # 构建 Google Play 上架用 AAB
```

> 详细说明参见 [`flutter_app/README.md`](../flutter_app/README.md)。

## Makefile 常用命令

| 命令 | 说明 |
|:---|:---|
| `make build` | 构建当前平台二进制 |
| `make build-full` | 构建前端 + 后端完整版本 |
| `make build-all` | 构建所有平台（Linux amd64/arm64 + 当前平台） |
| `make dev` | 开发模式运行 |
| `make test` | 运行所有测试（含 race 检测） |
| `make test-cover` | 测试 + 覆盖率报告 |
| `make docker` | 构建 Docker 镜像 |
| `make docker-multiarch` | 构建多平台镜像（amd64 + arm64） |
| `make frontend` | 构建前端到 web/dist/ |
| `make lint` | golangci-lint 检查 |
| `make clean` | 清理构建产物 |

<details>
<summary>查看全部 Makefile 目标</summary>

| 命令 | 说明 |
|:---|:---|
| `make build-linux` | 构建 Linux amd64 二进制 |
| `make build-arm64` | 构建 Linux arm64 二进制 |
| `make build-static` | 静态编译（CGO_ENABLED=0） |
| `make dev-with-frontend` | 开发模式（含前端目录） |
| `make test-short` | 运行短测试 |
| `make vet` | Go vet 检查 |
| `make fmt` | 代码格式化 |
| `make docker-push` | 推送 Docker 镜像 |
| `make docker-up` | docker compose up |
| `make docker-down` | docker compose down |
| `make docker-logs` | 查看容器日志 |
| `make migrate` | 构建迁移工具 |
| `make version` | 显示版本信息 |
| `make info` | 显示完整构建信息 |

</details>

## 项目结构

```
nowen-reader/
├── cmd/
│   ├── server/              # 主服务入口 — 启动 HTTP / DB / Scanner
│   └── migrate/             # 数据库迁移 CLI（Prisma → SQLite）
├── internal/
│   ├── archive/             # 压缩包 & 电子书解析（ZIP/RAR/7Z/PDF/EPUB/TXT/HTML）
│   ├── config/              # 配置管理（SiteConfig JSON + 环境变量）
│   ├── handler/             # HTTP API Handler（40+ 文件，按领域拆分）
│   ├── middleware/          # 中间件（Auth / CORS / Gzip / RateLimit / Security / Timeout）
│   ├── model/               # 数据模型（User / Comic / Tag / Category / ReadingSession / ComicGroup 等）
│   ├── service/             # 业务逻辑层（AI / Scanner / Metadata / Recommend / OPDS / Tag）
│   └── store/               # 数据库层（SQLite CRUD / Query / Batch / Stats / Migration）
├── web/
│   ├── embed.go             # go:embed 前端嵌入入口
│   └── dist/                # 前端构建产物（编译时填充）
├── frontend/                # Vite + React 19 + TypeScript 前端
│   └── src/
│       ├── app/             # 页面路由（首页 / comic / novel / reader / scraper / settings 等）
│       ├── components/      # UI 组件（60+，含阅读器、AI 面板、批量操作等）
│       ├── hooks/           # 自定义 Hooks
│       ├── api/ & lib/      # API 客户端 / i18n / Theme / Auth Context / PWA
│       └── types/           # 共享 TypeScript 类型
├── flutter_app/             # Flutter 原生客户端
│   └── lib/
│       ├── app/             # App / Router / Theme
│       ├── data/            # API 客户端、数据模型、Riverpod Provider
│       └── features/        # 功能模块（auth / home / detail / reader / search 等）
├── docker-compose.yml       # 一键部署（源码构建）
├── docker-compose.prod.yml  # 生产部署（Docker Hub 镜像）
├── docker-compose.nas.yml   # NAS 部署（群晖 / 威联通 / 绿联 / 铁威马）
├── Dockerfile               # 多阶段构建（Node 20 → Go 1.23 → Alpine 3.20，约 30 MB）
├── Makefile                 # 构建自动化（30+ 目标）
└── go.mod                   # Go 模块（Go 1.23）
```

## 技术栈

### 后端

| 组件 | 技术 |
|:---|:---|
| 语言 | Go 1.23 |
| Web 框架 | Gin v1.10 |
| 数据库 | SQLite（`modernc.org/sqlite`，纯 Go 实现，零 CGO） |
| 全文搜索 | SQLite FTS5 |
| 密码加密 | bcrypt（`golang.org/x/crypto`） |
| 压缩包解析 | `archive/zip` + `rardecode/v2` + 外部 CLI（`7z`） |
| PDF 渲染 | `mupdf-tools`（`mutool draw`） |
| 图片处理 | 纯 Go `image` 库 + `libwebp-tools`（`cwebp`） |
| 文件监听 | `fsnotify`（实时）+ 定时轮询（兜底） |
| 认证方式 | Cookie Session（bcrypt + UUID Token） |
| 前端嵌入 | `go:embed` |

### 前端

| 组件 | 技术 |
|:---|:---|
| 框架 | React 19 |
| 构建工具 | Vite 6 |
| 路由 | React Router v7（`react-router-dom`） |
| 样式 | Tailwind CSS v4（通过 `@tailwindcss/vite`） |
| 图标 | `lucide-react` |
| PDF | `pdfjs-dist` v5 |
| 语言 | TypeScript 5 |
| 国际化 | 自研 i18n（中文 / English） |
| 主题 | Context API（dark / light / system） |

### 移动端

| 组件 | 技术 |
|:---|:---|
| 框架 | Flutter 3.x（Dart SDK ≥ 3.2） |
| 状态管理 | Riverpod 2.x |
| 路由 | GoRouter 14.x |
| HTTP 客户端 | Dio 5.x + `dio_cookie_manager` |
| 图片 | `cached_network_image` + `photo_view` |
| 设计 | Material 3 |

### 部署 & 运维

| 组件 | 技术 |
|:---|:---|
| 容器化 | Docker 多阶段构建（Node 20 / Go 1.23 / Alpine 3.20，约 30 MB） |
| 多平台 | amd64 + arm64（Docker Buildx） |
| CI/CD | GitHub Actions（测试 / 构建 / Docker / Release / SSH 部署） |
| PWA | Service Worker + `manifest.json` |
| 进程管理 | `tini`（PID 1 信号处理） |
| 权限管理 | `su-exec`（root → `appuser` 降权） |

## CI/CD

项目使用 GitHub Actions 实现自动化：

- **`docker.yml`** — `main` 推送或手动触发，构建 `linux/amd64`、`linux/arm64` 镜像，同时推送 Docker Hub 和 GHCR，生成 `latest` 和提交 SHA 标签。
- **`flutter-ci.yml`** — Flutter 相关改动推送到 `main` 或提交 PR 时执行分析和测试；当前不生成 APK。
- **`dockerhub-description.yml`** — 镜像说明文档变更或手动触发时，将 `DOCKERHUB.md` 同步到 Docker Hub。
- **`build.yml` / `deploy.yml`** — 旧版手动发布工作流，目前仅配置 `workflow_dispatch`；发布任务仍有 `v*` Tag 条件限制。

### 镜像发布配置

Docker Hub 镜像名为 `silentzephyrus/nowen-reader`；GHCR 使用当前 GitHub 仓库所有者：`ghcr.io/<owner小写>/nowen-reader`。两处用户名分别配置。

在 Fork 仓库启用 Actions，然后进入 **Settings → Secrets and variables → Actions** 添加：

| Secret | 内容 |
|:---|:---|
| `DOCKERHUB_USERNAME` | 有权推送该镜像仓库的 Docker Hub 用户名 |
| `DOCKERHUB_TOKEN` | Docker Hub Personal Access Token，镜像推送需要 Read & Write 权限 |

`dockerhub-description.yml` 使用同一组凭据；该 README 同步 Action 要求 Token 具有 Read、Write、Delete 权限。

提交并推送 `main` 后自动构建，也可在 Actions 中选择 **Build and Push Multi-Arch Image (Docker Hub + GHCR)**，点击 **Run workflow**。GHCR 使用自动提供的 `GITHUB_TOKEN` 和工作流声明的 `packages: write` 权限。

镜像发布后，生产环境使用 `docker compose -f docker-compose.prod.yml pull` 和 `docker compose -f docker-compose.prod.yml up -d` 更新。

## 数据库迁移

SQLite 使用版本化的自动迁移系统，**启动时自动执行，无需手动操作**。迁移版本记录在 `_migrations` 表中。

## 开发流程（贡献代码）

```bash
# 1. Fork 并克隆
git clone https://github.com/your-username/nowen-reader.git
cd nowen-reader

# 2. 创建功能分支
git checkout -b feature/your-feature

# 3. 开发 & 测试
make dev       # 启动开发服务器
make test      # 运行测试

# 4. 提交 & 推送
git commit -m "feat: your feature description"
git push origin feature/your-feature

# 5. 创建 Pull Request
```

欢迎以任何形式参与贡献！

- 🐛 [提交 Bug](https://github.com/cropflre/nowen-reader/issues)
- 💡 [发起 Discussion](https://github.com/cropflre/nowen-reader/discussions)
- 🌐 国际化翻译
- 📖 完善文档
