# 卡码笔记（kamanotes）后端接口文档

> 本文档依据 `backend/src/main/java/com/kama/notes` 下的 Controller / DTO / VO 源码逐接口核对生成。
> 覆盖全部 **16 个 Controller、67 个 HTTP 接口**（含本次新增的「笔记分类」模块）。

- **文档版本**：v1.1
- **后端**：Spring Boot 2.7.18 · Spring Security · MyBatis · MySQL 8.0 · Redis
- **统一前缀**：`/api`

---

## 1. 通用约定

### 1.1 服务地址

| 项 | 值 |
| --- | --- |
| 配置项 | `server.port`（`application.yaml`） |
| 配置默认值 | `8080` |
| 本机当前开发环境 | `http://127.0.0.1:8081`（启动时以 `--server.port=8081` 覆盖；`frontend/.env.development` 亦指向 8081） |
| 数据库 | `kamanote_tech`（MySQL 8.0） |
| 跨域白名单 | `http://localhost:5173`、`http://127.0.0.1:5173`（`WebConfig`） |

请求地址格式：`{BaseURL}/api/{resource}`，例如 `http://127.0.0.1:8081/api/notes`。

### 1.2 统一响应结构

绝大多数接口返回如下 JSON（`ApiResponse`）：

```json
{
  "code": 200,
  "message": "获取笔记列表成功",
  "data": {}
}
```

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `code` | integer | 业务码，`200` 表示成功，其它表示失败 |
| `message` | string | 提示信息 |
| `data` | any | 业务数据，可能为对象、数组或 `null` |

**分页响应**（`PaginationApiResponse`）在上述基础上多一个 `pagination`：

```json
{
  "code": 200,
  "message": "获取笔记列表成功",
  "data": [],
  "pagination": { "page": 1, "pageSize": 10, "total": 42 }
}
```

**登录类响应**（`TokenApiResponse`）额外带 `token`（顶层字段）：

