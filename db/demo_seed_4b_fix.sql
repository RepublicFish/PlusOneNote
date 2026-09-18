-- ============================================================
--  kamanotes 演示数据 · 脚本 4b：补跑脚本 4 未完成的部分
--  背景：脚本 4 在「统计评论回复数」处触发了 MySQL 错误 1093
--        （UPDATE 的子查询引用了被更新的同一张表），
--        其后的语句未执行，这里单独补上。均为幂等操作。
-- ============================================================

USE kamanote_tech;
SET NAMES utf8mb4;

-- 1. 回填计数器（重复执行也安全）
UPDATE note n SET
    like_count    = (SELECT COUNT(*) FROM note_like    x WHERE x.note_id  = n.note_id),
    collect_count = (SELECT COUNT(*) FROM note_collect x WHERE x.note_id  = n.note_id),
    comment_count = (SELECT COUNT(*) FROM comment      x WHERE x.note_id  = n.note_id);

UPDATE comment c
LEFT JOIN (
    SELECT parent_id, COUNT(*) AS cnt
    FROM comment
    WHERE parent_id IS NOT NULL
    GROUP BY parent_id
) r ON c.comment_id = r.parent_id
SET c.reply_count = IFNULL(r.cnt, 0);

UPDATE comment c SET
    like_count = (SELECT COUNT(*) FROM comment_like x WHERE x.comment_id = c.comment_id);

-- 2. 检索向量
UPDATE note n
LEFT JOIN question q       ON n.question_id = q.question_id
LEFT JOIN note_category nc ON n.category_id = nc.category_id
SET n.search_vector = CONCAT_WS(' ',
        IFNULL(q.title, ''),
        IFNULL(q.exam_point, ''),
        IFNULL(nc.name, ''),
        n.content);

-- 3. 删除密码模板账号
DELETE FROM user WHERE account = 'demotemplate';

-- 4. 汇总
SELECT 'user' AS t, COUNT(*) AS n FROM user
UNION ALL SELECT 'question',          COUNT(*) FROM question
UNION ALL SELECT 'question_list',     COUNT(*) FROM question_list
UNION ALL SELECT 'question_list_item',COUNT(*) FROM question_list_item
UNION ALL SELECT 'note',              COUNT(*) FROM note
UNION ALL SELECT 'note_like',         COUNT(*) FROM note_like
UNION ALL SELECT 'note_collect',      COUNT(*) FROM note_collect
UNION ALL SELECT 'comment',           COUNT(*) FROM comment
UNION ALL SELECT 'comment_like',      COUNT(*) FROM comment_like
UNION ALL SELECT 'collection',        COUNT(*) FROM collection
UNION ALL SELECT 'collection_note',   COUNT(*) FROM collection_note
UNION ALL SELECT 'message',           COUNT(*) FROM message
UNION ALL SELECT 'statistic',         COUNT(*) FROM statistic;
