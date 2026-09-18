-- ============================================================
--  kamanotes 演示数据 · 脚本 4/4：关系数据 + 计数器同步 + 检索向量
--  点赞/收藏/评论等用集合运算批量生成，最后统一回填计数字段
-- ============================================================

USE kamanote_tech;
SET NAMES utf8mb4;

-- ------------------------------------------------------------
-- 1. 笔记点赞（约 55% 的用户-笔记组合，不给自己点赞）
-- ------------------------------------------------------------
INSERT INTO note_like (note_id, user_id, created_at, updated_at)
SELECT n.note_id, u.user_id,
       DATE_ADD(n.created_at, INTERVAL ((n.note_id * 7 + u.user_id * 13) % 240) HOUR),
       DATE_ADD(n.created_at, INTERVAL ((n.note_id * 7 + u.user_id * 13) % 240) HOUR)
FROM note n
JOIN user u ON u.account <> 'demotemplate'
WHERE ((n.note_id * 31 + u.user_id * 17) % 100) < 55
  AND u.user_id <> n.author_id;

-- ------------------------------------------------------------
-- 2. 笔记收藏（约 25%）
-- ------------------------------------------------------------
INSERT INTO note_collect (note_id, user_id, created_at)
SELECT n.note_id, u.user_id,
       DATE_ADD(n.created_at, INTERVAL ((n.note_id * 5 + u.user_id * 11) % 300) HOUR)
FROM note n
JOIN user u ON u.account <> 'demotemplate'
WHERE ((n.note_id * 23 + u.user_id * 29) % 100) < 25
  AND u.user_id <> n.author_id;

-- ------------------------------------------------------------
-- 3. 收藏夹（每个用户 3 个）
-- ------------------------------------------------------------
INSERT INTO collection (name, description, creator_id, created_at, updated_at)
SELECT t.name, t.descr, u.user_id, '2026-08-01 10:00:00', '2026-08-01 10:00:00'
FROM user u
CROSS JOIN (
            SELECT '算法题解'  AS name, '按题型整理的优质题解笔记'   AS descr
  UNION ALL SELECT '八股文',        'Java 后端面试高频八股'
  UNION ALL SELECT '项目参考',      '做课设时收集的资料与踩坑记录'
) t
WHERE u.account <> 'demotemplate';

-- 把别人的笔记放进自己的收藏夹（约 30% 组合）
INSERT INTO collection_note (collection_id, note_id, created_at, updated_at)
SELECT c.collection_id, n.note_id, '2026-08-05 12:00:00', '2026-08-05 12:00:00'
FROM collection c
JOIN note n ON ((c.collection_id * 13 + n.note_id * 7) % 100) < 30
WHERE c.creator_id <> n.author_id;

-- ------------------------------------------------------------
-- 4. 一级评论（约 35% 的 用户-笔记 组合）
-- ------------------------------------------------------------
INSERT INTO comment (note_id, author_id, parent_id, content, like_count, reply_count, created_at, updated_at)
SELECT n.note_id, u.user_id, NULL,
       ELT(1 + ((n.note_id * 3 + u.user_id * 7) % 10),
           '写得很清楚，收藏了，感谢分享！',
           '这个思路比我想的简洁多了，学到了。',
           '请问这里的时间复杂度是怎么算的？没太看懂。',
           '补充一点：边界情况还需要注意空数组。',
           '终于看懂了，之前一直卡在这一步。',
           '代码里的 mid 用 left + (right-left)/2 是为了防溢出吧？',
           '讲得真好，比官方题解还易懂。',
           '我用的另一种做法，但是你这个更优雅。',
           '面试刚好考到这道题，回来看笔记 thanks~',
           '总结得很到位，尤其是易错点那段。'),
       0, 0,
       DATE_ADD(n.created_at, INTERVAL ((n.note_id * 9 + u.user_id * 5) % 400) HOUR),
       DATE_ADD(n.created_at, INTERVAL ((n.note_id * 9 + u.user_id * 5) % 400) HOUR)
FROM note n
JOIN user u ON u.account <> 'demotemplate'
WHERE ((n.note_id * 19 + u.user_id * 23) % 100) < 35
  AND u.user_id <> n.author_id;

-- ------------------------------------------------------------
-- 5. 二级回复（对约 20% 的一级评论做回复）
-- ------------------------------------------------------------
INSERT INTO comment (note_id, author_id, parent_id, content, like_count, reply_count, created_at, updated_at)
SELECT c.note_id, u.user_id, c.comment_id,
       ELT(1 + ((c.comment_id * 5 + u.user_id * 3) % 6),
           '时间复杂度是 O(n)，每个元素最多进出窗口一次。',
           '对的，用 left + (right - left) / 2 可以避免 int 溢出。',
           '确实，空数组和单个元素这两种情况要单独考虑。',
           '可以看一下同分类下的另一篇笔记，讲得更细。',
           '我也遇到这个问题，后来发现是边界没处理好。',
           '感谢补充，已经更新到笔记里了。'),
       0, 0,
       DATE_ADD(c.created_at, INTERVAL ((c.comment_id * 3 + u.user_id) % 120) HOUR),
       DATE_ADD(c.created_at, INTERVAL ((c.comment_id * 3 + u.user_id) % 120) HOUR)
