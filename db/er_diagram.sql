-- ============================================================================
--  卡码笔记（kamanotes）数据库 DDL —— 用于生成 ER 图
-- ============================================================================
--  数据库：kamanote_tech（MySQL 8.0）
--  来源  ：从当前真实数据库 mysqldump 导出，字段类型 / 约束 / 注释 与线上完全一致
--
--  【重要说明】
--  1. 原数据库**没有建立任何外键约束**，只有普通索引。ER 图工具通常靠外键来
--     推断表间关系，因此本文件在 CREATE TABLE 中**补充了 FOREIGN KEY 约束**
--     （共 20 条），以便 ER 工具自动连线。
--  2. 因此本文件适用于「建模 / 出图」，**不建议直接当作生产建表脚本使用**：
--     加了外键后，像「删除分类时级联删除题目」这类操作会被外键阻止。
--     应用真实使用的建表脚本是：backend/src/main/resources/schema.sql
--  3. 表内 AUTO_INCREMENT 计数器（当前各表的值）已省略，属数据状态而非表结构。
--  4. CREATE TABLE 顺序已按外键依赖排列（被引用表在前）。
--  5. 索引与原库完全一致；外键所需的辅助索引由 MySQL 自动创建，未手工列出。
-- ============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE DATABASE IF NOT EXISTS `kamanote_tech`
    DEFAULT CHARACTER SET utf8mb4
    COLLATE utf8mb4_general_ci;

USE `kamanote_tech`;