```json
{
  "code": 200,
  "message": "登录成功",
  "data": { "userId": 1, "username": "testuser" },
  "token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

**空响应**（`EmptyVO`）：`data` 为 `{ "empty": true }`。

> ⚠️ **重要**：业务成功与业务失败都返回 **HTTP 200**，请以 body 中的 `code` 判断结果。
> 仅以下情况会返回非 200 的真实 HTTP 状态码：
> - 请求路径未匹配任何接口 → **HTTP 404**（Spring 默认错误页，非统一结构）
> - 请求非 `/api/**` 路径 → **HTTP 403**（被 Spring Security 的 `.anyRequest().authenticated()` 拦截）

### 1.3 鉴权

- **方式**：JWT Bearer Token，放在请求头
  ```
  Authorization: Bearer {token}
  ```
- **获取**：`POST /api/users/login` 或 `POST /api/users/whoami` 返回的 `token` 字段。
- **校验**：`TokenInterceptor` 拦截 `/**`（排除 `/login`、`/error`），解析 token 并写入请求级上下文 `RequestScopeData`。
- **强制登录**：Service / Controller 方法上的 `@NeedLogin` 注解（切面 `NeedLoginAspect`）。
  - 未登录时返回 `{ "code": 400, "message": "用户未登录" }`。
  - 部分接口未标注 `@NeedLogin`，但实现内部依赖 `RequestScopeData.getUserId()`，**实际也需登录**（文档中已标注）。

### 1.4 分页约定

| 参数 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `page` | integer | 1 | 页码，从 1 开始 |
| `pageSize` | integer | 10（部分接口 20） | 每页条数，上限一般 100~200 |

分页接口的 `total` 为满足条件的总记录数（`SELECT COUNT(*)` 结果）。

### 1.5 参数校验与错误

校验失败由 `ParamExceptionHandler` 统一处理，返回 `code = 400`：

```json
{
  "code": 400,
  "message": "Validation Failed",
  "data": {
    "password": "密码长度必须在 6 到 32 个字符之间"
  }
}
```

- `@RequestBody` 校验失败（`MethodArgumentNotValidException`）→ `data` 为 `{字段名: 错误信息}`
- `@PathVariable` / `@RequestParam` 校验失败（`ConstraintViolationException`）→ 同样结构
- 未捕获异常 → `{ "code": 500, "message": "Internal Server Error", "data": "异常信息" }`

### 1.6 枚举字典

| 枚举 | 取值 | 含义 |
| --- | --- | --- |
| `gender` | `1` / `2` / `3` | 男 / 女 / 保密 |
| `isAdmin` | `0` / `1` | 普通用户 / 管理员 |
| `isBanned` | `0` / `1` | 正常 / 封禁 |
| `question.difficulty` | `1` / `2` / `3` | 简单 / 中等 / 困难（前端按 1~3 渲染） |
| `questionList.type` | `1` / `2` | 普通题单 / 训练营题单 |
| `message.type` | `1` / `2` / `3` | 点赞 / 评论 / 系统 |
| `message.targetType` | `1` / `2` | 笔记 / 评论 |

### 1.7 静态资源

| 接口 | 说明 |
| --- | --- |
| `GET /images/{filename}` | 访问已上传的文件。映射到 `upload.path`（`${user.dir}/tmp/uploads`），由 `WebConfig` 注册，**不在 `/api` 前缀下** |

---

## 2. 接口总览（速查表）

| 模块 | 方法 | 路径 | 说明 | 鉴权 |
| --- | --- | --- | --- | --- |
| 用户 | POST | `/api/users` | 用户注册 | 公开 |
| 用户 | POST | `/api/users/login` | 登录（返回 token） | 公开 |
| 用户 | POST | `/api/users/whoami` | 自动登录/获取当前用户（返回新 token） | 需 token |
| 用户 | GET | `/api/users/{userId}` | 查询指定用户信息 | 公开 |
| 用户 | PATCH | `/api/users/me` | 更新当前用户信息 | 需登录 |
| 用户 | POST | `/api/users/avatar` | 上传头像 | 公开* |
| 用户 | GET | `/api/admin/users` | 管理端用户列表 | 公开* |
| **笔记分类** | GET | `/api/note-categories` | 笔记分类列表 | 公开 |
| **笔记分类** | POST | `/api/note-categories` | 创建笔记分类 | 需登录 |
| 笔记 | GET | `/api/notes` | 笔记列表（可按分类/题目/作者/收藏夹筛选） | 公开 |
| 笔记 | POST | `/api/notes` | 发布笔记（题目笔记 **或** 分类笔记） | 需登录 |
| 笔记 | PATCH | `/api/notes/{noteId}` | 更新笔记内容 | 需登录 |
| 笔记 | DELETE | `/api/notes/{noteId}` | 删除笔记 | 需登录 |
| 笔记 | GET | `/api/notes/download` | 导出题目笔记为 Markdown | 需登录 |
| 笔记 | GET | `/api/notes/ranklist` | 今日笔记排行榜 Top10 | 公开 |
| 笔记 | GET | `/api/notes/heatmap` | 个人提交热力图（近 94 天） | 需登录 |
| 笔记 | GET | `/api/notes/top3count` | 本月/上月进入日榜 Top3 的次数 | 需登录 |
| 点赞 | POST | `/api/like/note/{noteId}` | 点赞笔记 | 需登录 |
| 点赞 | DELETE | `/api/like/note/{noteId}` | 取消点赞笔记 | 需登录 |
| 收藏夹 | GET | `/api/collections` | 收藏夹列表 | 公开 |
| 收藏夹 | POST | `/api/collections` | 创建收藏夹 | 需登录 |
| 收藏夹 | DELETE | `/api/collections/{collectionId}` | 删除收藏夹 | 需登录 |
| 收藏夹 | POST | `/api/collections/batch` | 批量收藏/取消收藏 | 需登录 |
| 评论 | GET | `/api/comments` | 评论列表（含二级回复） | 公开 |
| 评论 | POST | `/api/comments` | 发表评论/回复 | 需登录 |
| 评论 | PATCH | `/api/comments/{commentId}` | 修改评论 | 需登录 |
| 评论 | DELETE | `/api/comments/{commentId}` | 删除评论 | 需登录 |
| 评论 | POST | `/api/comments/{commentId}/like` | 点赞评论 | 需登录 |
| 评论 | DELETE | `/api/comments/{commentId}/like` | 取消点赞评论 | 需登录 |
| 题目分类 | GET | `/api/categories` | 分类树（用户端） | 公开 |
| 题目分类 | GET | `/api/admin/categories` | 分类树（管理端） | 公开* |
| 题目分类 | POST | `/api/admin/categories` | 创建分类 | 公开* |
| 题目分类 | PATCH | `/api/admin/categories/{categoryId}` | 重命名分类 | 公开* |
| 题目分类 | DELETE | `/api/admin/categories/{categoryId}` | 删除分类及其题目 | 公开* |
| 题目 | GET | `/api/questions` | 用户端题目列表 | 公开 |
| 题目 | POST | `/api/questions/search` | 关键词搜索题目 | 公开 |
| 题目 | GET | `/api/questions/{questionId}` | 题目详情 + 我的笔记 | 公开 |
| 题目 | GET | `/api/admin/questions` | 管理端题目列表 | 公开* |
| 题目 | POST | `/api/admin/questions` | 创建题目 | 公开* |
| 题目 | POST | `/api/admin/questions/batch` | 按 Markdown 批量创建题目 | 公开* |
| 题目 | PATCH | `/api/admin/questions/{questionId}` | 更新题目 | 公开* |
| 题目 | DELETE | `/api/admin/questions/{questionId}` | 删除题目 | 公开* |
| 题单 | GET | `/api/admin/questionlists` | 题单列表 | 公开* |
| 题单 | GET | `/api/admin/questionlists/{questionListId}` | 题单详情 | 公开* |
| 题单 | POST | `/api/admin/questionlists` | 创建题单 | 公开* |
| 题单 | PATCH | `/api/admin/questionlists/{questionListId}` | 更新题单 | 公开* |
| 题单 | DELETE | `/api/admin/questionlists/{questionListId}` | 删除题单 | 公开* |
| 题单项 | GET | `/api/questionlist-items` | 题单内题目列表（用户端，含完成状态） | 公开 |
| 题单项 | GET | `/api/admin/questionlist-items/{questionListId}` | 题单内题目列表（管理端） | 公开* |
| 题单项 | POST | `/api/admin/questionlist-items` | 添加题目到题单 | 公开* |
| 题单项 | DELETE | `/api/admin/questionlist-items/{questionListId}/{questionId}` | 从题单移除题目 | 公开* |
| 题单项 | PATCH | `/api/admin/questionlist-items/sort` | 调整题单内排序 | 公开* |
| 消息 | GET | `/api/messages` | 我的消息列表 | 需登录 |
| 消息 | PATCH | `/api/messages/{messageId}/read` | 标记单条已读 | 需登录* |
| 消息 | PATCH | `/api/messages/all/read` | 全部标记已读 | 需登录* |
| 消息 | PATCH | `/api/messages/batch/read` | 批量标记已读 | 需登录* |
| 消息 | DELETE | `/api/messages/{messageId}` | 删除消息 | 需登录* |
| 消息 | GET | `/api/messages/unread/count` | 未读消息数 | 需登录* |
| 搜索 | GET | `/api/search/notes` | 全文检索笔记（MySQL 全文索引） | 公开 |
| 搜索 | GET | `/api/search/users` | 搜索用户 | 公开 |
| 搜索 | GET | `/api/search/notes/tag` | 按标签搜索笔记 | ⚠️ 不可用 |
| 统计 | GET | `/api/statistic` | 平台统计数据 | 公开 |
| 上传 | POST | `/api/upload/image` | 上传图片（编辑器插图） | 公开 |
| 邮件 | GET | `/api/email/verify-code` | 发送邮箱验证码 | 公开 |
| 测试 | GET | `/api/hello` | 连通性测试 | 公开 |
| 测试 | GET | `/api/exception` | 异常处理测试 | 公开 |

> **`公开*`**：当前代码未加 `@NeedLogin`，**任何未登录用户都能调用**（含 `/api/admin/**` 管理端接口）。这是现有的权限缺口，生产环境需补上管理员校验。
> **`需登录*`**：未标注 `@NeedLogin`，但实现依赖 `RequestScopeData.getUserId()`，未登录会得到 `code = 400` 或空结果。

---

## 3. 认证与用户

### 3.1 用户注册

- **接口**：`POST /api/users`
- **鉴权**：公开

**请求体**

| 字段 | 类型 | 必填 | 约束 |
| --- | --- | --- | --- |
| `account` | string | 是 | 6~32 字符，仅字母/数字/下划线，需唯一 |
| `username` | string | 是 | 1~16 字符，中文/字母/数字/下划线/`-`/`.` |
| `password` | string | 是 | 6~32 字符 |
| `email` | string | 否 | 邮箱格式 |
| `verifyCode` | string | 否 | 填写 `email` 时为 6 位验证码 |

```json
{
  "account": "kamatest10001",
  "username": "卡码测试",
  "password": "kama123456"
}
```

**响应**（`TokenApiResponse` —— **注册成功即返回 token，可直接当登录态使用**）

```json
{
  "code": 200,
  "message": "注册成功",
  "data": { "userId": 12 },
  "token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

`data` 结构（`RegisterVO`）：`userId` (long)。

**失败**

| 场景 | 响应 `message` |
| --- | --- |
| 账号已存在 | `账号重复` |
| 邮箱已被使用 | `邮箱已被使用` |
| 填了 `email` 却没填 `verifyCode` | `请提供邮箱验证码` |
| 验证码错误/已过期 | `验证码无效或已过期` |
| 其它异常 | `注册失败，请稍后再试` |

### 3.2 登录

- **接口**：`POST /api/users/login`
- **鉴权**：公开
- **说明**：`account` 与 `email` **至少提供一个**（`@AssertTrue` 校验）。

**请求体**

| 字段 | 类型 | 必填 | 约束 |
| --- | --- | --- | --- |
| `account` | string | 二选一 | 6~32 字符，仅字母/数字/下划线 |
| `email` | string | 二选一 | 邮箱格式 |
| `password` | string | 是 | 6~32 字符 |

```json
{ "account": "kamatest10001", "password": "kama123456" }
```

**响应**（`TokenApiResponse`，`token` 在顶层）

```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "userId": 12,
    "account": "kamatest10001",
    "username": "卡码测试",
    "gender": 3,
    "birthday": null,
    "avatarUrl": null,
    "email": null,
    "school": null,
    "signature": null,
    "isAdmin": 0
  },
  "token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

`data` 结构（`LoginUserVO`）：`userId`、`account`、`username`、`gender`、`birthday`、`avatarUrl`、`email`、`school`、`signature`、`isAdmin`。

**失败**

| 场景 | 响应 `message` |
| --- | --- |
| 账号与邮箱都未提供 | `请提供账号或邮箱` |
| 用户不存在 | `用户不存在` |
| 密码错误 | `密码错误` |

### 3.3 自动登录 / 获取当前用户

- **接口**：`POST /api/users/whoami`
- **鉴权**：需携带有效 token
- **说明**：根据 token 中的 userId 返回用户信息，并**签发新 token**、刷新 `last_login_at`。

**响应**：同 3.2，`message` 为 `自动登录成功`。

### 3.4 查询指定用户信息

- **接口**：`GET /api/users/{userId}`
- **鉴权**：公开

| 参数 | 位置 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- | --- |
| `userId` | path | long | 是 | 必须为纯数字 |

**响应 `data`**（`UserVO`）：`username`、`gender`、`avatarUrl`、`email`、`school`、`signature`、`lastLoginAt`。

### 3.5 更新当前用户信息

- **接口**：`PATCH /api/users/me`
- **鉴权**：需登录（`@NeedLogin`）
- **说明**：仅更新请求体中出现的字段。

**请求体**（`UpdateUserRequest`，均可选）

| 字段 | 类型 | 约束 |
| --- | --- | --- |
| `username` | string | 1~16 字符，中文/字母/数字/下划线 |
| `gender` | integer | 1~3 |
| `birthday` | date | `yyyy-MM-dd` |
| `avatarUrl` | string | 必须以 `http(s)://` 或 `ftp://` 开头 |
| `email` | string | 邮箱格式 |
| `school` | string | ≤64 字符 |
| `signature` | string | ≤128 字符 |

**响应**：`{ "code": 200, "message": "更新成功", "data": { "empty": true } }`

### 3.6 上传头像

- **接口**：`POST /api/users/avatar`
- **鉴权**：公开（当前未做登录校验）
- **Content-Type**：`multipart/form-data`

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `file` | file | 是 | 头像图片，单文件 ≤50MB |

**响应**：`{ "code": 200, "message": "上传成功", "data": { "url": "/images/xxx.png" } }`

### 3.7 管理端用户列表

- **接口**：`GET /api/admin/users`
- **鉴权**：公开（当前未校验管理员）

**Query 参数**（`UserQueryParam`）

| 字段 | 类型 | 必填 | 约束 |
| --- | --- | --- | --- |
| `userId` | long | 否 | ≥1 |
| `account` | string | 否 | 精确匹配 |
| `username` | string | 否 | 精确匹配 |
| `isAdmin` | integer | 否 | 0/1 |
| `isBanned` | integer | 否 | 0/1 |
| `page` | integer | 是 | ≥1 |
| `pageSize` | integer | 是 | 1~200 |

**响应**：分页响应，`data` 为 `User` 实体数组（**含 `password` 字段，注意脱敏**）。

---

## 4. 笔记分类（本次新增）

> 笔记分类**独立于题目分类**（`category` 表）。用于给「不绑定题目」的笔记按技术主题归类，例如 Redis / SQL / MQ。
> 数据表：`note_category`（`category_id`、`name`、`created_at`、`updated_at`，`name` 唯一）。

### 4.1 获取笔记分类列表

- **接口**：`GET /api/note-categories`
- **鉴权**：公开
- **说明**：返回全部笔记分类，按 `category_id` 升序。

**响应**

```json
{
  "code": 200,
  "message": "获取笔记分类列表成功",
  "data": [
    { "categoryId": 1, "name": "Redis" },
    { "categoryId": 2, "name": "MySQL" },
    { "categoryId": 3, "name": "SQL" },
    { "categoryId": 4, "name": "MQ" }
  ]
}
```

`data` 元素结构（`NoteCategoryVO`）：`categoryId` (integer)、`name` (string)。

> 初始化分类（`seed.sql`）：Redis、MySQL、SQL、MQ、Java、Spring、JVM、计算机网络、操作系统、数据结构与算法、其他。

### 4.2 创建笔记分类

- **接口**：`POST /api/note-categories`
- **鉴权**：需登录（`@NeedLogin`）
- **说明**：名称会 `trim`；**同名分类不会重复创建**，直接返回已存在的那条（`message` 为 `该分类已存在`）。

**请求体**（`CreateNoteCategoryBody`）

| 字段 | 类型 | 必填 | 约束 |
| --- | --- | --- | --- |
| `name` | string | 是 | 非空，≤64 字符 |

```json
{ "name": "Docker" }
```

**响应**

```json
{ "code": 200, "message": "创建笔记分类成功", "data": { "categoryId": 12, "name": "Docker" } }
```

---

## 5. 笔记

> 笔记有两种归属形态，由 `question_id` / `category_id` 区分：
> - **题目笔记**：`question_id` 非空，`category_id` 为空（原有能力）
> - **分类笔记**：`category_id` 非空，`question_id` 为空（本次新增）
>
> 创建时二者**至少提供一个**。

### 5.1 笔记列表

- **接口**：`GET /api/notes`
- **鉴权**：公开（未登录时不返回点赞/收藏状态）
- **返回**：分页响应

**Query 参数**（`NoteQueryParams`）

| 字段 | 类型 | 必填 | 默认 | 约束 | 说明 |
| --- | --- | --- | --- | --- | --- |
| `questionId` | integer | 否 | — | ≥1 | 按题目筛选 |
| `categoryId` | integer | 否 | — | ≥1 | **按笔记分类筛选（新增）** |
| `authorId` | long | 否 | — | ≥1 | 按作者筛选 |
| `collectionId` | integer | 否 | — | ≥1 | 按收藏夹筛选 |
| `sort` | string | 否 | — | 仅 `create` | 排序字段 |
| `order` | string | 否 | `ASC` | `asc` / `desc` | 排序方向 |
| `recentDays` | integer | 否 | — | 1~365 | 只取最近 N 天 |
| `page` | integer | 否 | 1 | 1~10000 | 页码 |
| `pageSize` | integer | 否 | 10 | 1~200 | 每页条数 |

**请求示例**

```
GET /api/notes?categoryId=1&page=1&pageSize=10
GET /api/notes?questionId=3&page=1&pageSize=10
GET /api/notes?sort=create&order=desc&recentDays=7&page=1&pageSize=10
```

**响应**

```json
{
  "code": 200,
  "message": "获取笔记列表成功",
  "data": [
    {
      "noteId": 3,
      "categoryId": 1,
      "content": "# Redis 缓存穿透\n...",
      "needCollapsed": true,
      "displayContent": "# Redis 缓存穿透...",
      "likeCount": 0,
      "commentCount": 0,
      "collectCount": 0,
      "createdAt": "2026-09-10T15:53:33",
      "author": { "userId": 12, "username": "卡码测试", "avatarUrl": null },
      "userActions": { "isLiked": false, "isCollected": false },
      "question": null,
      "category": { "categoryId": 1, "name": "Redis" }
    }
  ],
  "pagination": { "page": 1, "pageSize": 10, "total": 1 }
}
```

**`data` 元素结构（`NoteVO`）**

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `noteId` | integer | 笔记 ID |
| `categoryId` | integer\|null | 笔记分类 ID（**新增**） |
| `content` | string | 完整内容（Markdown） |
| `needCollapsed` | boolean | 是否过长需要折叠 |
| `displayContent` | string\|null | 折叠时展示的摘要 |
| `likeCount` / `commentCount` / `collectCount` | integer | 点赞/评论/收藏数 |
| `createdAt` | datetime | 创建时间 |
| `author` | object\|null | `{ userId, username, avatarUrl }` |
| `userActions` | object | `{ isLiked, isCollected }` |
| `question` | object\|null | `{ questionId, title }`；分类笔记为 `null` |
| `category` | object\|null | `{ categoryId, name }`；题目笔记为 `null`（**新增**） |

### 5.2 发布笔记

- **接口**：`POST /api/notes`
- **鉴权**：需登录（`@NeedLogin`）

**请求体**（`CreateNoteRequest`）

| 字段 | 类型 | 必填 | 约束 | 说明 |
| --- | --- | --- | --- | --- |
| `content` | string | 是 | 非空 | 笔记内容（Markdown） |
| `questionId` | integer | 否 | ≥1 | 题目 ID，**与 `categoryId` 至少填一个** |
| `categoryId` | integer | 否 | ≥1 | 笔记分类 ID（**新增**） |

**请求示例**

```json
// 分类笔记（不绑定题目）
{ "content": "# Redis 缓存穿透", "categoryId": 1 }

// 题目笔记（原有用法）
{ "content": "滑动窗口解法...", "questionId": 3 }
```

**响应**

```json
{ "code": 200, "message": "创建笔记成功", "data": { "noteId": 4 } }
```

**失败**

| 场景 | 响应 |
| --- | --- |
| 两个 ID 都未提供 | `{ "code": 400, "message": "请指定笔记所属的题目或笔记分类" }` |
| `questionId` 不存在 | `{ "code": 400, "message": "questionId 对应的问题不存在" }` |
| `categoryId` 不存在 | `{ "code": 400, "message": "categoryId 对应的笔记分类不存在" }` |
| 未登录 | `{ "code": 400, "message": "用户未登录" }` |

### 5.3 更新笔记

- **接口**：`PATCH /api/notes/{noteId}`
- **鉴权**：需登录，且仅笔记作者可改

| 参数 | 位置 | 类型 |
| --- | --- | --- |
| `noteId` | path | integer，≥1 |

**请求体**（`UpdateNoteRequest`）：`content` (string, 必填，非空)

**响应**：`{ "code": 200, "message": "更新笔记成功", "data": { "empty": true } }`

**失败**：笔记不存在 → `笔记不存在`；非作者 → `没有权限修改别人的笔记`。

### 5.4 删除笔记

- **接口**：`DELETE /api/notes/{noteId}`
- **鉴权**：需登录，且仅笔记作者可删
- **响应**：`{ "code": 200, "message": "删除笔记成功", "data": { "empty": true } }`

### 5.5 下载笔记（导出 Markdown）

- **接口**：`GET /api/notes/download`
- **鉴权**：需登录
- **说明**：把当前用户**绑定了题目**的笔记，按「题目分类 → 题目」层级拼成一个 Markdown 文档。
  ⚠️ **分类笔记（无题目）不参与导出**；若用户只有分类笔记，返回 `不存在可导出的题目笔记`。

**响应**：`{ "code": 200, "message": "生成笔记成功", "data": { "markdown": "# 数组\n## ..." } }`

### 5.6 今日笔记排行榜

- **接口**：`GET /api/notes/ranklist`
- **鉴权**：公开
- **说明**：按当天笔记数排名，取前 10 名。

**响应 `data` 元素**（`NoteRankListItem`）：`userId`、`username`、`avatarUrl`、`noteCount`、`rank`。

### 5.7 个人提交热力图

- **接口**：`GET /api/notes/heatmap`
- **鉴权**：需登录（`@NeedLogin`）
- **说明**：返回当前用户近 **94 天**每日笔记数及当日排名。

**响应 `data` 元素**（`NoteHeatMapItem`）：`date` (date)、`count` (integer)、`rank` (integer)。

### 5.8 本月/上月 Top3 次数

- **接口**：`GET /api/notes/top3count`
- **鉴权**：需登录（`@NeedLogin`）

**响应**：`{ "code": 200, "data": { "lastMonthTop3Count": 0, "thisMonthTop3Count": 1 } }`

---

## 6. 笔记点赞

### 6.1 点赞笔记

- **接口**：`POST /api/like/note/{noteId}`
- **鉴权**：需登录（`@NeedLogin`）
- **参数**：`noteId` (path, integer)
- **响应**：`{ "code": 200, "message": "点赞成功", "data": { "empty": true } }`

### 6.2 取消点赞笔记

- **接口**：`DELETE /api/like/note/{noteId}`
- **鉴权**：需登录（`@NeedLogin`）
- **响应**：`{ "code": 200, "message": "取消点赞成功", "data": { "empty": true } }`

---

## 7. 收藏夹

### 7.1 收藏夹列表

- **接口**：`GET /api/collections`
- **鉴权**：公开

**Query 参数**（`CollectionQueryParams`）

| 字段 | 类型 | 必填 | 约束 | 说明 |
| --- | --- | --- | --- | --- |
| `creatorId` | long | **是** | ≥1 | 收藏夹所属用户 |
| `noteId` | integer | 否 | ≥1 | 传入后会附带「该笔记是否在此收藏夹中」状态 |

**响应 `data` 元素**（`CollectionVO`）

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `collectionId` | integer | 收藏夹 ID |
| `name` | string | 名称 |
| `description` | string | 描述 |
| `noteStatus` | object\|null | `{ noteId, isCollected }`，仅当传入 `noteId` 时返回 |

### 7.2 创建收藏夹

- **接口**：`POST /api/collections`
- **鉴权**：需登录（`@NeedLogin`）

| 字段 | 类型 | 必填 |
| --- | --- | --- |
| `name` | string | 是（非空） |
| `description` | string | 否 |

**响应**：`{ "code": 200, "message": "创建成功", "data": { "collectionId": 5 } }`

### 7.3 删除收藏夹

- **接口**：`DELETE /api/collections/{collectionId}`
- **鉴权**：需登录
- **参数**：`collectionId` (path, integer, ≥1)
- **响应**：`{ "code": 200, "message": "删除成功", "data": { "empty": true } }`

### 7.4 批量收藏 / 取消收藏

- **接口**：`POST /api/collections/batch`
- **鉴权**：需登录（`@NeedLogin`）
- **说明**：一次把某篇笔记加入/移出多个收藏夹。

**请求体**（`UpdateCollectionBody`）

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `noteId` | integer | 是 | 笔记 ID（≥1） |
| `collections` | array | 是 | 操作项数组 |
| `collections[].collectionId` | integer | 是 | 收藏夹 ID（≥1） |
| `collections[].action` | string | 是 | `create`（加入）/ `delete`（移出） |

```json
{
  "noteId": 3,
  "collections": [
    { "collectionId": 1, "action": "create" },
    { "collectionId": 2, "action": "delete" }
  ]
}
```

**响应**：`{ "code": 200, "message": "操作成功", "data": { "empty": true } }`

---

## 8. 评论

> ⚠️ 本模块失败时把 **HTTP 语义码写进 body 的 `code`**：`404` = 评论不存在，`403` = 无权操作。
> 成功响应多由 `ApiResponse.success(...)` 构造，`message` 固定为 `"success"`。

### 8.1 评论列表

- **接口**：`GET /api/comments`
- **鉴权**：公开
- **返回**：分页响应（`message` 为空字符串 `""`，`total` 为**一级评论数**）

**Query 参数**（`CommentQueryParams`）

| 字段 | 类型 | 必填 | 约束 |
| --- | --- | --- | --- |
| `noteId` | integer | 是 | 非空 |
| `page` | integer | 是 | ≥1 |
| `pageSize` | integer | 是 | ≥1 |

**响应 `data` 元素**（`CommentVO`）

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `commentId` | integer | 评论 ID |
| `noteId` | integer | 所属笔记 |
| `content` | string | 评论内容 |
| `likeCount` | integer | 点赞数 |
| `replyCount` | integer | 回复数 |
| `createdAt` / `updatedAt` | datetime | 时间 |
| `author` | object | `{ userId, username, avatarUrl }` |
| `userActions` | object | `{ isLiked }` |
| `replies` | array | 二级回复，结构同上（不含 `replies`） |

### 8.2 发表评论 / 回复

- **接口**：`POST /api/comments`
- **鉴权**：需登录（`@NeedLogin`）

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `noteId` | integer | 是 | 评论的笔记 ID |
| `parentId` | integer | 否 | 父评论 ID；填了即为回复 |
| `content` | string | 是 | 非空 |

**响应**：`{ "code": 200, "message": "success", "data": 12 }` —— `data` **直接是评论 ID（数字），不是对象**

### 8.3 修改评论

- **接口**：`PATCH /api/comments/{commentId}`
- **鉴权**：需登录（`@NeedLogin`），仅作者
- **请求体**：`{ "content": "新内容" }`（非空）
- **响应**：`{ "code": 200, "message": "success", "data": { "empty": true } }`
- **失败**：`code = 404` `评论不存在`；`code = 403` `无权修改该评论`

### 8.4 删除评论

- **接口**：`DELETE /api/comments/{commentId}`
- **鉴权**：需登录（`@NeedLogin`），仅作者
- **响应**：`{ "code": 200, "message": "success", "data": { "empty": true } }`

### 8.5 点赞评论 / 取消点赞

| 接口 | 方法 | 鉴权 | 响应 |
| --- | --- | --- | --- |
| `/api/comments/{commentId}/like` | POST | 需登录（`@NeedLogin`） | `{ "code": 200, "message": "success", "data": { "empty": true } }` |
| `/api/comments/{commentId}/like` | DELETE | 需登录（`@NeedLogin`） | 同上 |

---

## 9. 题目分类（Category）

> ⚠️ 与第 4 节的「笔记分类」是**两套独立数据**：
> `category` 表用于**题目**分类（数组/链表/字符串…），`note_category` 表用于**笔记**分类（Redis/SQL/MQ…）。

### 9.1 分类树（用户端）

- **接口**：`GET /api/categories`
- **鉴权**：公开
- **说明**：返回**两级树**结构，仅 `parentCategoryId = 0` 的分类作为根节点。

**响应 `data` 元素**（`CategoryVO`）

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `categoryId` | integer | 分类 ID |
| `name` | string | 名称 |
| `parentCategoryId` | integer | 父分类 ID，0 表示一级分类 |
| `children` | array | 子分类数组，元素为 `{ categoryId, name, parentCategoryId }` |

### 9.2 分类树（管理端）

- **接口**：`GET /api/admin/categories`
- **鉴权**：公开（未校验管理员）
- **响应**：同 9.1

### 9.3 创建分类

- **接口**：`POST /api/admin/categories`
- **鉴权**：公开（未校验管理员）

| 字段 | 类型 | 必填 | 约束 |
| --- | --- | --- | --- |
| `name` | string | 是 | 非空 |
| `parentCategoryId` | integer | 是 | ≥0；`0` 表示创建一级分类，否则父分类必须存在 |

**响应**：`{ "code": 200, "message": "创建分类成功", "data": { "categoryId": 9 } }`

### 9.4 重命名分类

- **接口**：`PATCH /api/admin/categories/{categoryId}`
- **鉴权**：公开（未校验管理员）
- **请求体**：`{ "name": "新名称" }`（非空）

### 9.5 删除分类

- **接口**：`DELETE /api/admin/categories/{categoryId}`
- **鉴权**：公开（未校验管理员）
- **说明**：会**级联删除**该分类及其子分类，并删除这些分类下的**所有题目**。分类不存在时返回 `分类 Id 非法`。

---

## 10. 题目

### 10.1 用户端题目列表

- **接口**：`GET /api/questions`
- **鉴权**：公开（登录时返回 `userQuestionStatus`）
- **返回**：分页响应

**Query 参数**（`QuestionQueryParam`）

| 字段 | 类型 | 必填 | 约束 |
| --- | --- | --- | --- |
| `categoryId` | integer | 否 | ≥1 |
| `sort` | string | 否 | `view` / `difficulty` |
| `order` | string | 否 | `asc` / `desc` |
| `page` | integer | 是 | ≥1 |
| `pageSize` | integer | 是 | 1~200 |

**响应 `data` 元素**（`QuestionUserVO`）：`questionId`、`title`、`difficulty`、`examPoint`、`description`、`viewCount`、`userQuestionStatus: { finished }`。

### 10.2 搜索题目

- **接口**：`POST /api/questions/search`
- **鉴权**：公开
- **请求体**：`{ "keyword": "两数之和" }`（1~32 字符）
- **响应**：`data` 为 `QuestionVO` 数组（**不分页**）

### 10.3 题目详情（含我的笔记）

- **接口**：`GET /api/questions/{questionId}`
- **鉴权**：公开（登录时 `userNote` 才有内容）
- **参数**：`questionId` (path, integer, ≥1)

**响应 `data`**（`QuestionNoteVO`）

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `questionId` | integer | 题目 ID |
| `title` | string | 标题 |
| `difficulty` | integer | 难度 1~3 |
| `examPoint` | string | 考点 |
| `description` | string | 题面（Markdown） |
| `viewCount` | integer | 浏览量 |
| `userNote` | object | `{ finished, noteId, content }`：当前用户在该题下的笔记 |

### 10.4 管理端题目列表

- **接口**：`GET /api/admin/questions`
- **鉴权**：公开（未校验管理员）
- **Query 参数**：同 10.1
- **响应**：分页响应，`data` 为 `QuestionVO` 数组（`questionId`、`categoryId`、`title`、`difficulty`、`examPoint`、`description`、`viewCount`、`createdAt`、`updatedAt`）

### 10.5 创建题目

- **接口**：`POST /api/admin/questions`
- **鉴权**：公开（未校验管理员）

| 字段 | 类型 | 必填 | 约束 |
| --- | --- | --- | --- |
| `categoryId` | integer | 是 | ≥1 |
| `title` | string | 是 | 非空 |
| `difficulty` | integer | 是 | 业务约定 1~3（简单/中等/困难），**后端未做强校验** |
| `examPoint` | string | 否 | — |
| `description` | string | 否 | — |

**响应**：`{ "code": 200, "data": { "questionId": 42 } }`

### 10.6 批量创建题目

- **接口**：`POST /api/admin/questions/batch`
- **鉴权**：公开（未校验管理员）
- **说明**：按 Markdown 文本解析批量导入题目（内含分类名，会自动 `findOrCreate` 分类）。

| 字段 | 类型 | 必填 |
| --- | --- | --- |
| `markdown` | string | 否 |

**响应**：`EmptyVO`

### 10.7 更新题目

- **接口**：`PATCH /api/admin/questions/{questionId}`
- **鉴权**：公开（未校验管理员）

| 字段 | 类型 | 必填 |
| --- | --- | --- |
| `title` | string | 是（非空） |
| `difficulty` | integer | 是 |
| `examPoint` | string | 否 |
| `description` | string | 否 |

### 10.8 删除题目

- **接口**：`DELETE /api/admin/questions/{questionId}`
- **鉴权**：公开（未校验管理员）

---

## 11. 题单

> 全部接口都在 `/api/admin/questionlists` 下（当前未校验管理员）。

| 接口 | 方法 | 说明 |
| --- | --- | --- |
| `/api/admin/questionlists` | GET | 题单列表，`data` 为 `QuestionList` 数组 |
| `/api/admin/questionlists/{questionListId}` | GET | 单个题单详情 |
| `/api/admin/questionlists` | POST | 创建题单 |
| `/api/admin/questionlists/{questionListId}` | PATCH | 更新题单 |
| `/api/admin/questionlists/{questionListId}` | DELETE | 删除题单 |

**`QuestionList` 实体字段**：`questionListId`、`name`、`type`（1 普通 / 2 训练营）、`description`、`createdAt`、`updatedAt`

**创建/更新请求体**（`CreateQuestionListBody` / `UpdateQuestionListBody`）：`name` (string)、`type` (integer)、`description` (string)，均无强制校验注解。

**创建响应**：`{ "code": 200, "data": { "questionListId": 3 } }`

---

## 12. 题单项

### 12.1 题单内题目列表（用户端）

- **接口**：`GET /api/questionlist-items`
- **鉴权**：公开（登录时返回完成状态）
- **返回**：分页响应

**Query 参数**（`QuestionListItemQueryParams`）

| 字段 | 类型 | 必填 | 约束 |
| --- | --- | --- | --- |
| `questionListId` | integer | 是 | ≥1 |
| `page` | integer | 是 | ≥1 |
| `pageSize` | integer | 是 | ≥1 |

**响应 `data` 元素**（`QuestionListItemUserVO`）

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `questionListId` | integer | 题单 ID |
| `question` | object | `BaseQuestionVO`：`questionId`、`categoryId`、`title`、`difficulty`、`examPoint`、`description`、`viewCount` |
| `userQuestionStatus` | object | `{ finished }` |
| `rank` | integer | 题单内排序 |

### 12.2 题单内题目列表（管理端）

- **接口**：`GET /api/admin/questionlist-items/{questionListId}`
- **鉴权**：公开（未校验管理员）
- **响应**：`data` 为 `QuestionListItemVO` 数组（`questionListId`、`question`、`rank`）

### 12.3 添加题目到题单

- **接口**：`POST /api/admin/questionlist-items`
- **鉴权**：公开（未校验管理员）

| 字段 | 类型 | 必填 | 约束 |
| --- | --- | --- | --- |
| `questionListId` | integer | 是 | ≥1 |
| `questionId` | integer | 是 | ≥1 |

**响应**：`{ "code": 200, "data": { "rank": 5 } }`

### 12.4 从题单移除题目

- **接口**：`DELETE /api/admin/questionlist-items/{questionListId}/{questionId}`
- **鉴权**：公开（未校验管理员）

### 12.5 调整题单内排序

- **接口**：`PATCH /api/admin/questionlist-items/sort`
- **鉴权**：公开（未校验管理员）

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `questionListId` | integer | 是 | ≥1 |
| `questionIds` | integer[] | 是 | 非空，按数组顺序重排 |

---

## 13. 消息

> 所有接口均依赖当前登录用户，**必须携带 token**。

### 13.1 我的消息列表

- **接口**：`GET /api/messages`
- **鉴权**：需登录（`@NeedLogin`）
- **响应 `data` 元素**（`MessageVO`）

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `messageId` | integer | 消息 ID |
| `sender` | object | `{ userId, username, avatarUrl }` |
| `type` | integer | 1 点赞 / 2 评论 / 3 系统 |
| `target` | object | `{ targetId, targetType, questionSummary }`；仅非系统消息返回 |
| `content` | string | 消息内容 |
| `isRead` | boolean | 是否已读 |
| `createdAt` | datetime | 时间 |

### 13.2 标记已读 / 删除

| 接口 | 方法 | 请求体 | 说明 |
| --- | --- | --- | --- |
| `/api/messages/{messageId}/read` | PATCH | — | 标记单条已读 |
| `/api/messages/all/read` | PATCH | — | 全部标记已读 |
| `/api/messages/batch/read` | PATCH | `{ "messageIds": [1,2,3] }` | 批量标记已读 |
| `/api/messages/{messageId}` | DELETE | — | 删除消息 |

**响应**：统一为 `EmptyVO`。

### 13.3 未读消息数

- **接口**：`GET /api/messages/unread/count`
- **鉴权**：需登录
- **响应**：`{ "code": 200, "message": "success", "data": 3 }`

---

## 14. 搜索

> 基于 MySQL 全文索引 + Jieba 分词（`search_vector` 列 + `FULLTEXT` 索引）。

### 14.1 全文检索笔记

- **接口**：`GET /api/search/notes`
- **鉴权**：公开

| 参数 | 位置 | 类型 | 必填 | 默认 |
| --- | --- | --- | --- | --- |
| `keyword` | query | string | 是 | — |
| `page` | query | integer | 否 | 1 |
| `pageSize` | query | integer | 否 | 20 |

**响应**：`data` 为 `Note` 实体数组（**不分页**）。

### 14.2 搜索用户

- **接口**：`GET /api/search/users`
- **鉴权**：公开
- **Query 参数**：`keyword`（必填）、`page`（默认 1）、`pageSize`（默认 20）
- **响应**：`data` 为 `User` 实体数组

### 14.3 按标签搜索笔记 ⚠️

- **接口**：`GET /api/search/notes/tag`
- **Query 参数**：`keyword`、`tag`（均必填）、`page`、`pageSize`
- **状态**：**当前不可用**。其 SQL 依赖 `note_tag` / `tag` 两张表和 `note.id` 列，而实际 schema 中并不存在（只有 `note.note_id`），调用会抛 SQL 异常。需要该功能时请先补建表结构或改写 SQL。

---

## 15. 统计

### 15.1 平台统计列表

- **接口**：`GET /api/statistic`
- **鉴权**：公开
- **返回**：分页响应

**Query 参数**（`StatisticQueryParam`）

| 字段 | 类型 | 必填 | 约束 |
| --- | --- | --- | --- |
| `page` | integer | 是 | ≥1 |
| `pageSize` | integer | 是 | ≥1 |

**响应 `data` 元素**（`Statistic`）

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | integer | 主键 |
| `date` | date | 统计日期 |
| `loginCount` | integer | 当日登录数 |
| `registerCount` | integer | 当日注册数 |
| `totalRegisterCount` | integer | 累计注册数 |
| `noteCount` | integer | 当日笔记数 |
| `submitNoteCount` | integer | 当日提交笔记人数 |
| `totalNoteCount` | integer | 累计笔记数 |

---

## 16. 文件上传

### 16.1 上传图片

- **接口**：`POST /api/upload/image`
- **鉴权**：公开
- **Content-Type**：`multipart/form-data`
- **参数**：`file`（file，必填；编辑器插图用）
- **响应**：`{ "code": 200, "message": "上传成功", "data": { "url": "/images/xxx.png" } }`
- **访问**：上传后的文件通过 `GET /images/{filename}` 访问

---

## 17. 邮件

### 17.1 发送邮箱验证码

- **接口**：`GET /api/email/verify-code`
- **鉴权**：公开

| 参数 | 位置 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- | --- |
| `email` | query | string | 是 | 邮箱格式 |

- **限流**：同一邮箱 60 秒内只能发一次
- **有效期**：15 分钟
- **响应**：`{ "code": 200, "message": "success", "data": null }`

> 依赖 `spring.mail.*` 配置。当前 `application.yaml` 中账号为占位值（`your@qq.com`），未配置真实邮箱时会失败。

---

## 18. 测试接口

| 接口 | 方法 | 说明 | 响应 |
| --- | --- | --- | --- |
| `/api/hello` | GET | 打印当前请求上下文后返回字符串 | 纯文本 `Hello World!`（**非统一响应结构**） |
| `/api/exception` | GET | 主动抛出 `RuntimeException("test exception")` | `{ "code": 500, "message": "Internal Server Error", "data": "test exception" }` |

---

## 19. 附录

### 19.1 数据表一览

| 表名 | 说明 |
| --- | --- |
| `user` | 用户 |
| `category` | **题目**分类（数组/链表…），支持父子两级 |
| `question` | 题目 |
| `question_list` | 题单 |
| `question_list_item` | 题单-题目关联（含排序 `rank`） |
| `note` | 笔记（`question_id` 与 `category_id` 二选一归属） |
| **`note_category`** | **笔记**分类（Redis/SQL/MQ…）——本次新增 |
| `note_like` | 笔记点赞 |
| `note_collect` | 笔记收藏 |
| `collection` | 收藏夹 |
| `collection_note` | 收藏夹-笔记关联 |
| `comment` | 评论（`parent_id` 支持二级回复） |
| `comment_like` | 评论点赞 |
| `message` | 消息 |
| `statistic` | 每日统计 |

建表脚本：`backend/src/main/resources/schema.sql`；初始化数据：`backend/src/main/resources/seed.sql`；
笔记分类增量迁移脚本：`db/note_category.sql`。

### 19.2 主要实体字段

**`Note`**：`noteId`、`authorId`、`questionId`、`categoryId`、`content`、`likeCount`、`commentCount`、`collectCount`、`createdAt`、`updatedAt`

**`User`**：`userId`、`account`、`username`、`password`、`gender`、`birthday`、`avatarUrl`、`email`、`school`、`signature`、`isBanned`、`isAdmin`、`lastLoginAt`、`createdAt`、`updatedAt`

**`Question`**：`questionId`、`categoryId`、`title`、`difficulty`、`examPoint`、`description`、`viewCount`、`createdAt`、`updatedAt`

**`NoteCategory`**：`categoryId`、`name`、`createdAt`、`updatedAt`

### 19.3 已知问题与建议

| 编号 | 问题 | 影响 |
| --- | --- | --- |
| 1 | `/api/admin/**` 全部接口**未做管理员校验** | 任何匿名用户都能增删改题目、分类、用户列表 |
| 2 | `/api/search/notes/tag` 依赖不存在的 `note_tag` / `tag` 表 | 调用即报错 |
| 3 | `/api/admin/users` 返回 `User` 实体，含 `password` 字段 | 敏感信息泄露 |
| 4 | `GET /api/users/avatar`、`/api/upload/image` 未校验登录 | 可被匿名刷存储 |
| 5 | 业务错误统一返回 HTTP 200 | 部分网关/监控无法按状态码区分 |
| 6 | `/api/notes/download` 不含分类笔记 | 分类笔记无法导出 |