FROM comment c
JOIN user u ON u.account <> 'demotemplate'
WHERE c.parent_id IS NULL
  AND ((c.comment_id * 17 + u.user_id * 13) % 100) < 20
  AND u.user_id <> c.author_id;

-- ------------------------------------------------------------
-- 6. 评论点赞（约 30%）
-- ------------------------------------------------------------
INSERT INTO comment_like (comment_id, user_id, created_at)
SELECT c.comment_id, u.user_id,
       DATE_ADD(c.created_at, INTERVAL ((c.comment_id * 2 + u.user_id * 3) % 100) HOUR)
FROM comment c
JOIN user u ON u.account <> 'demotemplate'
WHERE ((c.comment_id * 11 + u.user_id * 5) % 100) < 30
  AND u.user_id <> c.author_id;

-- ------------------------------------------------------------
-- 7. 消息通知
--    被评论 → type=2，被点赞 → type=1，target_type=1 表示笔记
-- ------------------------------------------------------------
INSERT INTO message (receiver_id, sender_id, type, target_id, target_type, content, is_read, created_at, updated_at)
SELECT n.author_id, c.author_id, 2, n.note_id, 1, LEFT(c.content, 50), 0, c.created_at, c.created_at
FROM comment c
JOIN note n ON c.note_id = n.note_id
WHERE c.parent_id IS NULL
  AND c.author_id <> n.author_id;

INSERT INTO message (receiver_id, sender_id, type, target_id, target_type, content, is_read, created_at, updated_at)
SELECT n.author_id, nl.user_id, 1, n.note_id, 1, '赞了你的笔记', 0, nl.created_at, nl.created_at
FROM note_like nl
JOIN note n ON nl.note_id = n.note_id
WHERE ((nl.note_id * 7 + nl.user_id * 3) % 100) < 40
  AND nl.user_id <> n.author_id;

-- 系统通知
INSERT INTO message (receiver_id, sender_id, type, target_id, target_type, content, is_read, created_at, updated_at)
SELECT u.user_id, u.user_id, 3, NULL, NULL,
       '欢迎加入卡码笔记！建议先从「笔记分类」入手，按主题整理你的学习笔记。', 0,
       '2026-08-01 09:00:00', '2026-08-01 09:00:00'
FROM user u WHERE u.account <> 'demotemplate';

-- ------------------------------------------------------------
-- 8. 统计数据（近 90 天，用于后台图表）
-- ------------------------------------------------------------
INSERT INTO statistic (login_count, register_count, total_register_count,
                       note_count, submit_note_count, total_note_count, date)
WITH RECURSIVE seq AS (
    SELECT 0 AS i
    UNION ALL
    SELECT i + 1 FROM seq WHERE i < 89
)
SELECT 18 + (i * 7) % 62,
       (i * 3) % 5,
       96 + i * 2,
       4 + (i * 11) % 26,
       2 + (i * 5) % 13,
       380 + i * 9,
       DATE_SUB(CURDATE(), INTERVAL (89 - i) DAY)
FROM seq;

-- ------------------------------------------------------------
-- 9. 回填计数字段（保证与实际的点赞/收藏/评论数一致）
-- ------------------------------------------------------------
UPDATE note n SET
    like_count    = (SELECT COUNT(*) FROM note_like    x WHERE x.note_id  = n.note_id),
    collect_count = (SELECT COUNT(*) FROM note_collect x WHERE x.note_id  = n.note_id),
    comment_count = (SELECT COUNT(*) FROM comment      x WHERE x.note_id  = n.note_id);

-- 注意：MySQL 不允许在 UPDATE 的子查询里引用「被更新的同一张表」（错误 1093），
-- 所以统计回复数时改用「派生表 JOIN」的写法。
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

-- ------------------------------------------------------------
-- 10. 检索向量
--    把标题、考点、分类名、正文一起写入。
--    注意：当前全文索引用的是默认分词器且 innodb_ft_min_token_size = 3，
--    中文长句会被当成一个超长 token 而不被索引，检索功能需要另行修复（见文档说明）。
-- ------------------------------------------------------------
UPDATE note n
LEFT JOIN question q      ON n.question_id = q.question_id
LEFT JOIN note_category nc ON n.category_id = nc.category_id
SET n.search_vector = CONCAT_WS(' ',
        IFNULL(q.title, ''),
        IFNULL(q.exam_point, ''),
        IFNULL(nc.name, ''),
        n.content);

-- ------------------------------------------------------------
-- 删除仅用于生成 BCrypt 密码哈希的模板账号
-- （密码哈希已复制到 15 位演示用户，明文均为 kama123456）
-- 如需重新执行本套脚本，请先重新注册 demotemplate 账号
-- ------------------------------------------------------------
DELETE FROM user WHERE account = 'demotemplate';

-- ------------------------------------------------------------
-- 结果汇总
-- ------------------------------------------------------------
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