-- ============================================================================
-- 1. 用户表
-- ============================================================================
CREATE TABLE `user` (
    `user_id`        BIGINT       NOT NULL AUTO_INCREMENT COMMENT '用户ID',
    `account`        VARCHAR(64)  NOT NULL COMMENT '账号（唯一）',
    `username`       VARCHAR(64)  DEFAULT NULL COMMENT '用户名',
    `password`       VARCHAR(255) NOT NULL COMMENT '加密后的登录密码',
    `gender`         INT          DEFAULT 3 COMMENT '性别 1=男 2=女 3=保密',
    `birthday`       DATE         DEFAULT NULL COMMENT '生日',
    `avatar_url`     VARCHAR(255) DEFAULT NULL COMMENT '头像地址',
    `email`          VARCHAR(128) DEFAULT NULL COMMENT '邮箱',
    `school`         VARCHAR(128) DEFAULT NULL COMMENT '学校',
    `signature`      VARCHAR(255) DEFAULT NULL COMMENT '签名',
    `is_banned`      INT          DEFAULT 0 COMMENT '封禁状态 0=未封禁 1=已封禁',
    `is_admin`       INT          DEFAULT 0 COMMENT '管理员状态 0=普通 1=管理员',
    `last_login_at`  DATETIME     DEFAULT NULL COMMENT '最后登录时间',
    `created_at`     DATETIME     DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`     DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`user_id`),
    UNIQUE KEY `uk_account` (`account`),
    UNIQUE KEY `uk_email` (`email`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '用户表';

-- ============================================================================
-- 2. 题目分类表（算法分类：数组 / 链表 / 字符串 ...）
-- ============================================================================
CREATE TABLE `category` (
    `category_id`        INT         NOT NULL AUTO_INCREMENT COMMENT '分类ID',
    `name`               VARCHAR(64) NOT NULL COMMENT '分类名称',
    `parent_category_id` INT         DEFAULT 0 COMMENT '上级分类ID，0=一级分类',
    `created_at`         DATETIME    DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`         DATETIME    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`category_id`)
    -- 自关联：category.parent_category_id -> category.category_id
    -- 业务上用 0 表示「一级分类（无父级）」，直接加外键会因找不到 category_id=0 的行而插入失败，
    -- 故此处默认注释。若你的 ER 工具需要画出这条自关联，在下面加一行（MySQL 会自动建索引）：
    -- , CONSTRAINT `fk_category_parent` FOREIGN KEY (`parent_category_id`) REFERENCES `category` (`category_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '题目分类表';

-- ============================================================================
-- 3. 笔记分类表（技术主题分类：Redis / SQL / MQ ...，独立于题目分类）
-- ============================================================================
CREATE TABLE `note_category` (
    `category_id` INT         NOT NULL AUTO_INCREMENT COMMENT '笔记分类ID',
    `name`        VARCHAR(64) NOT NULL COMMENT '分类名称',
    `created_at`  DATETIME    DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`  DATETIME    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`category_id`),
    UNIQUE KEY `uk_name` (`name`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '笔记分类表';

-- ============================================================================
-- 4. 题目表
-- ============================================================================
CREATE TABLE `question` (
    `question_id` INT          NOT NULL AUTO_INCREMENT COMMENT '题目ID',
    `category_id` INT          DEFAULT NULL COMMENT '分类ID',
    `title`       VARCHAR(255) NOT NULL COMMENT '题目标题',
    `difficulty`  INT          DEFAULT 1 COMMENT '难度 1=简单 2=中等 3=困难',
    `exam_point`  VARCHAR(255) DEFAULT NULL COMMENT '考点',
    `description` TEXT         COMMENT '题目描述',
    `view_count`  INT          DEFAULT 0 COMMENT '浏览量',
    `created_at`  DATETIME     DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`  DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`question_id`),
    KEY `idx_category_id` (`category_id`),
    CONSTRAINT `fk_question_category` FOREIGN KEY (`category_id`) REFERENCES `category` (`category_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '题目表';

-- ============================================================================
-- 5. 题单表
-- ============================================================================
CREATE TABLE `question_list` (
    `question_list_id` INT          NOT NULL AUTO_INCREMENT COMMENT '题单ID',
    `name`             VARCHAR(128) NOT NULL COMMENT '题单名称',
    `type`             INT          DEFAULT NULL COMMENT '题单类型',
    `description`      VARCHAR(255) DEFAULT NULL COMMENT '题单描述',
    `created_at`       DATETIME     DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`       DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`question_list_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '题单表';

-- ============================================================================
-- 6. 笔记表
--    question_id 与 category_id 二选一：
--      question_id 非空 -> 题目笔记；category_id 非空 -> 分类笔记
-- ============================================================================
CREATE TABLE `note` (
    `note_id`       INT      NOT NULL AUTO_INCREMENT COMMENT '笔记ID',
    `author_id`     BIGINT   NOT NULL COMMENT '作者ID',
    `question_id`   INT      DEFAULT NULL COMMENT '题目ID',
    `category_id`   INT      DEFAULT NULL COMMENT '笔记分类ID（为空表示题目笔记）',
    `content`       LONGTEXT COMMENT '笔记内容（Markdown）',
    `like_count`    INT      DEFAULT 0 COMMENT '点赞数',
    `comment_count` INT      DEFAULT 0 COMMENT '评论数',
    `collect_count` INT      DEFAULT 0 COMMENT '收藏数',
    `search_vector` TEXT     COMMENT '全文检索向量',
    `created_at`    DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`    DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`note_id`),
    KEY `idx_author_id` (`author_id`),
    KEY `idx_question_id` (`question_id`),
    KEY `idx_category_id` (`category_id`),
    FULLTEXT KEY `ft_search_vector` (`search_vector`) WITH PARSER ngram,
    CONSTRAINT `fk_note_author`   FOREIGN KEY (`author_id`)   REFERENCES `user` (`user_id`),
    CONSTRAINT `fk_note_question` FOREIGN KEY (`question_id`) REFERENCES `question` (`question_id`),
    CONSTRAINT `fk_note_category` FOREIGN KEY (`category_id`) REFERENCES `note_category` (`category_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '笔记表';

-- ============================================================================
-- 7. 评论表（parent_id 支持二级回复）
-- ============================================================================
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
    KEY `idx_author_id` (`author_id`),
    CONSTRAINT `fk_comment_note`   FOREIGN KEY (`note_id`)   REFERENCES `note` (`note_id`),
    CONSTRAINT `fk_comment_author` FOREIGN KEY (`author_id`) REFERENCES `user` (`user_id`),
    CONSTRAINT `fk_comment_parent` FOREIGN KEY (`parent_id`) REFERENCES `comment` (`comment_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '评论表';

-- ============================================================================
-- 8. 收藏夹表
-- ============================================================================
CREATE TABLE `collection` (
    `collection_id` INT          NOT NULL AUTO_INCREMENT COMMENT '收藏夹ID',
    `name`          VARCHAR(128) NOT NULL COMMENT '收藏夹名称',
    `description`   VARCHAR(255) DEFAULT NULL COMMENT '收藏夹描述',
    `creator_id`    BIGINT       NOT NULL COMMENT '创建者ID',
    `created_at`    DATETIME     DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`    DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`collection_id`),
    KEY `idx_creator_id` (`creator_id`),
    CONSTRAINT `fk_collection_creator` FOREIGN KEY (`creator_id`) REFERENCES `user` (`user_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '收藏夹表';

-- ============================================================================
-- 9. 笔记点赞表（note × user 多对多）
-- ============================================================================
CREATE TABLE `note_like` (
    `note_id`    INT      NOT NULL COMMENT '笔记ID',
    `user_id`    BIGINT   NOT NULL COMMENT '用户ID',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`note_id`, `user_id`),
    CONSTRAINT `fk_note_like_note` FOREIGN KEY (`note_id`) REFERENCES `note` (`note_id`),
    CONSTRAINT `fk_note_like_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '笔记点赞表';

-- ============================================================================
-- 10. 笔记收藏表（note × user 多对多，直接收藏，不经收藏夹）
-- ============================================================================
CREATE TABLE `note_collect` (
    `collect_id` INT      NOT NULL AUTO_INCREMENT COMMENT '收藏ID',
    `note_id`    INT      NOT NULL COMMENT '笔记ID',
    `user_id`    BIGINT   NOT NULL COMMENT '用户ID',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`collect_id`),
    UNIQUE KEY `uk_note_user` (`note_id`, `user_id`),
    CONSTRAINT `fk_note_collect_note` FOREIGN KEY (`note_id`) REFERENCES `note` (`note_id`),
    CONSTRAINT `fk_note_collect_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '笔记收藏表';

-- ============================================================================
-- 11. 评论点赞表（comment × user 多对多）
-- ============================================================================
CREATE TABLE `comment_like` (
    `comment_like_id` INT      NOT NULL AUTO_INCREMENT COMMENT '评论点赞ID',
    `comment_id`      INT      NOT NULL COMMENT '评论ID',
    `user_id`         BIGINT   NOT NULL COMMENT '用户ID',
    `created_at`      DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`comment_like_id`),
    UNIQUE KEY `uk_comment_user` (`comment_id`, `user_id`),
    CONSTRAINT `fk_comment_like_comment` FOREIGN KEY (`comment_id`) REFERENCES `comment` (`comment_id`),
    CONSTRAINT `fk_comment_like_user`    FOREIGN KEY (`user_id`)    REFERENCES `user` (`user_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '评论点赞表';

-- ============================================================================
-- 12. 收藏夹-笔记关联表（collection × note 多对多）
-- ============================================================================
CREATE TABLE `collection_note` (
    `collection_id` INT      NOT NULL COMMENT '收藏夹ID',
    `note_id`       INT      NOT NULL COMMENT '笔记ID',
    `created_at`    DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`    DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`collection_id`, `note_id`),
    CONSTRAINT `fk_collection_note_collection` FOREIGN KEY (`collection_id`) REFERENCES `collection` (`collection_id`),
    CONSTRAINT `fk_collection_note_note`       FOREIGN KEY (`note_id`)       REFERENCES `note` (`note_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '收藏夹-笔记关联表';

-- ============================================================================
-- 13. 题单-题目关联表（question_list × question 多对多，含排序）
-- ============================================================================
CREATE TABLE `question_list_item` (
    `question_list_id` INT      NOT NULL COMMENT '题单ID',
    `question_id`      INT      NOT NULL COMMENT '题目ID',
    `rank`             INT      DEFAULT 1 COMMENT '题单内顺序，从1开始',
    `created_at`       DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`       DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`question_list_id`, `question_id`),
    CONSTRAINT `fk_qli_question_list` FOREIGN KEY (`question_list_id`) REFERENCES `question_list` (`question_list_id`),
    CONSTRAINT `fk_qli_question`      FOREIGN KEY (`question_id`)      REFERENCES `question` (`question_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '题单-题目关联表';

-- ============================================================================
-- 14. 消息表
-- ============================================================================
CREATE TABLE `message` (
    `message_id`  INT        NOT NULL AUTO_INCREMENT COMMENT '消息ID',
    `receiver_id` BIGINT     NOT NULL COMMENT '接收者ID',
    `sender_id`   BIGINT     NOT NULL COMMENT '发送者ID',
    `type`        INT        DEFAULT NULL COMMENT '消息类型',
    `target_id`   INT        DEFAULT NULL COMMENT '目标ID',
    `target_type` INT        DEFAULT NULL COMMENT '目标类型',
    `content`     TEXT       COMMENT '消息内容',
    `is_read`     TINYINT(1) DEFAULT 0 COMMENT '是否已读',
    `created_at`  DATETIME   DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at`  DATETIME   DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`message_id`),
    KEY `idx_receiver_id` (`receiver_id`),
    -- target_id 是「多态外键」：target_type=1 时指向 note.note_id，target_type=2 时指向 comment.comment_id，
    -- 无法用单一外键表达，故此处不建立外键约束。
    CONSTRAINT `fk_message_receiver` FOREIGN KEY (`receiver_id`) REFERENCES `user` (`user_id`),
    CONSTRAINT `fk_message_sender`   FOREIGN KEY (`sender_id`)   REFERENCES `user` (`user_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '消息表';

-- ============================================================================
-- 15. 统计信息表（独立表，无关联）
-- ============================================================================
CREATE TABLE `statistic` (
    `id`                  INT  NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `login_count`         INT  DEFAULT 0 COMMENT '当天登录次数',
    `register_count`      INT  DEFAULT 0 COMMENT '当天注册人数',
    `total_register_count` INT DEFAULT 0 COMMENT '累计注册总人数',
    `note_count`          INT  DEFAULT 0 COMMENT '当天笔记数量',
    `submit_note_count`   INT  DEFAULT 0 COMMENT '当天提交笔记数量',
    `total_note_count`    INT  DEFAULT 0 COMMENT '累计笔记总数量',
    `date`                DATE DEFAULT NULL COMMENT '统计日期',
    PRIMARY KEY (`id`),
    KEY `idx_date` (`date`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '统计信息表';

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
--  关系一览（用于核对 ER 图连线是否正确）
-- ============================================================================
--  1  : N  user            -> collection            (collection.creator_id    = user.user_id)
--  1  : N  user            -> note                  (note.author_id           = user.user_id)
--  1  : N  user            -> comment               (comment.author_id        = user.user_id)
--  1  : N  user            -> note_like              (note_like.user_id        = user.user_id)
--  1  : N  user            -> note_collect           (note_collect.user_id     = user.user_id)
--  1  : N  user            -> comment_like           (comment_like.user_id     = user.user_id)
--  1  : N  user            -> message（作为接收者）   (message.receiver_id      = user.user_id)
--  1  : N  user            -> message（作为发送者）   (message.sender_id        = user.user_id)
--
--  1  : N  category        -> question              (question.category_id     = category.category_id)
--  1  : N  category        -> category（自关联）      (category.parent_category_id，0 表示一级分类)
--
--  1  : N  note_category   -> note                   (note.category_id         = note_category.category_id)
--  1  : N  question        -> note                   (note.question_id         = question.question_id)
--
--  1  : N  note            -> comment                (comment.note_id          = note.note_id)
--  1  : N  note            -> note_like              (note_like.note_id        = note.note_id)
--  1  : N  note            -> note_collect           (note_collect.note_id     = note.note_id)
--  1  : N  note            -> collection_note        (collection_note.note_id  = note.note_id)
--
--  1  : N  comment         -> comment（自关联、二级回复）(comment.parent_id     = comment.comment_id)
--  1  : N  comment         -> comment_like           (comment_like.comment_id  = comment.comment_id)
--
--  1  : N  collection      -> collection_note        (collection_note.collection_id = collection.collection_id)
--  1  : N  question_list   -> question_list_item     (question_list_item.question_list_id = question_list.question_list_id)
--  1  : N  question        -> question_list_item     (question_list_item.question_id      = question.question_id)
--
--  N  : N （经中间表）
--     user  <-> note     通过 note_like        （点赞）
--     user  <-> note     通过 note_collect     （收藏）
--     user  <-> comment  通过 comment_like     （评论点赞）
--     note  <-> collection 通过 collection_note（收入收藏夹）
--     question <-> question_list 通过 question_list_item（组成题单）
--
--  独立表：statistic（无任何外键）
-- ============================================================================
--  统计：15 张表、20 条外键关系
-- ============================================================================

-- ============================================================================
--  附：枚举字段取值说明
--  为保证与线上库逐字一致，上面各列的 COMMENT 未做改写，取值含义集中列在此处：
-- ============================================================================
--  user.gender           1=男  2=女  3=保密（默认 3）
--  user.is_admin         0=普通用户  1=管理员（默认 0）
--  user.is_banned        0=未封禁  1=已封禁（默认 0）
--  question.difficulty   1=简单  2=中等  3=困难（默认 1）
--  question_list.type    1=普通题单  2=训练营题单
--  message.type          1=点赞  2=评论  3=系统
--  message.target_type   1=笔记  2=评论（与 message.target_id 组合，表示该消息指向的对象）
--  message.is_read       0=未读  1=已读（tinyint(1)，默认 0）
-- ============================================================================
