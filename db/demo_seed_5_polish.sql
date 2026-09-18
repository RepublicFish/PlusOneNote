-- ============================================================
--  kamanotes 演示数据 · 脚本 5：时间分布润色
--  问题：演示笔记的 created_at 都落在过去几个月，
--        而「今日笔记排行榜」只统计 DATE(created_at) = 今天，
--        导致首页排行榜为空。
--  做法：把一批笔记及其关联数据挪到「今天」，让首页显得活跃。
-- ============================================================

USE kamanote_tech;
SET NAMES utf8mb4;

-- 选 12 条笔记作为「今日发布」（按 note_id 分散到今天的 9~20 点）
UPDATE note
SET created_at = DATE_ADD(CURDATE(), INTERVAL (9 + note_id % 12) HOUR),
    updated_at = DATE_ADD(CURDATE(), INTERVAL (9 + note_id % 12) HOUR)
WHERE note_id IN (1, 2, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21);

-- 关联的点赞时间跟随笔记时间
UPDATE note_like nl
JOIN note n ON nl.note_id = n.note_id
SET nl.created_at = DATE_ADD(n.created_at, INTERVAL 1 HOUR),
    nl.updated_at = DATE_ADD(n.created_at, INTERVAL 1 HOUR)
WHERE n.note_id IN (1, 2, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21);

-- 关联的收藏时间跟随笔记时间
UPDATE note_collect nc
JOIN note n ON nc.note_id = n.note_id
SET nc.created_at = DATE_ADD(n.created_at, INTERVAL 2 HOUR)
WHERE n.note_id IN (1, 2, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21);

-- 关联的评论时间跟随笔记时间
UPDATE comment c
JOIN note n ON c.note_id = n.note_id
SET c.created_at = DATE_ADD(n.created_at, INTERVAL 3 HOUR),
    c.updated_at = DATE_ADD(n.created_at, INTERVAL 3 HOUR)
WHERE n.note_id IN (1, 2, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21);

-- 关联的消息时间跟随评论时间
UPDATE message m
JOIN comment c ON m.target_id = c.note_id AND m.type = 2
SET m.created_at = c.created_at,
    m.updated_at = c.created_at
WHERE c.note_id IN (1, 2, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21);

-- 校验：今日排行榜应能查到数据
SELECT n.author_id, u.username, COUNT(*) AS today_note_count
FROM note n
JOIN user u ON n.author_id = u.user_id
WHERE DATE(n.created_at) = CURDATE()
GROUP BY n.author_id, u.username
ORDER BY today_note_count DESC;

SELECT CONCAT('今日发布的笔记数 = ', COUNT(*)) AS result
FROM note WHERE DATE(created_at) = CURDATE();
