<div align="center">

# ymcloud · 部署指南

**准备好 Docker，让自己的 OJ 跑起来。**

![Docker Compose](https://img.shields.io/badge/Docker-Compose_v2-2496ED?logo=docker&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Linux_amd64-334155)
![Version](https://img.shields.io/badge/ymcloud-4.0.0-0F766E)

[项目源码](https://gitee.com/yemiaoo/ymcloud) · [部署仓库](https://gitee.com/yemiaoo/ymoj-deploy) · [开始部署](#开始部署) · [常见问题](#常见问题)

</div>

一套配置启动前端、Web、MySQL、Redis、RabbitMQ、Worker 和 go-judge。镜像已构建，数据库会在首次启动时初始化，无需安装 Java、Maven、Node 或 Python。

## 已有 Docker？从这里开始

以下命令适用于 **Git + Docker 已就绪的 Linux / macOS 终端或 Windows PowerShell**。服务器须满足下方环境要求；Windows 请先启动 Docker Desktop 并使用 Linux 容器。

```shell
git clone https://gitee.com/yemiaoo/ymoj-deploy.git
cd ymoj-deploy
cp .env .env.local
```

**先编辑 `.env.local`**：本机体验设置 `HTTP_BIND=127.0.0.1`；公网部署先替换密码和密钥，具体见[修改配置](#2-修改配置)。然后启动：

```shell
docker compose --env-file .env.local config --quiet
docker compose --env-file .env.local up -d
docker compose --env-file .env.local ps -a
```

默认访问 **http://localhost** 或 **http://服务器IP**。后台地址加 `/admin/login`，全新安装初始账号为 `admin`，密码为 `Ymcloud@123`。首次登录后修改管理员密码和邮箱。

> 默认密码与服务密钥是公开测试值。仅用于本机体验；正式部署前请完成下方配置。`.env.local` 是本机配置文件，本仓库不提供 `.gitignore`，请勿将它提交或上传。

## 开始部署

### 1. 准备运行环境

| 项目 | 要求 |
| --- | --- |
| 生产服务器 | Linux、x86_64 / amd64、cgroup v2 |
| 基础容量 | 至少 2 核 4GB；默认单 Worker、判题并发 1 |
| 容器工具 | Docker Engine + Docker Compose v2.20 或更新版本 |
| 本机体验 | Windows Docker Desktop（Linux 容器）；不替代 Linux 生产验收 |
| 网络 | 可以拉取腾讯云或 Docker Hub 镜像；对外访问时放行网站端口 |

尚未安装 Docker，请按系统选择[官方安装指南](https://docs.docker.com/engine/install/)，Windows 用户可使用 [Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/)。安装后在终端确认：

```shell
docker version
docker compose version
docker info --format '{{.OSType}} / {{.Architecture}} / cgroup {{.CgroupVersion}}'
```

`docker version` 应同时显示 Client 和 Server；生产服务器的最后一项应显示 Linux、x86_64（或 amd64）与 cgroup 2。当前发布镜像为 amd64，不将 ARM 模拟运行作为支持的生产环境。

取得部署文件：

```shell
git clone https://gitee.com/yemiaoo/ymoj-deploy.git
cd ymoj-deploy
```

没有 Git 时，可在[部署仓库页面](https://gitee.com/yemiaoo/ymoj-deploy)下载 ZIP 并解压，然后在解压目录打开终端。独立部署仓库应包含：

```text
ymoj-deploy/
├── .env                 公开默认配置
├── compose.yaml         服务与镜像配置
├── initdb/ymcloud.sql    首次安装的建表与初始化数据
├── README.md            本文
├── DEVELOPMENT.md       源码开发与维护
└── LICENSE
```

源码仓库中的 `deploy/` 也可使用，但其 Compose 读取相邻的 `../sql/ymcloud.sql`，需保留源码目录结构。独立仓库已携带 `initdb/ymcloud.sql`，无需下载完整源码。

### 2. 修改配置

第一次部署先复制配置，后续启动一直使用同一份 `.env.local`，不要重复覆盖它：

```shell
cp .env .env.local
```

Linux 可执行 `nano .env.local` 或使用自己熟悉的编辑器；Windows 可执行 `notepad .env.local`。保存为 UTF-8。

| 配置项 | 如何填写 |
| --- | --- |
| `HTTP_PORT` | 网站端口，默认 `80`；被占用时改为 `8080` 等空闲端口 |
| `HTTP_BIND` | 服务器对外访问用 `0.0.0.0`；仅本机体验用 `127.0.0.1` |
| `MYSQL_ROOT_PASSWORD`、`MYSQL_PASSWORD`、`REDIS_PASSWORD`、`RABBITMQ_PASSWORD` | 正式部署时各自替换为至少 16 位、互不相同的随机密码 |
| `TOKEN_SECRET` | 登录签名密钥，替换为至少 64 位随机字符串 |
| `WORKER_TOKEN`、`GO_JUDGE_TOKEN` | 两个独立服务密钥，分别替换为至少 32 位随机字符串 |
| `IMAGE_REPOSITORY` | 默认腾讯云；下载失败时改为 `docker.io/yemiao1/ymoj` |
| `MAIL_FROM`、`MAIL_PASS` | 可选；使用邮箱找回密码时配置 QQ 邮箱与 SMTP 授权码 |

可以用密码管理器生成随机值，建议仅使用大小写字母与数字。其他参数先保持默认，镜像版本已写入 Compose，无需填写容器 IP、数据库连接地址或服务内部端口。

`COMPOSE_PROJECT_NAME` 决定数据卷名称，安装后不要随意修改。判题容量参数需要配套调整，2 核 4GB 的初次部署先保持默认并发 1。

### 3. 启动并检查

在包含 `compose.yaml` 的目录执行：

```shell
docker compose --env-file .env.local config --quiet
docker compose --env-file .env.local up -d
docker compose --env-file .env.local ps -a
```

首次启动会下载缺少的镜像、初始化空数据库并等待服务健康，可能需要几分钟。正常结果：

- `preflight` 是一次性配置检查，状态为 `Exited (0)`。
- 其余 7 个服务保持运行，并最终显示 `healthy`。

想看启动进度：

```shell
docker compose --env-file .env.local logs -f --tail 100 web worker
```

按 `Ctrl+C` 只退出日志查看，后台服务继续运行。[Docker Compose 命令说明](https://docs.docker.com/reference/cli/docker/compose/up/)介绍了后台启动与服务重建行为。

### 4. 登录并完成首次判题

1. 本机访问 `http://localhost`；远程访问 `http://服务器IP`。端口为 8080 时，在地址后加 `:8080`。
2. 进入 `/admin/login`，用 `admin` / `Ymcloud@123` 登录，并修改密码和邮箱。
3. 创建题目，上传配对的 `.in` / `.out` 测试数据。
4. 提交一份正确代码，确认能收到评测结果，再开始添加题库或组织比赛。

云服务器需在安全组和防火墙放行所选网站端口。只有网站端口对外映射，MySQL、Redis、RabbitMQ 和沙箱接口均留在容器网络内。正式公开网站可在网站端口前配置 HTTPS 反向代理。

## 日常使用

所有命令都在部署目录执行，并保留 `--env-file .env.local`：

```shell
# 查看状态
docker compose --env-file .env.local ps -a

# 查看最近的应用日志
docker compose --env-file .env.local logs --tail 100 web worker

# 停止并移除容器，保留数据卷
docker compose --env-file .env.local down

# 再次启动
docker compose --env-file .env.local up -d
```

修改配置后执行 `up -d` 使其生效。MySQL 和 RabbitMQ 的账号密码在首次初始化后写入数据卷，不能只改配置文件来修改已有账号密码；需先修改服务内账号，再同步配置。不要通过删卷解决密码不匹配。

使用 `config --quiet` 检查配置即可；不带 `--quiet` 的 `config` 会展开密码，不宜分享完整输出。Web 与 Worker 均保留 UTF-8 控制台和文件日志，默认按天或 20MB 滚动，每类归档保留最多 15 天、200MB，可在 `.env.local` 中调整。

## 数据与备份

| 数据卷 | 保存内容 |
| --- | --- |
| `mysql-data` | 用户、题目、比赛、提交、配置及语言元数据 |
| `web-data` | 上传文件、私有测试数据与 `.secrets/storage-config.key` 加密主密钥 |
| `web-logs` | Web 日志 |
| `redis-data` | 缓存、判题租约与状态，启用 AOF |
| `rabbitmq-data` | 持久化任务、重试和结果消息 |
| `worker-data` | 测试缓存、工作目录、结果恢复记录与 Worker 日志 |
| `judge-files` | go-judge 文件缓存 |

实际卷名带项目名前缀，例如 `ymcloud_mysql-data`。普通 `down` / `up` 保留数据；**`docker compose down -v` 会删除数据卷，不用于日常停止或升级。**

备份前暂停提交、排空任务和结果队列，再停止应用写入，备份数据库与持久卷。数据库、上传文件和存储加密主密钥需要成套保存，同时保留 `.env.local`、对应版本配置与镜像信息。不要直接复制正在写入的 MySQL 数据目录作为一致性备份。

默认使用本地存储，首次安装不需要 SeaweedFS 或 MinIO。需要对象存储时，在后台填写 Web 容器可访问的 HTTPS 端点。Worker 缓存和结果恢复记录有各自的保留与清理策略，不要将整个 `worker-data` 当作临时文件删除。

## 更新已有系统

初始化 SQL **只在空数据库卷首次启动时执行**。更新文件或重启容器不会自动升级数据库结构；已有数据库需要按版本准备迁移方案，不能重新导入建表脚本来升级。

先查看新版本说明，暂停提交、排空任务并备份。保留原 `.env.local`、项目名和持久卷，再更新部署配置：

```shell
# 适用于通过 Git 克隆、且未手工修改仓库模板的部署目录
git pull --ff-only
```

对照新版 `.env`，将新增配置补充到 `.env.local`，保留已有密码和密钥。完成该版本需要的数据库迁移后执行：

```shell
docker compose --env-file .env.local config --quiet
docker compose --env-file .env.local pull
docker compose --env-file .env.local up -d
docker compose --env-file .env.local ps -a
```

ZIP 用户下载并解压新版本，保留自己的 `.env.local` 和原项目名。验证登录、四种语言判题、自测、比赛提交和排行榜后恢复服务。回退应使用上一版配置、镜像和配套数据恢复方案。

## 常见问题

| 现象 | 处理方式 |
| --- | --- |
| `docker` 或 `docker compose` 不存在 | 按官方安装指南安装 Docker 和 Compose 插件，再运行版本检查 |
| 无法连接 Docker daemon | 启动 Docker 服务或 Docker Desktop；Linux 还需确认当前用户有访问权限 |
| 腾讯云镜像下载失败 | 在 `.env.local` 将 `IMAGE_REPOSITORY` 改为 `docker.io/yemiao1/ymoj`，再执行启动命令 |
| `preflight` 非零退出 | 执行 `docker compose --env-file .env.local logs preflight`，按提示修正配置 |
| 提示初始化 SQL 不存在 | 独立仓库应有 `initdb/ymcloud.sql`；源码部署需有相邻的 `sql/ymcloud.sql`，不要用空目录代替 |
| MySQL 不健康 | 查看 `logs --tail 100 mysql`，检查初始化、磁盘和是否改动过已有密码 |
| Web / Worker 不健康 | 查看对应日志，先确认依赖服务健康，再检查服务密钥与判题容量 |
| 本机能打开，远程打不开 | 检查 `HTTP_BIND`、`HTTP_PORT`、云安全组和主机防火墙 |
| 网站端口被占用 | 修改 `.env.local` 的 `HTTP_PORT`，重新执行启动命令 |
| 更新后像一个空网站 | 检查 `COMPOSE_PROJECT_NAME` 是否变化，先找回原项目数据卷 |
| 判题返回容量不足的 SE | 题目限额超过部署预算；需配套提高资源，不能只提高并发 |

以上表格中的 `logs` 简写均需加完整命令前缀，例如：

```shell
docker compose --env-file .env.local logs --tail 100 mysql
```

## 维护者与源码开发

普通部署到这里即可。源码运行、环境隔离、存储配置和集成测试见[源码开发与维护](DEVELOPMENT.md)；独立判题节点见 [go-judge 部署文档](https://gitee.com/yemiaoo/ymcloud/blob/main/docker/go-judge/README.md)。以下构建与发布命令只在 **ymcloud 源码仓库** 执行。

## 维护者构建镜像与部署配置

在源码仓库根目录执行：

```shell
python docker/release.py
```

此命令仅供维护者，需要 JDK 17、Maven、Node/npm、Python 和 Docker Buildx。它构建干净的 Web/Worker jar 和前端，核验固定基础镜像及工具链，并构建、验证 `ymcloud-web:4.0.0`、`ymcloud-worker:4.0.0`、`ymcloud-go-judge:4.0.0`、`ymcloud-frontend:4.0.0`。默认将本地部署配置及内部构建记录写入 `target/phase3-verification/full-stack-deployment`，镜像保留在本机 Docker 中。这些构建记录用于维护者核对内容，普通部署用户无需生成或维护。`--output` 可指定新的空目录；脚本不会覆盖已有私有配置。`--skip-build` 只跳过 Java/前端编译，仍验证产物并构建镜像。

本机构建生成的 Compose 使用已验证的裸 image ID 和 `pull_policy: never`，进入输出目录，复制 `.env` 为 `.env.local` 并修改后，执行 `docker compose --env-file .env.local up -d`。这套配置只使用当前 Docker 中的镜像；其 `.env` 中的 `IMAGE_REPOSITORY` 不会改变固定的本地 image ID，也无需运行 `docker compose pull`。公开部署的 `deploy/compose.yaml` 使用仓库路径和版本标签，在缺少镜像时自动拉取。

源码 `deploy/.env` 保存公开测试默认值，生成部署配置时会核对其与 Compose 默认值一致。实际密码保存在部署机器的 `.env.local`，不要提交；维护者生成配置应使用保留公开默认值的干净源码。启动检查源码位于 `docker/web/preflight.py`，随 Web 镜像构建，部署用户无需执行或维护它。

初始化 SQL 始终只维护 `sql/ymcloud.sql`。源码 Compose 直接绑定此文件；生成独立目录时，脚本自动复制到 `initdb/ymcloud.sql` 并调整挂载路径。绑定设置 `create_host_path: false`，文件缺失时直接报错，不自动创建同名目录。部署目录不含 Python 脚本，也不生成镜像归档。

项目版本唯一配置在根 `pom.xml` 的 `<revision>`，本次为 `4.0.0`。修改此处后重新构建即可同步 Java 模块、前端项目版本及四个自研镜像的版本标签；维护者发布时将公开 Compose 的四个项目标签更新为该版本，脚本会拒绝与父 POM 不一致的部署模板。部署用户不需要在 `.env` 中再填写版本。内部构建记录保存版本与内容信息，自研镜像同时包含 OCI 版本标签。MySQL、Redis、RabbitMQ 和 go-judge 二进制保留各自的上游版本。

`--skip-build` 要求现有 `ymcloud-web.jar`、`ymcloud-judge.jar` 内的 Maven 版本和前端 `dist/version.json` 均与父 POM 一致，否则拒绝发布。不要手工修改版本文件或给旧镜像重打标签来代替实际构建。

## 维护者发布公开镜像

先完成本机构建和回归，并确认 Docker Hub 的 `yemiao1/ymoj` 为公开仓库。推送到腾讯云之前，必须先在个人版控制台选择命名空间 `ymoj`、新建仓库 `ymcloud`，类型选择“公有”，再验证公开访问。不要依赖 Docker 自动创建来保证仓库为公有；登录后能拉取镜像也不能证明匿名用户可以拉取。腾讯云的创建入口和公有类型说明见[个人版快速入门](https://cloud.tencent.com/document/product/1141/63910)。

确认两个仓库后登录。以下登录只供有发布权限的维护者使用，普通部署用户不需要登录：

```shell
docker login docker.io
docker login ccr.ccs.tencentyun.com
```

发布同一批已验证镜像到 `docker.io/yemiao1/ymoj` 与 `ccr.ccs.tencentyun.com/ymoj/ymcloud`，两个仓库均设为公开。每端只使用这一个仓库，通过“服务名-版本”标签区分七个镜像。四个项目镜像的版本读取父 POM；三个基础服务镜像直接复制已锁定的上游内容，不自行替换软件版本：

| 服务 | 本次发布标签 |
| --- | --- |
| Web | `web-4.0.0` |
| Worker | `worker-4.0.0` |
| go-judge | `go-judge-4.0.0` |
| 前端 | `frontend-4.0.0` |
| MySQL | `mysql-8.4` |
| Redis | `redis-7.4-alpine` |
| RabbitMQ | `rabbitmq-4.1-alpine` |

将同一批已验证的本地镜像分别推送到两个公开仓库。基础服务使用本次内部构建记录中的镜像，四个项目镜像使用本次构建产物；以下以 Web 为例，其余六个服务按表中标签处理：

```shell
docker tag ymcloud-web:4.0.0 docker.io/yemiao1/ymoj:web-4.0.0
docker push docker.io/yemiao1/ymoj:web-4.0.0
docker tag ymcloud-web:4.0.0 ccr.ccs.tencentyun.com/ymoj/ymcloud:web-4.0.0
docker push ccr.ccs.tencentyun.com/ymoj/ymcloud:web-4.0.0
```

推送完成后，按[维护者公开镜像发布验收](https://gitee.com/yemiaoo/ymcloud/blob/main/docker/go-judge/README.md#公开镜像发布验收)检查两端七个版本标签的匿名拉取、平台和镜像内容，完成部署回归后再发布对应的源码版本。这些验证仅由维护者执行，部署用户只需使用随发布版本提供的 Compose 和 `.env`。
