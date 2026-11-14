SET NAMES utf8mb4;

CREATE TABLE `user` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `username` varchar(50) NOT NULL COMMENT '登录用户名（唯一）',
  `password` varchar(255) NOT NULL COMMENT 'BCrypt 密码哈希',
  `nickname` varchar(50) DEFAULT NULL COMMENT '昵称',
  `sex` tinyint DEFAULT '0' COMMENT '性别：0=保密，1=男，2=女',
  `email` varchar(255) NOT NULL COMMENT '邮箱',
  `avatar` varchar(512) DEFAULT NULL COMMENT '头像 URL',
  `school` varchar(255) DEFAULT NULL COMMENT '学校',
  `signature` text COMMENT '个性签名',
  `blog` varchar(512) DEFAULT NULL COMMENT '博客链接',
  `login_ip` varchar(45) DEFAULT NULL COMMENT '最后登录 IP',
  `login_date` datetime DEFAULT NULL COMMENT '最后登录时间',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '账号状态：1=正常，0=禁用',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `username` (`username`) USING BTREE,
  UNIQUE KEY `email` (`email`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='用户表';

CREATE TABLE `role` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `code` varchar(64) NOT NULL COMMENT '角色编码（如 ADMIN, USER）',
  `name` varchar(64) NOT NULL COMMENT '角色名称（中文名，如 管理员，普通用户）',
  `description` varchar(255) DEFAULT NULL COMMENT '角色描述',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '角色状态：0=禁用，1=启用',
  `created_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `built_in` tinyint(1) NOT NULL DEFAULT '0' COMMENT '系统内置角色',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_role_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='角色表';

CREATE TABLE `auth` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `code` varchar(128) DEFAULT NULL COMMENT '权限编码（如 problem:problem:add, user:user:remove）',
  `name` varchar(128) DEFAULT NULL COMMENT '权限名称（中文名，如 新增题目，删除用户）',
  `parent_id` bigint unsigned DEFAULT NULL COMMENT '父权限ID',
  `path` varchar(255) DEFAULT NULL COMMENT '路由路径',
  `route_name` varchar(128) DEFAULT NULL COMMENT '路由名称',
  `component` varchar(255) DEFAULT NULL COMMENT '前端组件路径（菜单权限时使用）',
  `icon` varchar(64) DEFAULT NULL COMMENT '前端菜单图标',
  `type` varchar(255) DEFAULT NULL COMMENT '类型：M=目录，C=页面，F=操作权限',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '权限状态：0=禁用，1=启用',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `built_in` tinyint(1) NOT NULL DEFAULT '0' COMMENT '系统内置权限',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_auth_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='权限表';

CREATE TABLE `user_role` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint unsigned NOT NULL COMMENT '用户ID',
  `role_id` bigint unsigned NOT NULL COMMENT '角色ID',
  `created_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_user_role` (`user_id`,`role_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_role_id` (`role_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='用户角色关联表';

CREATE TABLE `role_auth` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `role_id` bigint unsigned NOT NULL COMMENT '角色ID',
  `auth_id` bigint unsigned NOT NULL COMMENT '权限ID',
  `created_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_role_auth` (`role_id`,`auth_id`) USING BTREE,
  KEY `idx_role_id` (`role_id`) USING BTREE,
  KEY `idx_auth_id` (`auth_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='角色权限关联表';

CREATE TABLE `system_setting` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `setting_key` varchar(128) NOT NULL COMMENT '配置键',
  `setting_value` varchar(255) NOT NULL COMMENT '配置值',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_setting_key` (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='系统配置表';

CREATE TABLE `language` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '语言ID',
  `name` varchar(100) NOT NULL COMMENT '语言名称：C++、C、Java、Python',
  `image` varchar(100) NOT NULL COMMENT '兼容语言镜像元数据，不用于执行或校验',
  `env` varchar(100) NOT NULL COMMENT '兼容环境元数据，不用于执行或校验',
  `version` varchar(100) DEFAULT NULL COMMENT '语言版本信息，如 g++ 9.4 / Python 3.10',
  `content_type` varchar(100) DEFAULT NULL COMMENT 'MIME类型，用于前端代码高亮，如 text/x-c++src',
  `file_name` varchar(100) NOT NULL COMMENT '默认文件名，如main.py,Main.java,main.cpp,main.c',
  `file_extension` varchar(20) NOT NULL COMMENT '默认文件扩展名，如 .cpp、.py',
  `compile_cmd` text COMMENT '编译指令，编译型语言需要，如 g++ main.cpp -o main',
  `run_cmd` text COMMENT '运行指令，如 ./main、python3 main.py',
  `template_code` longtext COMMENT '语言默认代码模板，显示在编辑器中',
  `code_template` longtext COMMENT '题面中用于填空题的嵌套模板',
  `type` tinyint NOT NULL DEFAULT '0' COMMENT '语言类型：0=编译型，1=解释型',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '启用状态：1=启用，0=停用',
  `oj` varchar(100) DEFAULT 'myy' COMMENT '归属OJ标识，自身平台填myy',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `name` (`name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='编程语言表';

CREATE TABLE `tag_classification` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(255) NOT NULL COMMENT '标签分类名称',
  `priority` int unsigned NOT NULL DEFAULT '1' COMMENT '分类优先级（数值越小优先级越高）',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='标签分类表';

CREATE TABLE `tag` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '标签ID',
  `name` varchar(255) NOT NULL COMMENT '标签名称',
  `parent_id` bigint unsigned DEFAULT NULL COMMENT '父标签ID',
  `color` varchar(255) DEFAULT NULL COMMENT '标签颜色（如 #ff6600）',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='标签表';

CREATE TABLE `problem` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '题目ID',
  `problem_id` varchar(255) NOT NULL COMMENT '问题的自定义ID，可作为唯一标识，例如YMOJ-1000（本题库），P1005（洛谷）等等',
  `title` varchar(255) NOT NULL COMMENT '题目标题',
  `content` text COMMENT '题目描述内容（题干）',
  `input` text COMMENT '输入描述',
  `output` text COMMENT '输出描述',
  `examples` text COMMENT '题面样例',
  `source` varchar(255) DEFAULT NULL COMMENT '题目来源说明，可为空，不参与判题',
  `difficulty` tinyint NOT NULL DEFAULT '1' COMMENT '难度：1=基础，2=进阶，3=挑战，4=高阶，5=大师',
  `judge_mode` varchar(16) NOT NULL DEFAULT 'default' COMMENT '判题方式：default=普通，spj=特殊；interactive暂不开放',
  `spj_language` varchar(8) DEFAULT NULL COMMENT 'SPJ语言：C++17 testlib',
  `spj_code` mediumtext DEFAULT NULL COMMENT '隐藏SPJ校验程序源码',
  `spj_digest` char(64) DEFAULT NULL COMMENT 'SPJ源码及编译协议摘要',
  `visibility` tinyint NOT NULL DEFAULT '2' COMMENT '可见性：1=公开，2=私有，3=比赛专属',
  `open_case_result` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否允许查看测试样例结果（0=否，1=是）',
  `time_limit` bigint NOT NULL DEFAULT '1000' COMMENT '时间限制（ms）',
  `memory_limit` bigint NOT NULL DEFAULT '65536' COMMENT '内存限制（KB）',
  `author_id` bigint unsigned DEFAULT NULL COMMENT '出题人ID（user.id）',
  `author_username` varchar(255) DEFAULT NULL COMMENT '出题人用户名',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `test_data_version_id` bigint DEFAULT NULL COMMENT '测试数据版本ID；NULL表示未绑定或历史版本未知',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `problem_id` (`problem_id`) USING BTREE,
  CONSTRAINT `chk_problem_difficulty` CHECK (`difficulty` BETWEEN 1 AND 5),
  CONSTRAINT `chk_problem_judge_mode` CHECK (`judge_mode` IN ('default','spj','interactive'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='题目表';

CREATE TABLE `problem_tag` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `problem_id` bigint unsigned NOT NULL COMMENT '题目ID',
  `tag_id` bigint unsigned NOT NULL COMMENT '标签ID',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_problem_tag` (`problem_id`,`tag_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='题目-标签关联表';

CREATE TABLE `test_data_version` (
  `id` bigint NOT NULL COMMENT '不可变版本ID（雪花ID）',
  `problem_id` bigint NOT NULL COMMENT '所属题目',
  `manifest` longtext NOT NULL COMMENT '排序后的测试点文件引用、大小和SHA-256',
  `manifest_sha256` char(64) NOT NULL COMMENT 'UTF-8清单SHA-256',
  `created_time` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_test_data_version_problem` (`problem_id`,`created_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='不可变测试数据版本与清单';

CREATE TABLE `contest` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '比赛ID',
  `creator_id` bigint unsigned DEFAULT NULL COMMENT '比赛创建者用户ID',
  `creator_username` varchar(255) DEFAULT NULL COMMENT '比赛创建者用户名或主办方',
  `image` varchar(512) DEFAULT NULL COMMENT '比赛Logo图片路径',
  `title` varchar(255) NOT NULL COMMENT '比赛标题',
  `description` text COMMENT '比赛说明内容',
  `source_id` bigint unsigned DEFAULT '0' COMMENT '来源比赛ID（0表示原创，其它为克隆赛ID）',
  `rated` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否计入Rating积分（0=否，1=是）',
  `mode` tinyint NOT NULL DEFAULT '0' COMMENT '赛制模式：0=ACM，1=OI，2=IOI；OI与IOI暂共用最高分规则',
  `style` tinyint NOT NULL DEFAULT '0' COMMENT '比赛类型：0=其他，1=周赛，2=月赛，3=娱乐赛，4=挑战赛',
  `visibility` tinyint NOT NULL DEFAULT '0' COMMENT '访问权限：0=公开，1=密码，2=私有',
  `password` varchar(255) DEFAULT NULL COMMENT '比赛密码（密码模式时使用）',
  `start_time` datetime DEFAULT NULL COMMENT '比赛开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '比赛结束时间',
  `duration` bigint DEFAULT NULL COMMENT '比赛时长（单位：分钟）',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='比赛表';

CREATE TABLE `contest_problem` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `display_id` varchar(255) NOT NULL COMMENT '该题目在比赛中的顺序id',
  `contest_id` bigint unsigned NOT NULL COMMENT '比赛id',
  `problem_id` bigint unsigned NOT NULL COMMENT '题目id',
  `display_title` varchar(255) NOT NULL COMMENT '该题目在比赛中的标题，默认为原名字',
  `color` varchar(255) DEFAULT NULL COMMENT '气球颜色',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_contest_display` (`contest_id`,`display_id`) USING BTREE,
  KEY `idx_contest_problem` (`contest_id`,`problem_id`) USING BTREE,
  KEY `idx_problem_contest` (`problem_id`,`contest_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='比赛题目表';

CREATE TABLE `contest_user` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `contest_id` bigint unsigned NOT NULL COMMENT '比赛ID',
  `user_id` bigint unsigned NOT NULL COMMENT '用户ID',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='比赛报名表';

CREATE TABLE `file` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '文件ID',
  `file_name` varchar(255) NOT NULL COMMENT '原始文件名，例如 data.zip',
  `file_type` varchar(50) DEFAULT NULL COMMENT '文件类型/MIME类型，例如 application/zip、image/png',
  `file_size` bigint unsigned DEFAULT '0' COMMENT '文件大小（字节）',
  `file_ext` varchar(50) DEFAULT NULL COMMENT '文件扩展名，例如 zip、png、pdf',
  `storage_path` varchar(500) NOT NULL COMMENT '文件存储相对路径，例如 upload/problem/1001/data.zip',
  `storage_type` tinyint NOT NULL DEFAULT '0' COMMENT '存储方式：0=本地，1=OSS，2=历史MinIO，3=S3兼容',
  `url` varchar(1000) DEFAULT NULL COMMENT '网站访问路径；私有文件通过鉴权接口读取',
  `uploader_id` bigint unsigned DEFAULT NULL COMMENT '上传者用户ID',
  `uploader_username` varchar(100) DEFAULT NULL COMMENT '上传者用户名',
  `biz_type` tinyint NOT NULL DEFAULT '0' COMMENT '业务类型：0=通用，1=题目附件，2=比赛附件，3=公告附件，4=图片，5=测试数据',
  `biz_id` bigint unsigned DEFAULT NULL COMMENT '业务ID，例如题目ID、比赛ID',
  `is_public` tinyint NOT NULL DEFAULT '1' COMMENT '是否公开访问：0=私有，1=公开',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '上传时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `storage_profile` varchar(64) DEFAULT NULL COMMENT '存储配置标识；local为本地，NULL兼容历史文件',
  `bucket` varchar(128) DEFAULT NULL COMMENT '对象存储桶；本地使用public/private目录',
  `object_key` varchar(500) DEFAULT NULL COMMENT '不可变对象键或本地相对路径',
  `sha256` char(64) DEFAULT NULL COMMENT '文件内容SHA-256；历史文件可为空',
  `legacy_path` varchar(1000) DEFAULT NULL COMMENT '迁移前路径，仅用于兼容与核验',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_file_public_url` (`is_public`,`url`(191)),
  KEY `idx_file_legacy_inventory` (`storage_type`,`storage_profile`,`id`),
  KEY `idx_file_storage_profile` (`storage_profile`),
  KEY `idx_file_url_guard` (`url`(191)),
  KEY `idx_file_business` (`biz_type`,`biz_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='文件信息表';

CREATE TABLE `judge` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '评测ID',
  `problem_id` bigint unsigned DEFAULT NULL COMMENT '题目ID',
  `problem_title` varchar(255) DEFAULT NULL COMMENT '题目标题',
  `display_id` varchar(100) DEFAULT NULL COMMENT '题目展示ID，例如 ABC100-A',
  `user_id` bigint unsigned NOT NULL COMMENT '用户ID',
  `username` varchar(100) DEFAULT NULL COMMENT '用户名',
  `language` varchar(100) NOT NULL COMMENT '编程语言名称',
  `code` longtext COMMENT '用户提交代码',
  `code_length` int DEFAULT NULL COMMENT '代码长度，单位：字符',
  `status` int DEFAULT '0' COMMENT '评测状态',
  `score` int DEFAULT NULL COMMENT '得分，ACM 模式为 NULL，OI 模式使用',
  `time` bigint DEFAULT '0' COMMENT '执行耗时(ms)',
  `memory` bigint DEFAULT '0' COMMENT '内存使用(KB)',
  `error_message` mediumtext COMMENT '编译错误/运行时错误信息',
  `share` tinyint NOT NULL DEFAULT '0' COMMENT '是否公开代码：0=私有，1=公开',
  `is_manual` tinyint NOT NULL DEFAULT '0' COMMENT '是否为人工评测记录：0=自动，1=人工',
  `contest_id` bigint unsigned NOT NULL DEFAULT '0' COMMENT '所属比赛ID，非比赛默认为0',
  `contest_problem_id` bigint unsigned DEFAULT '0' COMMENT '比赛题目ID',
  `judge_server` varchar(100) DEFAULT NULL COMMENT '执行判题的机器标识',
  `ip` varchar(255) DEFAULT NULL COMMENT '提交用户IP',
  `version` int DEFAULT '1' COMMENT '乐观锁版本号',
  `execution_id` varchar(36) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL COMMENT '当前评测执行标识；历史记录为空',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `test_data_version_id` bigint DEFAULT NULL COMMENT '测试数据版本ID；NULL表示未绑定或历史版本未知',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_created` (`user_id`,`created_time`) USING BTREE,
  KEY `idx_contest_created` (`contest_id`,`created_time`) USING BTREE,
  KEY `idx_contest_display_status` (`contest_id`,`display_id`,`status`) USING BTREE,
  KEY `idx_user_problem_contest` (`user_id`,`problem_id`,`contest_id`) USING BTREE,
  KEY `idx_status` (`status`) USING BTREE,
  KEY `idx_problem_id` (`problem_id`) USING BTREE,
  KEY `idx_contest_display_user_time` (`contest_id`,`created_time`,`display_id`,`user_id`,`status`),
  KEY `idx_judge_test_data_version` (`test_data_version_id`),
  CONSTRAINT `fk_judge_test_data_version` FOREIGN KEY (`test_data_version_id`)
    REFERENCES `test_data_version` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='判题记录表';

CREATE TABLE `judge_dispatch` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '持久化任务ID',
  `submission_id` bigint unsigned DEFAULT NULL COMMENT '与任务ID一致；仅同事务预分配时暂为空',
  `execution_id` varchar(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '执行标识，防止旧结果覆盖',
  `user_id` bigint unsigned NOT NULL COMMENT '任务所属用户',
  `strategy` int NOT NULL COMMENT '0正式提交；1自测',
  `problem_id` bigint unsigned DEFAULT NULL,
  `test_data_version_id` bigint DEFAULT NULL COMMENT '创建任务时固定的测试版本',
  `task_payload` longtext NOT NULL COMMENT '不可变消息快照，包含私有代码及自测输入',
  `result_payload` longtext DEFAULT NULL COMMENT '最近接收的有效结果',
  `dispatch_state` int NOT NULL DEFAULT 0 COMMENT '0待发布；1待结果；2已完成',
  `status` int NOT NULL DEFAULT 5,
  `last_result_sequence` int NOT NULL DEFAULT 0,
  `publish_attempts` int NOT NULL DEFAULT 0,
  `recovery_attempts` int NOT NULL DEFAULT 0,
  `next_attempt_time` datetime NOT NULL COMMENT '下次发布或恢复时间（UTC）',
  `published_time` datetime DEFAULT NULL COMMENT '最近发布时间（UTC）',
  `deadline_time` datetime NOT NULL COMMENT '任务总截止时间（UTC）',
  `lease_token` varchar(36) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  `lease_until` datetime DEFAULT NULL COMMENT '发布租约截止时间（UTC）',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_dispatch_submission` (`submission_id`),
  UNIQUE KEY `uniq_dispatch_execution` (`execution_id`),
  KEY `idx_dispatch_pending` (`dispatch_state`,`next_attempt_time`),
  KEY `idx_dispatch_deadline` (`dispatch_state`,`deadline_time`),
  KEY `idx_dispatch_version` (`test_data_version_id`),
  KEY `idx_dispatch_problem` (`problem_id`),
  CONSTRAINT `fk_dispatch_test_data_version` FOREIGN KEY (`test_data_version_id`)
    REFERENCES `test_data_version` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='可靠任务发布与结果幂等状态';

CREATE TABLE `judge_case` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '评测样例记录ID',
  `judge_id` bigint unsigned NOT NULL COMMENT '关联的判题记录ID（judge.id）',
  `case_index` int NOT NULL DEFAULT '1' COMMENT '样例在评测中的顺序编号（从1开始）',
  `status` tinyint NOT NULL DEFAULT '0' COMMENT '评测结果',
  `time` bigint DEFAULT NULL COMMENT '运行耗时(ms)',
  `memory` bigint DEFAULT NULL COMMENT '运行内存(KB)',
  `score` int DEFAULT NULL COMMENT '该样例得分（OI模式下有效）',
  `error_message` longtext COMMENT '运行错误信息（CE、RE、WA等时可能会有）',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '记录更新时间',
  `output` text COMMENT '用户程序输出（部分信息）',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_judge_id` (`judge_id`) USING BTREE,
  KEY `idx_judge_status` (`judge_id`,`status`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='判题样例结果表';

CREATE TABLE `user_acproblem` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `submission_id` bigint unsigned NOT NULL COMMENT '提交ID',
  `user_id` bigint unsigned NOT NULL COMMENT '用户ID',
  `username` varchar(50) NOT NULL COMMENT '用户名',
  `problem_id` bigint unsigned NOT NULL COMMENT '题目ID',
  `display_id` varchar(255) NOT NULL COMMENT '题目展示ID，例如 YMOJ-1001',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_problem` (`user_id`,`problem_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='用户已AC题目记录表';

CREATE TABLE `announcement` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '公告ID',
  `title` varchar(255) NOT NULL COMMENT '公告标题',
  `content` text NOT NULL COMMENT '公告内容（支持HTML/Markdown）',
  `priority` int NOT NULL DEFAULT '0' COMMENT '公告权重（值越大越靠前）',
  `pinned` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否置顶：1=置顶，0=不置顶',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '1可见，0不可见',
  `author_id` bigint unsigned DEFAULT NULL COMMENT '发布人ID',
  `author_username` varchar(255) DEFAULT NULL COMMENT '发布人用户名',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='公告表';

CREATE TABLE `storage_config` (
  `id` varchar(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '配置标识',
  `name` varchar(100) NOT NULL COMMENT '配置名称',
  `provider` varchar(16) NOT NULL COMMENT 'seaweedfs/minio/aliyun/s3',
  `endpoint` varchar(512) NOT NULL COMMENT '后端可达的存储服务地址',
  `region` varchar(64) NOT NULL COMMENT 'S3地域标识',
  `public_bucket` varchar(128) NOT NULL COMMENT '公开业务文件桶；桶自身保持私有',
  `private_bucket` varchar(128) NOT NULL COMMENT '私有业务文件桶',
  `path_style` tinyint NOT NULL DEFAULT '1' COMMENT '1=路径式访问，0=虚拟主机式访问',
  `encrypted_access_key` text NOT NULL COMMENT 'AES-GCM加密的访问标识',
  `encrypted_secret_key` text NOT NULL COMMENT 'AES-GCM加密的访问密钥',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `revision` bigint NOT NULL DEFAULT '1' COMMENT '配置修订号，用于并发控制',
  `tested_revision` bigint DEFAULT NULL COMMENT '最近测试通过的修订号',
  `tested_at` datetime DEFAULT NULL COMMENT '最近测试通过时间',
  `created_time` datetime NOT NULL COMMENT '创建时间',
  `updated_time` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='命名存储配置，凭据独立加密';

CREATE TABLE `storage_config_state` (
  `id` tinyint NOT NULL COMMENT '单例ID，固定为1',
  `active_key` varchar(64) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL COMMENT '默认存储标识，local为内置本地存储',
  `revision` bigint NOT NULL DEFAULT '0' COMMENT '配置修订号，用于并发控制',
  `updated_time` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='默认存储配置与并发控制';

START TRANSACTION;

INSERT INTO `user` (`id`, `username`, `password`, `nickname`, `sex`, `email`, `status`) VALUES
    (1, 'admin', '$2a$10$20LHKKmhqgI14NC//MgE8eFHMWO6FvnH7piPZYYGrVGYkmjNPMJzC', '超级管理员', 0, 'admin@example.invalid', 1);

INSERT INTO `role` (`id`, `code`, `name`, `description`, `status`, `built_in`) VALUES
    (1, 'USER', '普通用户', '使用题库、比赛及提交功能，无后台权限', 1, 1),
    (2, 'ADMIN', '普通管理员', '管理全站题目与比赛，不能分配管理角色', 1, 1),
    (3, 'PROBLEM_SETTER', '出题人', '访问非专属题目，管理本人原题及测试数据', 1, 1),
    (4, 'CONTEST_MANAGER', '比赛管理员', '包含出题人能力，管理及重评本人比赛', 1, 1);

INSERT INTO `user_role` (`user_id`, `role_id`) VALUES
    (1, 2);

INSERT INTO `auth` (`id`, `code`, `name`, `parent_id`, `path`, `route_name`, `component`, `icon`, `type`, `status`, `built_in`) VALUES
    (1, NULL, '系统监控', 0, '/admin/monitor', 'AdminMonitor', 'Layout', 'Monitor', 'M', 1, 1),
    (2, NULL, '用户管理', 0, '/admin/user', 'AdminUser', 'Layout', 'User', 'M', 1, 1),
    (3, NULL, '题目管理', 0, '/admin/problem', 'AdminProblem', 'Layout', 'Tickets', 'M', 1, 1),
    (4, NULL, '比赛管理', 0, '/admin/contest', 'AdminContest', 'Layout', 'Trophy', 'M', 1, 1),
    (5, NULL, '公告管理', 0, '/admin/announcement', 'AdminAnnouncement', 'Layout', 'Bell', 'M', 1, 1),
    (11, 'monitor:server:list', '服务监控', 1, 'server', 'AdminServerMonitor', 'admin/monitor/Server', NULL, 'C', 1, 1),
    (12, 'monitor:online:list', '在线用户', 1, 'user-online', 'AdminUserOnline', 'admin/monitor/UserOnline', NULL, 'C', 1, 1),
    (21, 'user:user:list', '用户列表', 2, 'list', 'AdminUserList', 'admin/user/UserList', NULL, 'C', 1, 1),
    (31, 'problem:problem:list', '题目列表', 3, 'list', 'AdminProblemList', 'admin/problem/ProblemList', NULL, 'C', 1, 1),
    (32, 'problem:problem:add', '新增题目', 3, 'add', 'AdminAddProblem', 'admin/problem/Problem', NULL, 'C', 1, 1),
    (33, 'problem:tag:list', '标签管理', 3, 'tag', 'AdminTagEdit', 'admin/problem/Tag', NULL, 'C', 1, 1),
    (41, 'contest:contest:list', '比赛列表', 4, 'list', 'AdminContestList', 'admin/contest/ContestList', NULL, 'C', 1, 1),
    (42, 'contest:contest:add', '新增比赛', 4, 'add', 'AdminContestAdd', 'admin/contest/Contest', NULL, 'C', 1, 1),
    (51, 'announcement:announcement:list', '公告列表', 5, 'list', 'AdminAnnouncementList', 'admin/announcement/AnnouncementList', NULL, 'C', 1, 1),
    (111, 'monitor:online:forceLogout', '强制退出', 12, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (211, 'user:user:query', '用户查询', 21, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (212, 'user:user:add', '用户新增', 21, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (213, 'user:user:edit', '用户编辑', 21, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (214, 'user:user:remove', '用户删除', 21, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (311, 'problem:problem:query', '题目查询', 31, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (312, 'problem:problem:edit', '题目编辑', 31, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (314, 'problem:problem:publish', '调整题目公开状态', 31, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (548, 'system:submission:rejudge', '重新评测提交', 31, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (549, 'system:submission:edit', '手动改判（仅超级管理员）', 31, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (313, 'problem:problem:remove', '题目删除', 31, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (331, 'problem:tag:add', '标签新增', 33, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (332, 'problem:tag:edit', '标签编辑', 33, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (333, 'problem:tag:remove', '标签删除', 33, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (341, 'problem:testcase:query', '样例查询', 31, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (342, 'problem:testcase:add', '样例新增', 31, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (343, 'problem:testcase:remove', '样例删除', 31, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (411, 'contest:contest:query', '比赛查询', 41, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (412, 'contest:contest:edit', '比赛编辑', 41, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (413, 'contest:contest:remove', '比赛删除', 41, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (421, 'contest:problem:list', '比赛题目列表', 42, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (422, 'contest:problem:add', '比赛题目新增', 42, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (423, 'contest:problem:edit', '比赛题目编辑', 42, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (424, 'contest:problem:remove', '比赛题目删除', 42, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (511, 'announcement:announcement:query', '公告查询', 51, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (512, 'announcement:announcement:add', '公告新增', 51, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (513, 'announcement:announcement:edit', '公告编辑', 51, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (514, 'announcement:announcement:remove', '公告删除', 51, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (515, NULL, '常用设置', 0, '/admin/common', 'AdminCommon', 'Layout', 'Setting', 'M', 1, 1),
    (516, 'system:setting:list', '系统配置', 515, 'system-setting', 'AdminSystemSetting', 'admin/common/SystemSetting', NULL, 'C', 1, 1),
    (517, 'system:setting:edit', '修改系统配置', 516, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (518, 'admin:access', '进入管理后台', 0, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (519, 'system:role:list', '角色管理', 515, 'role', 'AdminRoleList', 'admin/common/RoleList', NULL, 'C', 1, 1),
    (520, 'system:role:query', '查询角色', 519, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (521, 'system:role:add', '新增角色', 519, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (522, 'system:role:edit', '修改角色', 519, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (523, 'system:role:remove', '删除角色', 519, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (524, 'system:role:auth', '分配角色权限', 519, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (527, 'system:auth:list', '菜单权限', 515, 'auth', 'AdminAuthList', 'admin/common/AuthList', NULL, 'C', 1, 1),
    (528, 'system:auth:add', '新增菜单权限', 527, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (529, 'system:auth:edit', '修改菜单权限', 527, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (530, 'system:auth:remove', '删除菜单权限', 527, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (531, 'user:user:role', '分配用户角色', 21, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (532, 'file:file:list', '文件管理', 515, 'file', 'AdminFileManage', 'admin/common/FileManage', NULL, 'C', 1, 1),
    (533, 'file:file:download', '下载文件', 532, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (534, 'file:file:upload', '上传通用文件', 532, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (535, 'file:file:remove', '删除无关联通用文件', 532, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (536, 'file:file:private', '访问私有通用文件', 532, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (540, 'file:storage:list', '存储配置', 515, 'storage-config', 'AdminStorageConfig', 'admin/common/StorageConfig', NULL, 'C', 1, 1),
    (541, 'file:storage:add', '新增存储配置（仅超级管理员）', 540, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (542, 'file:storage:edit', '修改存储配置（仅超级管理员）', 540, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (543, 'file:storage:remove', '删除存储配置（仅超级管理员）', 540, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (544, 'file:storage:test', '测试存储连接（仅超级管理员）', 540, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (545, 'file:storage:activate', '启用默认存储（仅超级管理员）', 540, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (546, 'file:migration:query', '查看文件迁移盘点', 532, NULL, NULL, NULL, NULL, 'F', 1, 1),
    (547, 'file:migration:execute', '执行历史文件迁移', 532, NULL, NULL, NULL, NULL, 'F', 1, 1);

INSERT INTO `role_auth` (`role_id`, `auth_id`) VALUES
    (2, 1),
    (2, 2),
    (2, 3),
    (2, 4),
    (2, 5),
    (2, 11),
    (2, 12),
    (2, 21),
    (2, 31),
    (2, 32),
    (2, 33),
    (2, 41),
    (2, 42),
    (2, 51),
    (2, 111),
    (2, 211),
    (2, 212),
    (2, 213),
    (2, 214),
    (2, 311),
    (2, 312),
    (2, 313),
    (2, 314),
    (2, 548),
    (2, 331),
    (2, 332),
    (2, 333),
    (2, 341),
    (2, 342),
    (2, 343),
    (2, 411),
    (2, 412),
    (2, 413),
    (2, 421),
    (2, 422),
    (2, 423),
    (2, 424),
    (2, 511),
    (2, 512),
    (2, 513),
    (2, 514),
    (2, 515),
    (2, 516),
    (2, 517),
    (2, 518),
    (2, 532),
    (2, 533),
    (2, 534),
    (2, 535),
    (2, 536),
    (2, 540),
    (2, 546),
    (2, 547),
    (3, 3),
    (3, 31),
    (3, 32),
    (3, 33),
    (3, 311),
    (3, 312),
    (3, 313),
    (3, 331),
    (3, 332),
    (3, 333),
    (3, 341),
    (3, 342),
    (3, 343),
    (3, 515),
    (3, 518),
    (3, 532),
    (4, 3),
    (4, 31),
    (4, 32),
    (4, 33),
    (4, 311),
    (4, 312),
    (4, 313),
    (4, 331),
    (4, 332),
    (4, 333),
    (4, 341),
    (4, 342),
    (4, 343),
    (4, 515),
    (4, 518),
    (4, 532),
    (4, 4),
    (4, 41),
    (4, 42),
    (4, 411),
    (4, 412),
    (4, 413),
    (4, 421),
    (4, 422),
    (4, 423),
    (4, 424),
    (4, 548);

INSERT INTO `language` (`id`, `name`, `image`, `env`, `version`, `content_type`, `file_name`, `file_extension`, `compile_cmd`, `run_cmd`, `template_code`, `code_template`, `type`, `status`, `oj`) VALUES
    (1, 'C++', 'go-judge:v1.13.3', 'debian12-toolchains', 'G++ 12.2.0 (C++17)', 'text/x-c++src', 'main.cpp', '.cpp', 'g++ -O2 -w -fmax-errors=3 -std=c++17 main.cpp -lm -o main', './main', '#include <iostream>
using namespace std;
int main() {
    int a, b;
    cin >> a >> b;
    cout << a + b << endl;
    return 0;
}', NULL, 0, 1, 'myy'),
    (2, 'C', 'go-judge:v1.13.3', 'debian12-toolchains', 'GCC 12.2.0 (C11)', 'text/x-csrc', 'main.c', '.c', 'gcc -O2 -w -fmax-errors=3 -std=c11 main.c -lm -o main', './main', '#include <stdio.h>
int main() {
    int a, b;
    scanf("%d %d", &a, &b);
    printf("%d\\n", a + b);
    return 0;
}', NULL, 0, 1, 'myy'),
    (3, 'Java', 'go-judge:v1.13.3', 'debian12-toolchains', 'OpenJDK 17.0.20.1', 'text/x-java', 'Main.java', '.java', 'javac -encoding UTF8 Main.java', 'java Main', 'public class Main {
    public static void main(String[] args) throws Exception {
        java.util.Scanner sc = new java.util.Scanner(System.in);
        int a = sc.nextInt(), b = sc.nextInt();
        System.out.println(a + b);
    }
}', NULL, 0, 1, 'myy'),
    (4, 'Python', 'go-judge:v1.13.3', 'debian12-toolchains', 'Python 3.11.2', 'text/x-python', 'main.py', '.py', 'python3 -m py_compile main.py', 'python3 main.py', 'a, b = map(int, input().split())
print(a + b)', NULL, 1, 1, 'myy');

INSERT INTO `system_setting` (`setting_key`, `setting_value`) VALUES
    ('register_enabled', 'true');

INSERT INTO `storage_config_state` (`id`, `active_key`, `revision`, `updated_time`)
VALUES (1, 'local', 0, CURRENT_TIMESTAMP);

COMMIT;
