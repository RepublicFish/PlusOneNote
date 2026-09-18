-- ============================================================
--  kamanotes 演示数据 · 脚本 3/4：笔记
--   - 题目笔记：填写 question_id，category_id 为空
--   - 分类笔记：填写 category_id，question_id 为空
-- ============================================================

USE kamanote_tech;
SET NAMES utf8mb4;

SET @u_zhangwei   = (SELECT user_id FROM user WHERE account='zhangwei');
SET @u_lina       = (SELECT user_id FROM user WHERE account='lina');
SET @u_wangfang   = (SELECT user_id FROM user WHERE account='wangfang');
SET @u_liuyang    = (SELECT user_id FROM user WHERE account='liuyang');
SET @u_chenjie    = (SELECT user_id FROM user WHERE account='chenjie');
SET @u_zhaomin    = (SELECT user_id FROM user WHERE account='zhaomin');
SET @u_sunpeng    = (SELECT user_id FROM user WHERE account='sunpeng');
SET @u_zhouxin    = (SELECT user_id FROM user WHERE account='zhouxin');
SET @u_wulei      = (SELECT user_id FROM user WHERE account='wulei');
SET @u_zhengshuang= (SELECT user_id FROM user WHERE account='zhengshuang');
SET @u_xulei      = (SELECT user_id FROM user WHERE account='xulei');
SET @u_hejuan     = (SELECT user_id FROM user WHERE account='hejuan');
SET @u_guoyu      = (SELECT user_id FROM user WHERE account='guoyu');
SET @u_maqiang    = (SELECT user_id FROM user WHERE account='maqiang');
SET @u_linna      = (SELECT user_id FROM user WHERE account='linna');

-- 题目 ID 速查：1两数之和 2移除元素 3长度最小的子数组 4反转链表 5两两交换 6环形链表II
-- 7反转字符串 8strStr 9字母异位词 10数组交集 11用栈实现队列 12有效的括号
-- 13前序遍历 14最大深度 15斐波那契 16爬楼梯 17组合 18全排列
-- 19二分查找 20有序数组平方 21螺旋矩阵II 22水果成篮 23最小覆盖子串
-- 24设计链表 25删除倒数第N 26链表相交 27合并有序链表 28K个一组翻转
-- 29替换空格 30翻转单词 31左旋转 32重复子串 33三数之和 34四数之和
-- 35四数相加II 36赎金信 37相邻重复项 38逆波兰 39滑动窗口最大值 40前K高频
-- 41层序遍历 42翻转二叉树 43对称二叉树 44所有路径 45路径总和 46构造二叉树 47验证BST
-- 48最小花费爬楼梯 49不同路径 50整数拆分 51 01背包 52零钱兑换 53最长递增子序列 54最长公共子序列
-- 55字母组合 56组合总和 57分割回文串 58子集 59N皇后

-- ============================================================
-- A. 题目笔记
-- ============================================================
INSERT INTO note (author_id, question_id, category_id, content, created_at, updated_at) VALUES

(@u_zhangwei, 1, NULL,
'## 核心思路\n用哈希表把「找 target - x」从 O(n) 降到 O(1)。\n\n遍历数组时，先查 map 里有没有 target - nums[i]：\n- 有 → 直接返回两个下标\n- 没有 → 把当前值和下标存进 map\n\n注意：**先查再存**，可以天然避免同一个元素被用两次。\n\n```java\npublic int[] twoSum(int[] nums, int target) {\n    Map<Integer, Integer> map = new HashMap<>();\n    for (int i = 0; i < nums.length; i++) {\n        int need = target - nums[i];\n        if (map.containsKey(need)) {\n            return new int[]{map.get(need), i};\n        }\n        map.put(nums[i], i);\n    }\n    return new int[0];\n}\n```\n\n### 复杂度\n- 时间 O(n)，每个元素只访问一次\n- 空间 O(n)，最坏情况全部入表\n\n### 易错点\n返回的是**下标**而不是值，所以 map 的 value 要存下标。', '2026-08-02 10:12:00', '2026-08-02 10:12:00'),

(@u_lina, 2, NULL,
'## 双指针原地移除\n数组的元素在内存地址中是连续的，不能单独删除，只能**覆盖**。\n\n用快慢指针：\n- `fast` 负责遍历，找不等于 val 的元素\n- `slow` 指向下一个要写入的位置\n\n```java\npublic int removeElement(int[] nums, int val) {\n    int slow = 0;\n    for (int fast = 0; fast < nums.length; fast++) {\n        if (nums[fast] != val) {\n            nums[slow++] = nums[fast];\n        }\n    }\n    return slow;\n}\n```\n\n返回的 `slow` 正好就是新数组的长度，因为下标 0 ~ slow-1 都是保留下来的元素。\n\n### 为什么不用暴力法\n暴力法每删一个元素就要整体前移，是 O(n^2)；双指针一趟扫描 O(n)。', '2026-08-03 15:30:00', '2026-08-03 15:30:00'),

