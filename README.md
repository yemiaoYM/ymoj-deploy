# YMOJ v4.1.0 部署说明

使用 Docker Compose 启动前端、后端、判题服务及其依赖。配置直接写在部署目录的 `.env` 中，Compose 会自动读取。

## 1. 准备环境

- Ubuntu 等 Linux amd64 系统，启用 cgroup v2。
- 已安装 Docker Engine 和 Docker Compose v2.20 及以上。
- 建议至少 2 核 CPU、4 GB 内存；并发参数默认设为 0，由服务按可用 CPU 自动计算；提高并发前需同步核对内存与进程预算。
- 放行网站端口，默认是 TCP 80。其他服务无需开放公网端口。

## 2. 下载并进入部署目录

```bash
git clone https://gitee.com/yemiaoo/ymoj-deploy.git
cd ymoj-deploy
```

也可从 [GitHub 部署仓库](https://github.com/yemiaoYM/ymoj-deploy) 获取同一版本。

如果已下载部署包，解压后 `cd` 到包含 `compose.yaml`、`.env` 和 `initdb/` 的目录。

如果使用本源码仓库，则在仓库根目录执行 `cd deploy`；保留同级 `sql/ymcloud.sql`，不要只复制 `deploy` 文件夹。

## 3. 配置 .env

直接编辑当前目录的 `.env`，不需要复制或改名。

| 配置项 | 默认值与用途 |
| --- | --- |
| `HTTP_PORT` | `80`，网站对外端口；被占用时可改为 `8080` |
| `HTTP_BIND` | `0.0.0.0`，允许外部访问；仅本机体验可改为 `127.0.0.1` |
| `IMAGE_REPOSITORY` | 默认腾讯云镜像源；拉取失败可改为 `docker.io/yemiao1/ymoj` |
| `TZ` | `Asia/Shanghai`，网站业务时区 |
| `MAIL_FROM`、`MAIL_PASS` | 可选 QQ 邮箱及 SMTP 授权码，用于找回密码 |

默认密码仅供快速体验。公开部署前，在 `.env` 修改 4 个密码：`MYSQL_ROOT_PASSWORD`、`MYSQL_PASSWORD`、`REDIS_PASSWORD`、`RABBITMQ_PASSWORD`；同时修改 3 个独立服务密钥：`TOKEN_SECRET`、`WORKER_TOKEN`、`GO_JUDGE_TOKEN`。长度要求见 `.env` 注释。

其他参数先保持默认。不要改容器地址或内部端口；Compose 已配置服务之间的连接。

## 4. 启动并访问

在上述部署目录执行：

```bash
docker compose up -d
```

首次启动会自动拉取镜像、初始化数据库并启动服务，需要等待几分钟。查看状态：

```bash
docker compose ps -a
```

`preflight` 是启动预检任务，显示 `Exited (0)` 属于正常完成。其余 7 个服务应处于运行状态并通过健康检查。

浏览器访问 `http://服务器IP`。如果修改了端口，例如 `HTTP_PORT=8080`，则访问 `http://服务器IP:8080`。

后台地址为 `/admin/login`。首次登录账号为 **`admin`**，密码为 **`Ymcloud@123`**，登录后及时修改。

## 5. 服务端口与初始账号

只有前端端口发布到宿主机。下表其余端口仅在 Compose 内部网络使用。

| 服务 | 容器端口 | 宿主机端口 | 初始账号 / 密码或认证 |
| --- | --- | --- | --- |
| 前端 `frontend` | `8080` | `.env` 的 `HTTP_PORT`，默认 `80` | 网站管理员 `admin` / `Ymcloud@123` |
| 后端 `web` | `9091` | 不发布 | 通过网站登录获取令牌 |
| MySQL `mysql` | `3306` | 不发布 | 应用账号 `ymcloud` / `ymcloudMysql123456`；管理账号 `root` / `ymcloudRoot123456` |
| Redis `redis` | `6379` | 不发布 | 默认用户 `default` / `ymcloudRedis123456` |
| RabbitMQ `rabbitmq` | `5672` | 不发布 | `ymcloud` / `ymcloudRabbit123456`，虚拟主机 `/ymcloud` |
| 沙箱 `go-judge` | `5050` | 不发布 | 使用 `.env` 的 `GO_JUDGE_TOKEN`，无网页登录账号 |
| 判题 `worker` | 无 HTTP 监听端口 | 不发布 | 使用 `.env` 的 `WORKER_TOKEN` 与后端通信 |
| 预检 `preflight` | 无 | 不发布 | 执行结束后退出 |

表中数据库、缓存和队列密码是未修改 `.env` 时的默认值。修改后以实际配置为准。当前 RabbitMQ 镜像不提供 `15672` 管理页面。服务密钥不是网站登录密码。

## 6. 查看日志与保存数据

启动失败时先查看预检和相关服务日志：

```bash
docker compose logs --tail=100 preflight web worker
```

“服务监控”采集失败时查看 `web` 日志。Web 的普通 `/tmp` 保持 `noexec`；JNA 原生库使用专用 `/jna-tmp` 内存挂载，并通过 `JAVA_TOOL_OPTIONS=-Djna.tmpdir=/jna-tmp` 指定。该小目录允许加载原生库，仅容器应用用户可访问。自定义 Compose 时需保留这两个配置；修改后重新执行 `docker compose up -d` 重建发生变化的容器。

数据库、上传文件、判题数据和应用日志保存在 Docker 数据卷中。普通停止或重建容器会保留数据。

**不要执行 `docker compose down -v`，该命令会删除数据卷。**

首次初始化后不要随意改变 `COMPOSE_PROJECT_NAME`。MySQL、RabbitMQ 已有账号的密码保存在数据卷中，仅修改 `.env` 不会同步修改已有账号。初始化 SQL 也只在空数据库首次启动时执行。

## 7. 从旧版本升级到 v4.1.0

本版项目镜像使用 `web-4.1.0`、`worker-4.1.0`、`go-judge-4.1.0`、`frontend-4.1.0`；预检与 Web 使用相同镜像。MySQL、Redis、RabbitMQ 保持各自基础版本标签。

已有部署不能只替换镜像：本版包含题目与比赛权限、SPJ 字段及判题消息格式变更。先备份数据库、数据卷和原配置，暂停新提交，等待判题、SPJ 编译预检、重试和结果队列（含未确认消息）排空，确认 Worker 无运行任务后停止旧 Web/Worker。

根据实际数据库结构审查源码仓库 `sql/migrations/` 中的以下迁移，按日期顺序仅执行尚未应用的部分，不重复执行；执行前完成脚本要求的历史数据人工确认：

1. `20261101_problem_contest_permissions.sql`：题目与比赛权限、角色和索引调整。
2. `20261106_problem_spj.sql`：新增 SPJ 语言、源码及摘要字段。
3. `20261107_judge_payload_cleanup.sql`：清理历史判题快照中已移除的消息字段。

这些脚本不能替代对实际数据库与目标结构的差异核对。初始化 SQL 仅供全新数据库使用，禁止向已有数据库重新导入 `sql/ymcloud.sql`。迁移脚本未随部署包提供时，应先取得与本版匹配且经过审查的迁移文件，再开始升级。

保留原 `.env` 中的密码、密钥及自定义资源配置，逐项合并新模板；在确认四个项目镜像均已发布后拉取镜像，同步升级 Web、Worker、go-judge 和前端。检查服务健康，并验证登录、普通判题、SPJ、比赛提交及结果展示后恢复提交。若需回退，使用与旧代码匹配的数据库备份和配置，不能仅回退镜像。
