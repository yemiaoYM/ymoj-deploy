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

普通部署到这里即可。源码运行、环境隔离、存储配置和集成测试见[源码开发与维护](#源码开发与维护)；独立判题节点见 [go-judge 部署文档](https://gitee.com/yemiaoo/ymcloud/blob/main/docker/go-judge/README.md)。以下构建与发布命令只在 **ymcloud 源码仓库** 执行。

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

## 源码开发与维护

只部署网站无需阅读本节；需要修改、调试或构建源码时展开。以下命令在 [ymcloud 源码仓库](https://gitee.com/yemiaoo/ymcloud)根目录执行。

<details>
<summary>展开源码运行、环境配置与回归验证说明</summary>

## 运行环境

| 环境 | 要求 |
| --- | --- |
| Java | JDK 17，项目编译目标为 Java 17 |
| Maven | 3.9+ |
| Node.js | 推荐 22，当前前端依赖要求至少 20.5 |
| npm | 9+，使用仓库中的 `package-lock.json` 安装 |
| MySQL | 8.0+，字符集 `utf8mb4` |
| Redis | 6+ |
| RabbitMQ | 3.13+；判题使用普通持久化 Topic，不需要延迟交换机插件 |
| Docker | Docker Engine 或 Docker Desktop，使用 Linux 容器 |
| 同机生产部署 | 最低 2 核 4GB，Web、MySQL、Redis、RabbitMQ 与单个 Worker 共用服务器，Worker 并发保持 1 |

可以使用已经运行的 MySQL、Redis 和 RabbitMQ。开始前确认后端能连接这些服务，并且 RabbitMQ 账户有相应 virtual host 的权限。

2GB 内存不作为生产支持规格。2 核 4GB 是低并发部署基线；题目允许更高内存、同时运行对象存储或增加评测并发时，需要相应提高服务器配置。测试数据缓存默认 5GiB 是磁盘上限，文件通过小缓冲流式读取，不会预分配同等内存。

## 首次启动

以下命令从项目根目录执行，前端步骤会明确切换到 `ymcloud-vue`。

### 1. 初始化一个空数据库

[sql/ymcloud.sql](https://gitee.com/yemiaoo/ymcloud/blob/main/sql/ymcloud.sql) 是当前版本的完整初始化文件，包含 23 张业务表及必要数据。使用现有 MySQL 即可，无需另建 MySQL 容器。

首次安装时创建一个空库，再导入 SQL。下面的命令适用于 Linux、Windows PowerShell 和命令提示符；密码在提示时输入。替换连接地址、用户名和库名后，请同步修改后端配置。

```text
mysql -h 127.0.0.1 -u root -p -e "CREATE DATABASE IF NOT EXISTS ymcloud DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;"
mysql --default-character-set=utf8mb4 -h 127.0.0.1 -u root -p ymcloud -e "SOURCE sql/ymcloud.sql;"
```

如果 `ymcloud` 已经是业务库，请使用另一个空库名。此文件用于全新安装，不能作为已有版本的升级脚本；重复导入不会覆盖已有记录或修改旧表结构。

初始化数据包括：

| 内容 | 初始值 |
| --- | --- |
| 超级管理员 | 用户 ID 为 `1`，用户名 `admin`，初始密码 `Ymcloud@123` |
| 管理员邮箱 | `admin@example.invalid`，仅为占位值，不能接收邮件 |
| 内置角色 | 管理员、题目管理员、普通用户，共 3 个角色 |
| 菜单与权限 | 67 项，包含文件管理、存储配置与历史文件迁移权限 |
| 判题语言 | Java、C、C++、Python，共 4 种 |
| 注册开关 | 开启，可在后台“常用设置 → 系统配置”关闭 |
| 文件存储 | 本地存储，其他服务需要在后台配置 |

用户 ID 为 `1` 的正常账号具有全部系统权限。初始密码是公开的安装示例，首次登录后立即修改密码和邮箱，再对外开放服务。请在后台创建自己的题目并上传测试数据；初始库不包含历史用户、题目、比赛、提交、文件或存储连接凭据。

### 2. 填写后端连接配置

通用默认值位于 [application.yml](https://gitee.com/yemiaoo/ymcloud/blob/main/ymcloud-web/src/main/resources/application.yml)，默认启用 `dev` 环境。在同一目录新建 `application-dev.yml`，按自己的服务填写以下内容。`yyyy` 仅为占位值，需要替换；Redis 没有密码时使用空字符串。

```yaml
spring:
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://127.0.0.1:3306/ymcloud?useSSL=false&serverTimezone=Asia/Shanghai&characterEncoding=UTF-8
    username: yyyy
    password: yyyy
  data:
    redis:
      host: 127.0.0.1
      port: 6379
      database: 0
      password: yyyy
  rabbitmq:
    host: 127.0.0.1
    port: 5672
    username: yyyy
    password: yyyy
    virtual-host: /

token:
  secret: ${YMCLOUD_TOKEN_SECRET}
```

`YMCLOUD_TOKEN_SECRET` 是 OJ 登录令牌的签名密钥，不能使用仓库中的公开示例值。首次安装可在准备运行后端的终端生成一个随机值。

Linux / Bash（需要 OpenSSL）：

```bash
export YMCLOUD_TOKEN_SECRET="$(openssl rand -base64 64 | tr -d '\n')"
export YMCLOUD_WORKER_SERVICE_TOKEN="$(openssl rand -hex 32)"
```

Windows / PowerShell 7：

```powershell
$env:YMCLOUD_TOKEN_SECRET = [Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(64))
$env:YMCLOUD_WORKER_SERVICE_TOKEN = [Convert]::ToHexString([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
```

环境变量只对当前终端及其启动的进程生效。部署时将生成值保存在自己的服务环境配置或密钥管理中，后续启动继续使用同一值；从 IDE 启动时也要设置该环境变量。不要将实际密钥提交 Git。

`YMCLOUD_WORKER_SERVICE_TOKEN` 是 Web 与 Worker 之间的独立服务密钥，至少 32 个可打印字符，两个进程必须使用相同值。它只允许读取已发布测试版本，不赋予用户或管理员权限，也不复用存储密钥。未配置时 Web 拒绝数据下载，Worker 拒绝启动。

基础登录与注册不依赖邮件发送。需要忘记密码或邮箱修改功能时，再在私有环境配置中填写 `mail.from`、`mail.pass`；当前邮件实现使用 QQ SMTP 和邮箱授权码。

### 3. 准备统一判题执行服务

Linux 生产部署要求 cgroup v2。先打包 Worker，再构建唯一的 go-judge v1.13.3 运行镜像及非特权 Worker 镜像：

```bash
mvn -pl ymcloud-judge -am package -DskipTests
bash docker/build.sh
```

统一镜像固定官方来源及 Debian 12 slim Digest、仓库快照和软件包版本，提供 OpenJDK 17、GCC/G++ 12、Python 3.11。构建生成不可变运行镜像锁；Compose 只包含 Worker 和 go-judge，连接已有 Web、Redis、RabbitMQ。Worker 无 Docker SDK、Socket 或 Docker 管理权限。

按 [第三阶段部署与验收](https://gitee.com/yemiaoo/ymcloud/blob/main/docker/go-judge/README.md) 创建独占目录、填写两个独立令牌、检查容量并启动服务。开发时直接运行 Worker jar 也必须提供 `YMCLOUD_GO_JUDGE_URL` 和 `YMCLOUD_GO_JUDGE_TOKEN`；启动检查版本、鉴权、cgroup v2、默认 seccomp 及工具链通过后才消费任务。

### 4. 构建并分别运行 Web 与 Worker

在已设置签名密钥的终端执行：

```text
mvn package -DskipTests
java -jar ymcloud-web/target/ymcloud-web.jar --spring.config.additional-location=file:./ymcloud-web/src/main/resources/
```

也可以在 IDE 中运行 `com.ymcloud.YmCloudWebApplication`，工作目录为项目根目录，程序参数填写 `--spring.config.additional-location=file:./ymcloud-web/src/main/resources/`。Web 和 Worker 的私有 dev/prod 配置均不进入发布 jar；开发时显式读取上述配置目录，完整 Docker 部署通过 `--env-file .env.local` 读取本机配置。默认后端监听 `127.0.0.1:9091`。

另一个终端启动 Worker。它不连接 MySQL，也不需要存储服务的地址、桶或访问密钥。使用与 Web 相同的开发 Redis、RabbitMQ virtual host 和服务身份，并设置 Worker 可访问的 Web 地址：

```text
java -jar ymcloud-judge/target/ymcloud-judge.jar --spring.config.additional-location=file:./ymcloud-judge/src/main/resources/
```

Worker 与 Web 一样默认启用 `dev`。在 `ymcloud-judge/src/main/resources/application-dev.yml` 中填写与 Web 开发环境一致的 `spring.data.redis`、`spring.rabbitmq` 和 `ymcloud.worker.data` 配置。Worker 私有 dev/prod 配置不进入 jar，上述开发命令显式读取源码旁的配置目录；生产使用外置配置目录或环境变量。不要复制包含业务数据库凭据的 Web 配置到 Worker。也可通过 `REDIS_HOST`、`REDIS_PORT`、`REDIS_PASSWORD`、`REDIS_DATABASE` 和 `RABBITMQ_HOST`、`RABBITMQ_PORT`、`RABBITMQ_USERNAME`、`RABBITMQ_PASSWORD`、`RABBITMQ_VHOST` 设置基础连接默认值；实际环境配置中的显式值会覆盖这些默认值。`YMCLOUD_WORKER_API_URL` 默认为 `http://127.0.0.1:9091`。

远程 Worker 访问 Web 默认必须使用 HTTPS，本机回环地址可用 HTTP。完整单机 Compose 显式允许其隔离容器网络中的 RFC1918 私网 HTTP；客户端校验全部 DNS 结果并使用已验证 IP，不跟随重定向。反向代理只向判题节点开放 `/internal/judge-worker/**`；无需向浏览器提供该入口。

双方会声明以下新交换机和队列：

| 用途 | 默认名称 |
| --- | --- |
| 判题交换机 | `judge.worker-v2.topic` |
| 判题任务队列 | `judge.worker-v2.queue` |
| 判题结果队列 | `judge.worker-v2.result.queue` |
| 有限重试 / 无效任务队列 | 任务队列名加 `.retry` / `.dead` |
| 任务 / 结果路由键 | `judge` / `judge.result` |

名称可通过 `ymcloud.judge.exchange`、`task-queue`、`result-queue` 配置，或对应的 `YMCLOUD_JUDGE_EXCHANGE`、`YMCLOUD_JUDGE_TASK_QUEUE`、`YMCLOUD_JUDGE_RESULT_QUEUE` 环境变量修改。

Web 的 `judge_dispatch` 表保存任务快照，任务发布等待 RabbitMQ 确认；失败后有限重试，超过总截止时间记录系统错误。Worker 用 Redis 租约合并重复执行，最终结果先保存到本地日志，再确认发布并应答任务。Web 在事务内校验执行标识、版本和结果序号，重复结果不重复插入测试点或 AC 记录。Redis 状态缓存丢失时，状态查询从数据库恢复。

任务箱的发布时间、恢复时间和截止时间统一使用 UTC；消息使用 epoch 毫秒，跨主机时区不改变任务预算。

正式提交与自测共用任务箱的数据库自增编号，保持浏览器可以精确表示的整数范围。已有数据库升级时从历史最大提交编号之后继续分配，旧提交 URL 保持不变。

### 5. 启动前端并登录后台

另开一个终端执行：

```text
cd ymcloud-vue
npm ci
npm run dev
```

访问 `http://localhost:5173`。后台登录地址为 `http://localhost:5173/admin/login`，使用初始化管理员账号登录并修改密码、邮箱。

Vite 的开发代理将 `/api` 转发到 `http://localhost:9091` 并去掉前缀，将 `/files` 转发到同一后端。创建题目、上传成对测试数据，再用初始化的语言提交代码，即可验证判题链路。

## 文件与对象存储

Web 默认启动自动创建项目根目录下的 `files/public`、`files/private`。将 jar 复制到独立部署目录时，默认文件根目录位于 jar 所在目录。需要固定目录时设置 `YMCLOUD_FILE_BASE_DIR`。

Worker 的工作目录、结果日志及版本缓存默认位于启动目录的 `files/worker/work`、`files/worker/results`、`files/worker/cache`。通过 `YMCLOUD_JUDGE_WORK_DIR`、`YMCLOUD_JUDGE_RESULT_DIR` 和 `YMCLOUD_JUDGE_CACHE_DIR` 固定部署目录。测试数据以文件流读取，保留输入原始字节；下载校验成功后才原子启用。缓存有容量上限，只清理没有评测引用的版本；每个 Worker 使用独立目录，同一缓存目录不能被两个进程共用。结果日志应保存在可持续写入的本地磁盘，重启时保留。运行账户需要相应目录读写权限。

go-judge 为每个测试点提供独立临时文件系统与默认 seccomp，编译器和运行库只读。文件缓存位于独占磁盘目录，任务正常清理配合 TTL 兜底；服务启动清理异常退出遗留文件，Worker 数据缓存及结果日志保留。默认单题/编译上限 512MiB、输出合计 1MiB、单文件及编译产物 16MiB；超出部署容量直接产生明确 SE，不截短题目内存或重复执行。

公开头像、封面等通过当前网站的 `/files/public/**` 访问。测试数据始终作为私有文件，查询和下载需要题目测试数据权限；普通私有文件还需要独立的私有文件权限。不要将整个 `files/private` 目录配置为静态资源目录。

使用外部存储时，由超级管理员进入“常用设置 → 存储配置”，填写实际服务的地址、桶和访问密钥，保存后“测试连接”，成功再“设为默认”。配置立即生效，无需重启后端。MinIO、SeaweedFS 等待配置行只是示例，保存不会自动启用；新默认配置只影响之后上传的文件，已有文件仍从原配置读取。

公开文件与私有文件使用不同存储桶，两个桶均保持私有，由 OJ 控制访问。远程存储使用 HTTPS，连接地址以 OJ 后端所在机器或容器能够访问的地址为准。

如果没有对象存储，可选用 [SeaweedFS 安装说明](https://gitee.com/yemiaoo/ymcloud/blob/main/seaweedfs/README.md) 中的 Docker 脚本；已有 SeaweedFS、MinIO 或 OSS 的用户直接添加后台配置即可。

OJ 首次保存存储配置时自动生成 `files/.secrets/storage-config.key`，用于加密数据库中的存储连接凭据。部署备份应同时保留数据库、文件或对象存储数据及该主密钥；恢复时使用对应的主密钥。自定义文件根目录后，主密钥也位于该目录的 `.secrets` 中。

## 开发与生产环境

开发和生产使用独立的数据库、Redis database、RabbitMQ virtual host，以及各自的文件目录、存储桶和主密钥。只区分 `dev` / `prod` 文件名不会隔离共享服务的数据。

开发连接写入 `application-dev.yml`，生产连接写入 `application-prod.yml`。生产启动时显式选择环境：

```text
java -Xms64m -Xmx256m -jar ymcloud-web/target/ymcloud-web.jar --spring.profiles.active=prod --spring.config.additional-location=file:./config/
java -Xms32m -Xmx128m -jar ymcloud-judge/target/ymcloud-judge.jar --spring.profiles.active=prod --spring.config.additional-location=file:./config/
```

以上为单 Worker、低并发部署的 JVM 堆起点，堆上限不等于进程总内存。操作系统、MySQL、Redis、RabbitMQ 和判题容器仍需各自预留空间；编译和用户程序在 Docker 内运行，不占 Worker 的 Java 堆。题目的时间、内存限制决定评测语义，增加或减少 Worker 堆不会改变这些限制。

高配服务器可自行提高 Web、Worker 的 `-Xmx`，并通过 `YMCLOUD_WORKER_CONCURRENCY` 逐步增加评测并发。默认常驻 go-judge 总预算 1 核、1GiB，禁用 swap，Worker/沙箱并发均为 1。扩容必须配套调整两侧并发、单题/编译内存与服务总预算，并通过墙钟公平性验收；具体参数见部署说明。

这两个环境文件被 Git 忽略。使用命令行参数、环境变量或外置配置管理实际部署信息；分发 jar 前也检查打包资源，避免把开发或生产的真实凭据随制品发送给他人。

生产前端构建：

```text
cd ymcloud-vue
npm run type-check
npm run build
```

产物位于 `ymcloud-vue/dist`。部署静态页面时配置 SPA 路由回退，并将 `/api`、`/files` 代理到后端；`/api` 代理需去掉前缀，与开发代理保持一致。后端默认仅监听本机，可由同机反向代理提供 HTTPS 访问。

真实凭据、访问密钥、私有配置、数据库导出、用户数据和测试数据不上传 Git。

## 从第一阶段升级

第一阶段旧任务和新版协议不兼容。先暂停新提交，让旧 Web 消费者处理完 `judge.storage-v1.*` 队列并确认结果已落库，再停止旧 Web。不要清空队列或让新旧消费者共用判题队列。

SQL 目录仅保留当前版本的完整初始化文件 [sql/ymcloud.sql](https://gitee.com/yemiaoo/ymcloud/blob/main/sql/ymcloud.sql)，用于首次安装的空数据库，不提供历史版本迁移脚本。已有数据库升级需根据实际版本单独准备迁移方案，保留历史结果及测试版本，不可直接导入初始化文件。

部署新 Web 和 Worker，使用相同的服务密钥及新版队列，完成一次真实提交和自测后恢复提交。维护窗口内回退时，先排空新版任务，停止新版服务，再恢复旧 Web 和旧队列配置；保留新增字段、任务表和文件数据，不删除历史记录。

多实例扩展时，每个 Worker 设置不同 `YMCLOUD_WORKER_ID`、独立缓存/工作/结果目录，使用同一环境的任务队列、Redis 和 Web 服务入口。初始部署建议单 Worker、并发 1，确认判题节点容量后再增加 `YMCLOUD_WORKER_CONCURRENCY`。

Worker 已记录队列等待时间、执行耗时、缓存命中、下载失败、校验失败和系统错误指标（`ymcloud.judge.*`）。它不启动 HTTP 服务；需要查看指标时，通过自己的私有配置开启 `spring.jmx.enabled=true`、`management.endpoints.jmx.exposure.include=metrics`，使用本机 JMX 工具读取。任务箱中已完成的任务仍保留快照，后续可按部署的数据保留规则归档，勿直接清理未完成任务或运行中的版本缓存。

Worker 的 INFO 日志记录启动、任务接收、数据准备、编译完成、终态发布及恢复；WARN 记录下载校验、租约、重试和系统故障。日志包含提交、执行和数据版本标识，耗时使用毫秒，内存使用 KiB，不记录源码、测试输入输出或凭据。开发时可在私有配置中将 `logging.level.com.ymcloud.judge` 和 `logging.level.com.ymcloud.web.judge` 设为 `DEBUG`，查看测试点、缓存命中及消息进度；生产默认保持 INFO。

Web 和 Worker 使用各自的 `logback-spring.xml`：控制台保留 INFO 并按终端能力着色；`application.log` 保存应用日志，`error.log` 单独保存 ERROR，文件统一 UTF-8、无颜色字符。默认目录分别为 `./files/logs/web`、`./files/logs/worker`（相对于进程工作目录），可用 `LOGGING_FILE_PATH` 覆盖。Docker 镜像写入 `/data/logs` 的持久卷。日志按天或 20MB 滚动并 gzip 压缩，每类归档最多 15 天、200MB，启动时清理过期归档；应用日志上限与判题结果记录的保留期互不影响。完整部署可在 `.env.local` 的日志部分调整这些值。

判题源码从内存上传，编译结束即删除上传文件；每点输入在执行结束后删除，编译产物在全部测试点完成或任务异常退出时删除。已收到但校验无效的沙箱响应也会回收其中合法文件 ID；清理失败或断连未返回 ID 时由 go-judge 默认 1 小时 TTL 兜底。沙箱启动清理独占 `files`、`run` 两个子目录，Worker 容器启动仅清工作目录。测试版本缓存按 5GiB 容量淘汰无引用版本；正式结果记录保留 7 天，每分钟检查，异常退出的 `.result-*.tmp` 超过 1 小时后回收。源码、产物与临时文件不能和测试数据缓存、结果恢复记录一并清空。

## 开发验证

修改前端后运行 `npm run type-check` 和 `npm run build`。Java 单元测试可按涉及的模块与测试类筛选执行。旧版 `WebTest` 是依赖业务数据、邮件服务和固定脚本的手工调试用例，默认跳过；仅在准备好对应开发环境后显式设置 `YMCLOUD_RUN_LEGACY_WEB_TESTS=true`，不要用于隔离回归。

真实存储数据库测试需要显式启用 `YMCLOUD_STORAGE_DB_IT=true`，真实 S3 测试需要 `YMCLOUD_RUN_S3_TESTS=true`。SeaweedFS 安装、权限、持久性及性能验证入口见 [SeaweedFS 开发验证说明](https://gitee.com/yemiaoo/ymcloud/blob/main/seaweedfs/README.md#排查与开发验证)。

Worker 的真实 go-judge 回归需要专属验收服务，显式启用 `YMCLOUD_RUN_GO_JUDGE_TESTS=true`，配置 `YMCLOUD_GO_JUDGE_URL` 和独立令牌。任务发布与结果事务测试 `JudgeDispatchDatabaseIT` 需要 `YMCLOUD_JUDGE_DB_IT=true`，仅接受本机开发 MySQL，在随机临时库中执行并清理，覆盖并发重复消息、事务回滚、超时恢复和提交编号兼容性。

打包后可运行 [独立进程整体验证](https://gitee.com/yemiaoo/ymcloud/blob/main/ymcloud-web/src/test/scripts/judge/verify_worker.py)。安装测试依赖 `PyYAML`、`pymysql`、`redis`、`pika`，设置 `YMCLOUD_WORKER_E2E=true` 和 `YMCLOUD_WORKER_E2E_REDIS_DATABASE` 后执行：

```text
python -B ymcloud-web/src/test/scripts/judge/verify_worker.py
```

该 Redis database 必须为空、不同于开发配置中的 database，且处于 1–15 范围。脚本读取本机 `application-dev.yml`，使用随机数据库、独立队列和临时目录启动真实 Web 与 Worker，验证版本固定、缓存修复、普通/比赛提交、自测、权限、重复消息及重启恢复。验证时两个 JVM 均按 2 个处理器运行，Worker 堆上限 128MiB、Web 堆上限 256MiB；这验证应用在有限堆下的功能，不代替同机全部服务的容量测试。测试连接配置只保存在临时目录，结束后清理；报告位于忽略的 `target/phase3-verification`。不要使用生产连接配置运行测试。

[Linux 权限验证](https://gitee.com/yemiaoo/ymcloud/blob/main/ymcloud-web/src/test/scripts/judge/verify_linux.py) 使用不可变统一运行镜像和打包后的 Worker，在独立非 root 容器内检查私有缓存权限、损坏恢复及链接拒绝。先设置 `YMCLOUD_WORKER_LINUX_TEST=true`，并将 `YMCLOUD_GO_JUDGE_IMAGE` 设置为构建产物 `images.env` 中的实际摘要，再执行：

```text
python -B ymcloud-web/src/test/scripts/judge/verify_linux.py
```

## 第三阶段升级

上线前暂停提交，排空任务、重试和结果队列，并确认 `judge_dispatch` 未完成任务及活跃租约收敛。已有数据库需按实际版本准备迁移方案，将语言展示版本与统一工具链对齐；保留历史提交和任务快照，`image/env` 仅保留兼容元数据。全新安装使用 `sql/ymcloud.sql`。替换 Worker 与 go-judge 后完成四语言及普通提交、比赛、自测、状态轮询和 AC 统计冒烟，再恢复提交。恢复旧部署时成套恢复上一版本的部署配置、固定镜像及对应数据，代码没有双引擎开关。

完整上线、恢复、回归矩阵及墙钟公平性门槛见 [部署与故障排查说明](https://gitee.com/yemiaoo/ymcloud/blob/main/docker/go-judge/README.md)。SQL、配置及文档仍需按具体文件审批后才能提交或推送，`AGENTS.md` 仅保留本地。

## 许可

本项目采用 [MIT License](https://gitee.com/yemiaoo/ymcloud/blob/main/LICENSE)。欢迎通过 Issue 和 Pull Request 交流、改进。

</details>
