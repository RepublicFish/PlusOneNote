-- ============================================================
--  kamanotes 演示数据 · 脚本 1/4：清理测试残留 + 演示用户
--  执行顺序：1 → 2 → 3 → 4
--  所有演示账号密码统一为：kama123456
--  （复制 demotemplate 的 BCrypt 哈希，保证可正常登录）
-- ============================================================

USE kamanote_tech;
SET NAMES utf8mb4;

-- ------------------------------------------------------------
-- 0. 清理开发/测试阶段产生的残留数据
--    (3~8 号账号是调试时注册的，账号名形如 deltest7800)
-- ------------------------------------------------------------
DELETE FROM note_like       WHERE user_id BETWEEN 3 AND 8;
DELETE FROM note_collect    WHERE user_id BETWEEN 3 AND 8;
DELETE FROM comment_like    WHERE user_id BETWEEN 3 AND 8;
DELETE FROM comment         WHERE author_id BETWEEN 3 AND 8;
DELETE FROM collection_note WHERE collection_id IN (SELECT collection_id FROM collection WHERE creator_id BETWEEN 3 AND 8);
DELETE FROM collection      WHERE creator_id BETWEEN 3 AND 8;
DELETE FROM message         WHERE receiver_id BETWEEN 3 AND 8 OR sender_id BETWEEN 3 AND 8;
DELETE FROM note            WHERE author_id BETWEEN 3 AND 8;
DELETE FROM user            WHERE user_id BETWEEN 3 AND 8;

-- 清理指向已不存在记录的孤儿关联
DELETE FROM note_like       WHERE note_id     NOT IN (SELECT note_id     FROM note);
DELETE FROM note_collect    WHERE note_id     NOT IN (SELECT note_id     FROM note);
DELETE FROM collection_note WHERE note_id     NOT IN (SELECT note_id     FROM note);
DELETE FROM comment_like    WHERE comment_id  NOT IN (SELECT comment_id  FROM comment);
DELETE FROM comment         WHERE note_id     NOT IN (SELECT note_id     FROM note);

-- ------------------------------------------------------------
-- 1. 演示用户（15 位）
--    密码哈希取自 demotemplate，明文均为 kama123456
-- ------------------------------------------------------------
SET @pwd = (SELECT password FROM user WHERE account = 'demotemplate');

INSERT INTO user
  (account, username, password, gender, birthday, avatar_url, email, school, signature,
   is_banned, is_admin, last_login_at, created_at)