(@u_wangfang, 3, NULL,
'## 滑动窗口\n求「连续子数组」的极值问题，优先考虑滑动窗口。\n\n窗口用 `[start, end]` 表示，核心是**窗口内和 sum**：\n\n1. `end` 向右扩，把 nums[end] 加入 sum\n2. 当 `sum >= target` 时，窗口已经满足条件，先更新最小长度\n3. 然后不断收缩 `start`，直到 sum < target\n\n```java\npublic int minSubArrayLen(int target, int[] nums) {\n    int start = 0, sum = 0, ans = Integer.MAX_VALUE;\n    for (int end = 0; end < nums.length; end++) {\n        sum += nums[end];\n        while (sum >= target) {\n            ans = Math.min(ans, end - start + 1);\n            sum -= nums[start++];\n        }\n    }\n    return ans == Integer.MAX_VALUE ? 0 : ans;\n}\n```\n\n### 关键点\n- 窗口长度是 `end - start + 1`，别忘了 +1\n- 外层 for 只动 end，内层 while 动 start，**每个元素最多进出窗口一次**，所以整体是 O(n)\n- 答案初始化为最大值，最后要判断是否被更新过（可能无解返回 0）', '2026-08-05 09:40:00', '2026-08-06 11:20:00'),

(@u_liuyang, 4, NULL,
'## 反转链表：双指针\n反转的本质是把每个节点的 `next` 指针方向掉头。\n\n需要三个指针：\n- `prev`：已反转部分的头\n- `cur`：当前节点\n- `next`：先保存 cur.next，否则改完指针就找不到后面了\n\n```java\npublic ListNode reverseList(ListNode head) {\n    ListNode prev = null, cur = head;\n    while (cur != null) {\n        ListNode next = cur.next;  // 先存\n        cur.next = prev;           // 掉头\n        prev = cur;               // prev 前移\n        cur = next;               // cur 前移\n    }\n    return prev;\n}\n```\n\n循环结束时 `cur == null`，`prev` 正好指向新的头节点。', '2026-08-07 20:05:00', '2026-08-07 20:05:00'),

(@u_chenjie, 6, NULL,
'## 环形链表 II：快慢指针 + 数学推导\n\n### 第一步：判断有没有环\n快指针每次走 2 步，慢指针每次走 1 步。如果有环，两者一定会在环内相遇。\n\n### 第二步：找环的入口\n设头节点到环入口距离为 x，入口到相遇点为 y，相遇点回到入口为 z。\n- 慢指针走了 `x + y`\n- 快指针走了 `x + y + n(y + z)`\n\n快指针是慢指针的两倍：`x + y = n(y + z)`，整理得 `x = (n-1)(y+z) + z`。\n\n这说明：**从相遇点和从头节点同时出发、同速前进，一定会在环入口相遇**。\n\n```java\npublic ListNode detectCycle(ListNode head) {\n    ListNode slow = head, fast = head;\n    while (fast != null && fast.next != null) {\n        slow = slow.next;\n        fast = fast.next.next;\n        if (slow == fast) {\n            ListNode p = head;\n            while (p != slow) { p = p.next; slow = slow.next; }\n            return p;\n        }\n    }\n    return null;\n}\n```\n\n> 面试常问：为什么快指针走 2 步而不是 3 步？因为 2 步的相对速度是 1，保证一定能追上且不会跳过。', '2026-08-09 14:22:00', '2026-08-10 09:15:00'),

(@u_zhaomin, 12, NULL,
'## 有效的括号：栈的经典应用\n括号匹配是「后进先出」的典型场景。\n\n思路：遍历字符串，遇到左括号就压栈；遇到右括号就看栈顶是不是对应的左括号。\n\n```java\npublic boolean isValid(String s) {\n    Deque<Character> stack = new ArrayDeque<>();\n    for (char c : s.toCharArray()) {\n        if (c == (char)40) stack.push((char)41);\n        else if (c == (char)91) stack.push((char)93);\n        else if (c == (char)123) stack.push((char)125);\n        else if (stack.isEmpty() || stack.pop() != c) return false;\n    }\n    return stack.isEmpty();\n}\n```\n\n### 三个边界\n1. 左括号多了 → 遍历完栈不为空\n2. 右括号多了 → 栈空时还要 pop\n3. 类型不匹配 → pop 出来的和当前不等\n\n第 3 条最容易被忽略，一定要显式判断。', '2026-08-11 16:48:00', '2026-08-11 16:48:00'),

