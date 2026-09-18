-- ============================================================
--  修复全文检索：把 note 的 FULLTEXT 索引切换为 ngram 分词器
--
--  背景：
--    search_vector 里已写入「标题 + 考点 + 分类名 + 正文」，
--    但 MySQL 默认全文分词器不切分中文，整段中文会变成一个超长 token，
--    超过 innodb_ft_max_token_size(84) 后根本不被索引；
--    同时 innodb_ft_min_token_size=3 会丢弃「缓存」「数组」这类 2 字词。
--    结果就是 /api/search/notes 永远查不到中文。
--
--  ngram 分词器会把中文按 ngram_token_size(=2) 切成二元组建立倒排索引，
--  检索时查询词也按同样规则切分，因此中文可以正常命中。
-- ============================================================

USE kamanote_tech;
SET NAMES utf8mb4;

SELECT '--- 切换前的索引定义 ---' AS info;
SHOW INDEX FROM note WHERE Key_name = 'ft_search_vector';

-- 1. 删除旧索引，用 ngram 分词器重建
ALTER TABLE note DROP INDEX ft_search_vector;
ALTER TABLE note ADD FULLTEXT INDEX ft_search_vector (search_vector) WITH PARSER ngram;

SELECT '--- 切换后的索引定义（应与之前一致，分词器不体现在这里） ---' AS info;
SHOW INDEX FROM note WHERE Key_name = 'ft_search_vector';

-- 2. 验证：完全模拟后端 NoteMapper.searchNotes 的写法
--    （NATURAL LANGUAGE MODE，关键词由后端 jieba 分词后以空格连接）
SELECT '--- 测试1: 缓存（2字中文，修复前为 0） ---' AS info;
SELECT note_id, LEFT(search_vector, 30) AS head
FROM note
WHERE MATCH(search_vector) AGAINST('缓存' IN NATURAL LANGUAGE MODE)
LIMIT 5;

SELECT '--- 测试2: 动态规划 回溯（jieba 分词后的形式） ---' AS info;
SELECT note_id, LEFT(search_vector, 30) AS head
FROM note
WHERE MATCH(search_vector) AGAINST('动态规划 回溯' IN NATURAL LANGUAGE MODE)
LIMIT 5;

SELECT '--- 测试3: Redis（英文） ---' AS info;
SELECT note_id, LEFT(search_vector, 30) AS head
FROM note
WHERE MATCH(search_vector) AGAINST('Redis' IN NATURAL LANGUAGE MODE)
LIMIT 5;

SELECT '--- 测试4: 各关键词命中数汇总 ---' AS info;
SELECT '缓存'      AS keyword, COUNT(*) AS hits FROM note WHERE MATCH(search_vector) AGAINST('缓存' IN NATURAL LANGUAGE MODE)
UNION ALL SELECT '数组',      COUNT(*) FROM note WHERE MATCH(search_vector) AGAINST('数组' IN NATURAL LANGUAGE MODE)
UNION ALL SELECT '动态规划',  COUNT(*) FROM note WHERE MATCH(search_vector) AGAINST('动态规划' IN NATURAL LANGUAGE MODE)
UNION ALL SELECT '索引',      COUNT(*) FROM note WHERE MATCH(search_vector) AGAINST('索引' IN NATURAL LANGUAGE MODE)
UNION ALL SELECT 'Redis',     COUNT(*) FROM note WHERE MATCH(search_vector) AGAINST('Redis' IN NATURAL LANGUAGE MODE)
UNION ALL SELECT '三次握手',  COUNT(*) FROM note WHERE MATCH(search_vector) AGAINST('三次握手' IN NATURAL LANGUAGE MODE);