VALUES
('zhangwei',  '张伟',   @pwd, 1, '2002-03-15', 'http://localhost:8081/images/0ba22ea5-ce12-404e-bf09-e15872ab2206.png', 'zhangwei@example.com',  '哈尔滨工业大学', '把每一道题都当成面试题来做',        0, 0, '2026-09-17 21:10:00', '2026-03-12 09:20:00'),
('lina2026',  '李娜',   @pwd, 2, '2003-07-22', 'http://localhost:8081/images/186c64dd-e3f2-4aee-840e-049eeb65c200.jpg', 'lina@example.com',      '浙江大学',       '慢慢来，比较快',                    0, 0, '2026-09-17 20:35:00', '2026-03-18 14:05:00'),
('wangfang',  '王芳',   @pwd, 2, '2002-11-08', 'http://localhost:8081/images/5ea027fd-f57d-4d7c-8868-34abe99cf548.png', 'wangfang@example.com',  '北京邮电大学',   '算法是内功，框架是招式',            0, 0, '2026-09-16 22:40:00', '2026-04-02 10:30:00'),
('liuyang',   '刘洋',   @pwd, 1, '2001-05-30', 'http://localhost:8081/images/624bba98-329a-4113-89bb-642505d47989.png', 'liuyang@example.com',   '华中科技大学',   '每天进步一点点',                    0, 0, '2026-09-17 19:05:00', '2026-04-15 16:50:00'),
('chenjie',   '陈杰',   @pwd, 1, '2003-01-19', 'http://localhost:8081/images/d428c1be-3060-42c6-95ea-c904ff611aed.png', 'chenjie@example.com',   '西安电子科技大学','刷题不是目的，理解才是',            0, 0, '2026-09-15 08:20:00', '2026-04-21 11:15:00'),
('zhaomin',   '赵敏',   @pwd, 2, '2002-09-03', 'http://localhost:8081/images/daf4e117-64d4-4d82-bb32-df41664c6db8.jpg', 'zhaomin@example.com',   '南京大学',       '代码洁癖患者',                      0, 0, '2026-09-17 23:15:00', '2026-05-06 09:45:00'),
('sunpeng',   '孙鹏',   @pwd, 1, '2001-12-25', 'http://localhost:8081/images/0ba22ea5-ce12-404e-bf09-e15872ab2206.png', 'sunpeng@example.com',   '电子科技大学',   '后端选手，正在补算法',              0, 0, '2026-09-14 21:55:00', '2026-05-13 15:20:00'),
('zhouxin',   '周欣',   @pwd, 2, '2003-04-11', 'http://localhost:8081/images/186c64dd-e3f2-4aee-840e-049eeb65c200.jpg', 'zhouxin@example.com',   '武汉大学',       '在准备秋招，一起加油',              0, 0, '2026-09-17 18:30:00', '2026-05-20 13:10:00'),
('wulei2026', '吴磊',   @pwd, 1, '2002-06-28', 'http://localhost:8081/images/5ea027fd-f57d-4d7c-8868-34abe99cf548.png', 'wulei@example.com',      '同济大学',       '记录是为了更好地复习',              0, 0, '2026-09-16 20:05:00', '2026-06-01 10:00:00'),
('zhengshuang','郑爽',  @pwd, 2, '2003-02-14', 'http://localhost:8081/images/624bba98-329a-4113-89bb-642505d47989.png', 'zhengshuang@example.com','中山大学',      '从零开始学算法',                    0, 0, '2026-09-13 22:20:00', '2026-06-09 16:35:00'),
('xulei2026', '徐磊',   @pwd, 1, '2001-08-07', 'http://localhost:8081/images/d428c1be-3060-42c6-95ea-c904ff611aed.png', 'xulei@example.com',     '大连理工大学',   '一年后我要进大厂',                  0, 0, '2026-09-17 12:45:00', '2026-06-18 09:05:00'),
('hejuan',    '何娟',   @pwd, 2, '2002-10-16', 'http://localhost:8081/images/daf4e117-64d4-4d82-bb32-df41664c6db8.jpg', 'hejuan@example.com',    '四川大学',       '坚持就是胜利',                      0, 0, '2026-09-16 11:30:00', '2026-06-25 14:40:00'),
('guoyu2026', '郭宇',   @pwd, 1, '2003-03-21', 'http://localhost:8081/images/0ba22ea5-ce12-404e-bf09-e15872ab2206.png', 'guoyu@example.com',     '中南大学',       '笔记记得越细，复习越省力',          0, 0, '2026-09-15 17:50:00', '2026-07-03 10:25:00'),
('maqiang',   '马强',   @pwd, 1, '2002-07-09', 'http://localhost:8081/images/186c64dd-e3f2-4aee-840e-049eeb65c200.jpg', 'maqiang@example.com',   '东南大学',       '刷完这本题单就去面字节',            0, 0, '2026-09-17 09:15:00', '2026-07-12 15:55:00'),
('linna2026', '林娜',   @pwd, 2, '2003-05-27', 'http://localhost:8081/images/5ea027fd-f57d-4d7c-8868-34abe99cf548.png', 'linna@example.com',     '厦门大学',       '目标是 offer++',                    0, 0, '2026-09-16 19:40:00', '2026-07-20 11:05:00');

SELECT CONCAT('演示用户插入完成，当前用户总数 = ', COUNT(*)) AS result FROM user;