(@u_sunpeng, 14, NULL,
'## 二叉树的最大深度\n\n### 递归（后序）\n最大深度 = 左右子树最大深度 + 1。\n\n```java\npublic int maxDepth(TreeNode root) {\n    if (root == null) return 0;\n    return Math.max(maxDepth(root.left), maxDepth(root.right)) + 1;\n}\n```\n\n### 迭代（层序）\n用队列做 BFS，每处理完一层深度 +1。\n\n```java\npublic int maxDepthBFS(TreeNode root) {\n    if (root == null) return 0;\n    Queue<TreeNode> q = new LinkedList<>();\n    q.offer(root);\n    int depth = 0;\n    while (!q.isEmpty()) {\n        int size = q.size();\n        while (size-- > 0) {\n            TreeNode n = q.poll();\n            if (n.left != null) q.offer(n.left);\n            if (n.right != null) q.offer(n.right);\n        }\n        depth++;\n    }\n    return depth;\n}\n```\n\n> 求深度用**后序**（左右中，需要子树结果），求高度用后序；而前序适合求路径。', '2026-08-13 11:05:00', '2026-08-13 11:05:00'),

(@u_zhouxin, 16, NULL,
'## 爬楼梯：动态规划入门\n\n### 状态定义\ndp[i] = 爬到第 i 阶的方法数。\n\n### 转移方程\n最后一步要么从 i-1 爬 1 阶，要么从 i-2 爬 2 阶：\n`dp[i] = dp[i-1] + dp[i-2]`\n\n这其实就是**斐波那契数列**。\n\n```java\npublic int climbStairs(int n) {\n    if (n <= 2) return n;\n    int a = 1, b = 2;\n    for (int i = 3; i <= n; i++) {\n        int c = a + b;\n        a = b;\n        b = c;\n    }\n    return b;\n}\n```\n\n### 为什么可以滚动变量\ndp[i] 只依赖前两项，不需要整个数组，空间可以压到 O(1)。', '2026-08-15 19:30:00', '2026-08-15 19:30:00'),

(@u_wulei, 19, NULL,
'## 二分查找：区间的开闭是关键\n\n最容易写错的不是逻辑，而是**边界约定**。这里统一用「左闭右闭」`[left, right]`：\n\n```java\npublic int search(int[] nums, int target) {\n    int left = 0, right = nums.length - 1;   // 右闭\n    while (left <= right) {                  // 闭区间要用 <=\n        int mid = left + (right - left) / 2; // 防止溢出\n        if (nums[mid] == target) return mid;\n        else if (nums[mid] < target) left = mid + 1;\n        else right = mid - 1;\n    }\n    return -1;\n}\n```\n\n### 三个细节\n1. `left <= right`：因为是闭区间，`left == right` 时仍要检查\n2. `mid = left + (right-left)/2`：等价于 `(left+right)/2` 但避免 int 溢出\n3. `left = mid + 1` / `right = mid - 1`：mid 已排除，不要再包含\n\n### 左闭右开写法\n`right = nums.length`，循环条件 `left < right`，且 `right = mid`。两种写法不要混用。', '2026-08-17 08:50:00', '2026-08-18 10:30:00'),

(@u_zhengshuang, 22, NULL,
'## 水果成篮：最长子数组，最多两种元素\n\n可以转换成：**求最长的、只包含不超过 2 种数字的连续子数组**。\n\n滑动窗口 + 哈希表计数：\n\n```java\npublic int totalFruit(int[] fruits) {\n    Map<Integer, Integer> cnt = new HashMap<>();\n    int left = 0, ans = 0;\n    for (int right = 0; right < fruits.length; right++) {\n        cnt.merge(fruits[right], 1, Integer::sum);\n        while (cnt.size() > 2) {\n            int k = fruits[left++];\n            cnt.merge(k, -1, Integer::sum);\n            if (cnt.get(k) == 0) cnt.remove(k);\n        }\n        ans = Math.max(ans, right - left + 1);\n    }\n    return ans;\n}\n```\n\n> 关键：计数减到 0 要**从 map 里移除**，否则 `cnt.size()` 不会变小，死循环。', '2026-08-19 15:12:00', '2026-08-19 15:12:00'),

