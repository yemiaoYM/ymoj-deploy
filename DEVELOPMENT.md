# ymcloud 源码开发与维护

本文面向需要修改、调试或构建 ymcloud 的开发者。只想搭建网站，请使用[独立部署仓库](https://gitee.com/yemiaoo/ymoj-deploy)及[部署指南](README.md)。下列命令除特别说明外均在源码仓库根目录执行。

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
