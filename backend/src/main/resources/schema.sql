-- ============================================================
-- 卡码笔记 (kamanotes) 数据库初始化脚本
-- 数据库: kamanote_tech
-- 根据后端实体类 + MyBatis Mapper 推导生成
-- ============================================================

CREATE DATABASE IF NOT EXISTS `kamanote_tech`
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_general_ci;

USE `kamanote_tech`;

SET NAMES utf8mb4;

-- ----------------------------
-- 用户表
-- ----------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
    `user_id`       BIGINT       NOT NULL AUTO_INCREMENT COMMENT '用户ID',
    `account`       VARCHAR(64)  NOT NULL COMMENT '账号（唯一）',
    `username`      VARCHAR(64)  DEFAULT NULL COMMENT '用户名',
    `password`      VARCHAR(255) NOT NULL COMMENT '加密后的登录密码',
    `gender`        INT          DEFAULT 3 COMMENT '性别 1=男 2=女 3=保密',
    `birthday`      DATE         DEFAULT NULL COMMENT '生日',
    `avatar_url`    VARCHAR(255) DEFAULT NULL COMMENT '头像地址',
    `email`         VARCHAR(128) DEFAULT NULL COMMENT '邮箱',
    `school`        VARCHAR(128) DEFAULT NULL COMMENT '学校',
    `signature`     VARCHAR(255) DEFAULT NULL COMMENT '签名',
    `is_banned`     INT          DEFAULT 0 COMMENT '封禁状态 0=未封禁 1=已封禁',
    `is_admin`      INT          DEFAULT 0 COMMENT '管理员状态 0=普通 1=管理员',
    `last_login_at` DATETIME     DEFAULT NULL COMMENT '最后登录时间',
    `created_at`    DATETIME     DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`    DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`user_id`),
    UNIQUE KEY `uk_account` (`account`),
    UNIQUE KEY `uk_email` (`email`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '用户表';

-- ----------------------------
-- 分类表
-- ----------------------------
DROP TABLE IF EXISTS `category`;
CREATE TABLE `category` (
    `category_id`       INT          NOT NULL AUTO_INCREMENT COMMENT '分类ID',
    `name`              VARCHAR(64)  NOT NULL COMMENT '分类名称',
    `parent_category_id` INT         DEFAULT 0 COMMENT '上级分类ID，0=一级分类',
    `created_at`        DATETIME     DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`        DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`category_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '分类表';

-- ----------------------------
-- 题目表
-- ----------------------------
DROP TABLE IF EXISTS `question`;
CREATE TABLE `question` (
    `question_id` INT          NOT NULL AUTO_INCREMENT COMMENT '题目ID',
    `category_id` INT          DEFAULT NULL COMMENT '分类ID',
    `title`       VARCHAR(255) NOT NULL COMMENT '题目标题',
    `difficulty`  INT          DEFAULT 1 COMMENT '难度 1=简单 2=中等 3=困难',
    `exam_point`  VARCHAR(255) DEFAULT NULL COMMENT '考点',
    `description` TEXT         DEFAULT NULL COMMENT '题目描述',
    `view_count`  INT          DEFAULT 0 COMMENT '浏览量',
    `created_at`  DATETIME     DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`  DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`question_id`),
    KEY `idx_category_id` (`category_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '题目表';

-- ----------------------------
-- 题单表
-- ----------------------------
DROP TABLE IF EXISTS `question_list`;
CREATE TABLE `question_list` (
    `question_list_id` INT          NOT NULL AUTO_INCREMENT COMMENT '题单ID',
    `name`             VARCHAR(128) NOT NULL COMMENT '题单名称',
    `type`             INT          DEFAULT NULL COMMENT '题单类型',
    `description`      VARCHAR(255) DEFAULT NULL COMMENT '题单描述',
    `created_at`       DATETIME     DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`       DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`question_list_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '题单表';

-- ----------------------------
-- 题单-题目关联表
-- ----------------------------
DROP TABLE IF EXISTS `question_list_item`;
CREATE TABLE `question_list_item` (
    `question_list_id` INT      NOT NULL COMMENT '题单ID',
    `question_id`      INT      NOT NULL COMMENT '题目ID',
    `rank`             INT      DEFAULT 1 COMMENT '题单内顺序，从1开始',
    `created_at`       DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`       DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`question_list_id`, `question_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '题单-题目关联表';

-- ----------------------------
-- 笔记分类表（笔记专属分类，如 Redis / SQL / MQ，独立于题目分类 category）
-- ----------------------------
DROP TABLE IF EXISTS `note_category`;
CREATE TABLE `note_category` (
    `category_id` INT         NOT NULL AUTO_INCREMENT COMMENT '笔记分类ID',
    `name`        VARCHAR(64) NOT NULL COMMENT '分类名称',
    `created_at`  DATETIME    DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`  DATETIME    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`category_id`),
    UNIQUE KEY `uk_name` (`name`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '笔记分类表';

-- ----------------------------
-- 笔记表
-- ----------------------------
DROP TABLE IF EXISTS `note`;
CREATE TABLE `note` (
    `note_id`        INT      NOT NULL AUTO_INCREMENT COMMENT '笔记ID',
    `author_id`      BIGINT   NOT NULL COMMENT '作者ID',
    `question_id`    INT      DEFAULT NULL COMMENT '题目ID（为空表示不绑定题目的分类笔记）',
    `category_id`    INT      DEFAULT NULL COMMENT '笔记分类ID（为空表示绑定题目的笔记）',
    `content`        LONGTEXT COMMENT '笔记内容（Markdown）',
    `like_count`     INT      DEFAULT 0 COMMENT '点赞数',
    `comment_count`  INT      DEFAULT 0 COMMENT '评论数',
    `collect_count`  INT      DEFAULT 0 COMMENT '收藏数',
    `search_vector`  TEXT     COMMENT '全文检索向量',
    `created_at`     DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`     DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`note_id`),
    KEY `idx_author_id` (`author_id`),
    KEY `idx_question_id` (`question_id`),
    KEY `idx_category_id` (`category_id`),
    -- 全文索引必须使用 ngram 分词器，否则 MySQL 默认分词器不切分中文
    -- （整段中文会成为超长 token 而不被索引），中文检索将永远查不到结果
    FULLTEXT KEY `ft_search_vector` (`search_vector`) WITH PARSER ngram
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '笔记表';

-- ----------------------------
-- 笔记点赞表
-- ----------------------------
DROP TABLE IF EXISTS `note_like`;
CREATE TABLE `note_like` (
    `note_id`    INT      NOT NULL COMMENT '笔记ID',
    `user_id`    BIGINT   NOT NULL COMMENT '用户ID',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`note_id`, `user_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '笔记点赞表';

-- ----------------------------
-- 笔记收藏表
-- ----------------------------
DROP TABLE IF EXISTS `note_collect`;
CREATE TABLE `note_collect` (
    `collect_id` INT      NOT NULL AUTO_INCREMENT COMMENT '收藏ID',
    `note_id`    INT      NOT NULL COMMENT '笔记ID',
    `user_id`    BIGINT   NOT NULL COMMENT '用户ID',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`collect_id`),
    UNIQUE KEY `uk_note_user` (`note_id`, `user_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '笔记收藏表';

-- ----------------------------
-- 收藏夹表
-- ----------------------------
DROP TABLE IF EXISTS `collection`;
CREATE TABLE `collection` (
    `collection_id` INT          NOT NULL AUTO_INCREMENT COMMENT '收藏夹ID',
    `name`          VARCHAR(128) NOT NULL COMMENT '收藏夹名称',
    `description`   VARCHAR(255) DEFAULT NULL COMMENT '收藏夹描述',
    `creator_id`    BIGINT       NOT NULL COMMENT '创建者ID',
    `created_at`    DATETIME     DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`    DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`collection_id`),
    KEY `idx_creator_id` (`creator_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '收藏夹表';

-- ----------------------------
-- 收藏夹-笔记关联表
-- ----------------------------
DROP TABLE IF EXISTS `collection_note`;
CREATE TABLE `collection_note` (
    `collection_id` INT      NOT NULL COMMENT '收藏夹ID',
    `note_id`       INT      NOT NULL COMMENT '笔记ID',
    `created_at`    DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`    DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`collection_id`, `note_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '收藏夹-笔记关联表';

-- ----------------------------
-- 评论表
-- ----------------------------
DROP TABLE IF EXISTS `comment`;
CREATE TABLE `comment` (
    `comment_id`  INT      NOT NULL AUTO_INCREMENT COMMENT '评论ID',
    `note_id`     INT      NOT NULL COMMENT '笔记ID',
    `author_id`   BIGINT   NOT NULL COMMENT '作者ID',
    `parent_id`   INT      DEFAULT NULL COMMENT '父评论ID',
    `content`     TEXT     COMMENT '评论内容',
    `like_count`  INT      DEFAULT 0 COMMENT '点赞数',
    `reply_count` INT      DEFAULT 0 COMMENT '回复数',
    `created_at`  DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`comment_id`),
    KEY `idx_note_id` (`note_id`),
    KEY `idx_author_id` (`author_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '评论表';

-- ----------------------------
-- 评论点赞表
-- ----------------------------
DROP TABLE IF EXISTS `comment_like`;
CREATE TABLE `comment_like` (
    `comment_like_id` INT      NOT NULL AUTO_INCREMENT COMMENT '评论点赞ID',
    `comment_id`      INT      NOT NULL COMMENT '评论ID',
    `user_id`         BIGINT   NOT NULL COMMENT '用户ID',
    `created_at`      DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`comment_like_id`),
    UNIQUE KEY `uk_comment_user` (`comment_id`, `user_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '评论点赞表';

-- ----------------------------
-- 消息表
-- ----------------------------
DROP TABLE IF EXISTS `message`;
CREATE TABLE `message` (
    `message_id`  INT          NOT NULL AUTO_INCREMENT COMMENT '消息ID',
    `receiver_id` BIGINT       NOT NULL COMMENT '接收者ID',
    `sender_id`   BIGINT       NOT NULL COMMENT '发送者ID',
    `type`        INT          DEFAULT NULL COMMENT '消息类型',
    `target_id`   INT          DEFAULT NULL COMMENT '目标ID',
    `target_type` INT          DEFAULT NULL COMMENT '目标类型',
    `content`     TEXT         COMMENT '消息内容',
    `is_read`     TINYINT(1)   DEFAULT 0 COMMENT '是否已读',
    `created_at`  DATETIME     DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`  DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`message_id`),
    KEY `idx_receiver_id` (`receiver_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '消息表';

-- ----------------------------
-- 统计信息表
-- ----------------------------
DROP TABLE IF EXISTS `statistic`;
CREATE TABLE `statistic` (
    `id`                   INT  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `login_count`          INT  DEFAULT 0 COMMENT '当天登录次数',
    `register_count`       INT  DEFAULT 0 COMMENT '当天注册人数',
    `total_register_count` INT  DEFAULT 0 COMMENT '累计注册总人数',
    `note_count`           INT  DEFAULT 0 COMMENT '当天笔记数量',
    `submit_note_count`    INT  DEFAULT 0 COMMENT '当天提交笔记数量',
    `total_note_count`     INT  DEFAULT 0 COMMENT '累计笔记总数量',
    `date`                 DATE DEFAULT NULL COMMENT '统计日期',
    PRIMARY KEY (`id`),
    -- 每个日期只允许一条统计记录，
    -- 配合 INSERT ... ON DUPLICATE KEY UPDATE 保证定时任务重复执行也不会产生重复行
    UNIQUE KEY `uk_date` (`date`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '统计信息表';