(@u_xulei, 33, NULL,
'## 三数之和：排序 + 双指针 + 去重\n\n暴力三重循环是 O(n^3)，排序后用双指针可以降到 O(n^2)。\n\n步骤：\n1. 排序\n2. 固定 `i`，在 `[i+1, n-1]` 区间用左右指针找两数之和为 `-nums[i]`\n3. 三处去重：`i`、`left`、`right`\n\n```java\npublic List<List<Integer>> threeSum(int[] nums) {\n    Arrays.sort(nums);\n    List<List<Integer>> res = new ArrayList<>();\n    for (int i = 0; i < nums.length - 2; i++) {\n        if (nums[i] > 0) break;                       // 已排序，后面不可能凑 0\n        if (i > 0 && nums[i] == nums[i - 1]) continue; // 对 i 去重\n        int l = i + 1, r = nums.length - 1;\n        while (l < r) {\n            int sum = nums[i] + nums[l] + nums[r];\n            if (sum < 0) l++;\n            else if (sum > 0) r--;\n            else {\n                res.add(List.of(nums[i], nums[l], nums[r]));\n                while (l < r && nums[l] == nums[l + 1]) l++;\n                while (l < r && nums[r] == nums[r - 1]) r--;\n                l++; r--;\n            }\n        }\n    }\n    return res;\n}\n```\n\n### 去重逻辑为什么这么写\n`nums[i] == nums[i-1]` 说明这个值作为第一个数已经枚举过，再枚举只会得到重复的三元组。左右指针同理。', '2026-08-21 21:08:00', '2026-08-22 09:44:00'),

(@u_hejuan, 39, NULL,
'## 滑动窗口最大值：单调队列\n\n暴力法每次窗口求最大值是 O(nk)。用**单调递减队列**可以做到 O(n)。\n\n队列里存下标，保证对应的值单调递减：\n\n```java\npublic int[] maxSlidingWindow(int[] nums, int k) {\n    Deque<Integer> dq = new ArrayDeque<>();\n    int[] res = new int[nums.length - k + 1];\n    for (int i = 0; i < nums.length; i++) {\n        // 1. 队头如果已经滑出窗口就弹出\n        if (!dq.isEmpty() && dq.peekFirst() <= i - k) dq.pollFirst();\n        // 2. 队尾比当前小的都弹掉，保持单调递减\n        while (!dq.isEmpty() && nums[dq.peekLast()] < nums[i]) dq.pollLast();\n        dq.offerLast(i);\n        // 3. 窗口形成后记录队头\n        if (i >= k - 1) res[i - k + 1] = nums[dq.peekFirst()];\n    }\n    return res;\n}\n```\n\n> 队头始终是当前窗口的最大值。每个下标最多进出队一次，所以是 O(n)。', '2026-08-23 13:26:00', '2026-08-23 13:26:00'),

(@u_guoyu, 41, NULL,
'## 二叉树层序遍历：BFS 模板\n\n层序遍历必须用**队列**，而且要用 `size` 锁定当前层的节点数。\n\n```java\npublic List<List<Integer>> levelOrder(TreeNode root) {\n    List<List<Integer>> res = new ArrayList<>();\n    if (root == null) return res;\n    Queue<TreeNode> q = new LinkedList<>();\n    q.offer(root);\n    while (!q.isEmpty()) {\n        int size = q.size();          // 关键：先记住这一层有多少个\n        List<Integer> level = new ArrayList<>();\n        while (size-- > 0) {\n            TreeNode n = q.poll();\n            level.add(n.val);\n            if (n.left != null) q.offer(n.left);\n            if (n.right != null) q.offer(n.right);\n        }\n        res.add(level);\n    }\n    return res;\n}\n```\n\n### 为什么必须用 size\n如果在 while 里直接 `q.size()`，那么每加入下一层节点队列长度就变了，会把两层混在一起。\n\n### 举一反三\n这个模板稍作修改就能解：层序自底向上、右视图、每层平均值、最大宽度。', '2026-08-25 10:18:00', '2026-08-26 14:02:00'),

(@u_maqiang, 51, NULL,
'## 01 背包：动态规划的经典模型\n\n### 状态定义\ndp[j] = 容量为 j 的背包能装的最大价值。\n\n### 转移方程\n对每件物品 i（体积 v[i]、价值 w[i]）：\n`dp[j] = max(dp[j], dp[j - v[i]] + w[i])`\n\n### 一维数组为什么必须倒序遍历\n```java\nfor (int i = 0; i < n; i++) {\n    for (int j = V; j >= v[i]; j--) {   // 倒序！\n        dp[j] = Math.max(dp[j], dp[j - v[i]] + w[i]);\n    }\n}\n```\n\n如果正序遍历，`dp[j - v[i]]` 会是**本轮已经更新过**的值，相当于同一件物品被放多次，那就变成了完全背包。\n\n### 记忆口诀\n- 01 背包：**倒序**，每件物品只用一次\n- 完全背包：**正序**，每件物品可用无限次\n\n这一点面试非常爱考。', '2026-08-27 20:40:00', '2026-08-28 11:15:00'),

