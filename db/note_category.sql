-- ============================================================
-- 笔记分类功能迁移脚本
-- 说明：为「笔记」增加独立于题目的分类能力
--   1) 新建 note_category 表（笔记分类，如 Redis / SQL / MQ ...）
--   2) note 表增加 category_id 字段（可空，兼容原有"题目笔记"）
-- 适用库：kamanote_tech
-- ============================================================

USE kamanote_tech;

-- 1. 笔记分类表
CREATE TABLE IF NOT EXISTS `note_category` (
  `category_id` int NOT NULL AUTO_INCREMENT COMMENT '笔记分类ID',
  `name` varchar(64) NOT NULL COMMENT '分类名称',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`category_id`),
  UNIQUE KEY `uk_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='笔记分类表';

-- 2. note 表增加分类字段（若已存在则忽略报错）
ALTER TABLE `note`
  ADD COLUMN `category_id` int DEFAULT NULL COMMENT '笔记分类ID（为空表示题目笔记）' AFTER `question_id`,
  ADD KEY `idx_category_id` (`category_id`);

-- 3. 初始化常用笔记分类
INSERT IGNORE INTO `note_category` (`name`) VALUES
  ('Redis'),
  ('MySQL'),
  ('SQL'),
  ('MQ'),
  ('Java'),
  ('Spring'),
  ('JVM'),
  ('计算机网络'),
  ('操作系统'),
  ('数据结构与算法'),
  ('其他');
