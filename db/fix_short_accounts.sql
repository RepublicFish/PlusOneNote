-- ============================================================
--  修复：部分演示账号名过短，无法登录
--
--  原因：LoginRequest.account 与 RegisterRequest.account 都有
--        @Size(min = 6, max = 32) 校验，
--        lina(4) / wulei(5) / xulei(5) / guoyu(5) / linna(5)
--        不足 6 位，登录时直接被参数校验拒绝。
--  做法：统一补上年份后缀，保持可读性。
--  密码不变，仍为 kama123456
-- ============================================================

USE kamanote_tech;
SET NAMES utf8mb4;

UPDATE user SET account = 'lina2026'  WHERE account = 'lina';
UPDATE user SET account = 'wulei2026' WHERE account = 'wulei';
UPDATE user SET account = 'xulei2026' WHERE account = 'xulei';
UPDATE user SET account = 'guoyu2026' WHERE account = 'guoyu';
UPDATE user SET account = 'linna2026' WHERE account = 'linna';

-- 校验：是否还存在长度小于 6 的账号
SELECT '--- 仍然过短的账号（应为空） ---' AS info;
SELECT user_id, account, CHAR_LENGTH(account) AS len
FROM user WHERE CHAR_LENGTH(account) < 6;

SELECT '--- 全部演示账号 ---' AS info;
SELECT user_id, account, CHAR_LENGTH(account) AS len, username, is_admin
FROM user ORDER BY user_id;