(@u_linna, 52, NULL,
'## 零钱兑换：完全背包求最小值\n\n### 状态定义\ndp[j] = 凑出金额 j 所需的最少硬币数。\n\n### 初始化\ndp[0] = 0（凑 0 元需要 0 枚），其余初始化为一个「不可能的大值」。\n\n```java\npublic int coinChange(int[] coins, int amount) {\n    int MAX = amount + 1;             // 比任何合法答案都大\n    int[] dp = new int[amount + 1];\n    Arrays.fill(dp, MAX);\n    dp[0] = 0;\n    for (int coin : coins) {\n        for (int j = coin; j <= amount; j++) {   // 正序 = 完全背包\n            dp[j] = Math.min(dp[j], dp[j - coin] + 1);\n        }\n    }\n    return dp[amount] == MAX ? -1 : dp[amount];\n}\n```\n\n### 两个易错点\n1. 初始化用 `amount + 1` 而不是 `Integer.MAX_VALUE`，否则 `dp[j-coin] + 1` 会整数溢出\n2. 最后要判断是否仍为初始值，是则说明凑不出来，返回 -1', '2026-08-29 16:55:00', '2026-08-29 16:55:00'),

(@u_zhangwei, 53, NULL,
'## 最长递增子序列\n\n### 解法一：动态规划 O(n^2)\n`dp[i]` = 以 nums[i] **结尾**的最长递增子序列长度。\n\n```java\nfor (int i = 1; i < n; i++) {\n    for (int j = 0; j < i; j++) {\n        if (nums[j] < nums[i]) dp[i] = Math.max(dp[i], dp[j] + 1);\n    }\n    ans = Math.max(ans, dp[i]);\n}\n```\n\n注意答案不是 `dp[n-1]`，而是所有 dp 的最大值。\n\n### 解法二：贪心 + 二分 O(n log n)\n维护一个数组 `tails`，`tails[k]` 表示长度为 k+1 的递增子序列的**最小结尾**。遍历时用二分找到第一个 >= nums[i] 的位置替换。\n\n```java\nint[] tails = new int[n];\nint len = 0;\nfor (int x : nums) {\n    int l = 0, r = len;\n    while (l < r) {\n        int mid = (l + r) >>> 1;\n        if (tails[mid] < x) l = mid + 1;\n        else r = mid;\n    }\n    tails[l] = x;\n    if (l == len) len++;\n}\nreturn len;\n```\n\n> tails 数组本身并不是某个合法的 LIS，它只记录「长度为 k 时最小的结尾」，这样才能让后续更容易接上。', '2026-08-31 09:12:00', '2026-09-01 19:30:00'),

(@u_lina, 59, NULL,
'## N 皇后：回溯 + 剪枝\n\n一行只放一个皇后，所以按行递归。用三个集合记录已被占用的列和两个方向的对角线。\n\n- 主对角线（左上到右下）：`row - col` 是常数\n- 副对角线（右上到左下）：`row + col` 是常数\n\n```java\npublic List<List<String>> solveNQueens(int n) {\n    List<List<String>> res = new ArrayList<>();\n    Set<Integer> col = new HashSet<>(), d1 = new HashSet<>(), d2 = new HashSet<>();\n    int[] pos = new int[n];\n    dfs(0, n, pos, col, d1, d2, res);\n    return res;\n}\n\nprivate void dfs(int row, int n, int[] pos, Set<Integer> col,\n                 Set<Integer> d1, Set<Integer> d2, List<List<String>> res) {\n    if (row == n) { res.add(build(pos, n)); return; }\n    for (int c = 0; c < n; c++) {\n        if (col.contains(c) || d1.contains(row - c) || d2.contains(row + c)) continue;\n        col.add(c); d1.add(row - c); d2.add(row + c); pos[row] = c;\n        dfs(row + 1, n, pos, col, d1, d2, res);\n        col.remove(c); d1.remove(row - c); d2.remove(row + c);  // 回溯\n    }\n}\n```\n\n### 剪枝效果\n不加剪枝要枚举 n^n 种摆法；按行 + 列/对角线判重后，n=8 时解只有 92 个，搜索空间大幅缩小。', '2026-09-03 14:20:00', '2026-09-03 14:20:00');
