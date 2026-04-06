# SoloDev.Cool API — Postman Collection

> Base URL: `https://your-domain.com` | 本地开发: `http://localhost:3000`

---

## 环境变量 (Environment Variables)

在 Postman 中创建环境变量，方便全局使用：

| 变量名 | 初始值 | 说明 |
|--------|--------|------|
| `base_url` | `http://localhost:3000` | API 基础地址 |
| `token` | *(登录后自动填入)* | JWT Token |
| `user_email` | `user@example.com` | 测试邮箱 |
| `user_password` | `123456` | 测试密码 |

---

## 全局请求头 (Global Headers)

在 Collection 级别设置以下默认 Headers：

```
Content-Type: application/json
```

认证接口额外添加：

```
Authorization: Bearer {{token}}
```

---

## Postman Tests 脚本（自动保存 Token）

在 **登录接口** 的 `Tests` 标签中添加以下脚本，登录成功后自动保存 Token：

```javascript
const res = pm.response.json();
if (res.code === 0 && res.data && res.data.token) {
    pm.environment.set('token', res.data.token);
    console.log('Token saved:', res.data.token);
}
```

---

## 统一响应格式

**成功：**

```json
{
    "code": 0,
    "message": "success",
    "data": {}
}
```

**失败：**

```json
{
    "code": 422,
    "message": "验证失败",
    "errors": {
        "email": ["已被占用"]
    }
}
```

**分页响应头：** `X-Page` / `X-Per-Page` / `X-Total` / `X-Total-Pages`

---

## 业务错误码

| code | 含义 |
|------|------|
| 0 | 成功 |
| 10001 | 邮箱或密码错误 |
| 10002 | 验证码错误或已过期 |
| 10003 | 邀请码无效 |
| 10004 | 邀请码已使用或已过期 |
| 10005 | 邮箱已注册 |
| 10006 | 今日已签到 |
| 10009 | 不能给自己投票 |
| 10010 | 投票已关闭 |
| 10012 | 验证码发送过于频繁 |

---

---

# 1. Auth — 认证模块

---

## 1.1 发送邮箱验证码

`POST` `{{base_url}}/api/v1/auth/send_verification_code`

> 无需认证

**Headers:**

```
Content-Type: application/json
```

**Body (raw JSON):**

```json
{
    "email": "user@example.com",
    "purpose": "register"
}
```

> `purpose` 可选值: `register` | `reset_password`

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "验证码已发送"
}
```

**错误示例 `422`:**

```json
{
    "code": 10005,
    "message": "该邮箱已被注册"
}
```

---

## 1.2 邮箱注册

`POST` `{{base_url}}/api/v1/auth/register`

> 无需认证

**Body (raw JSON):**

```json
{
    "email": "newuser@example.com",
    "username": "cooldev",
    "password": "123456",
    "verification_code": "123456",
    "invitation_code": "ABCD1234"
}
```

> `verification_code` — 开启邮箱验证时必填
> `invitation_code` — 后台开启邀请码时必填

**响应 `201 Created`:**

```json
{
    "code": 0,
    "message": "注册成功",
    "data": {
        "token": "eyJhbGciOiJIUzI1NiJ9...",
        "user": {
            "id": 1,
            "email": "newuser@example.com",
            "username": "cooldev",
            "points": 0,
            "role": "user",
            "avatar_url": null
        }
    }
}
```

**Tests 脚本（注册后也保存 Token）：**

```javascript
const res = pm.response.json();
if (res.code === 0 && res.data && res.data.token) {
    pm.environment.set('token', res.data.token);
}
```

---

## 1.3 邮箱登录

`POST` `{{base_url}}/api/v1/auth/login`

> 无需认证

**Body (raw JSON):**

```json
{
    "email": "{{user_email}}",
    "password": "{{user_password}}"
}
```

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "登录成功",
    "data": {
        "token": "eyJhbGciOiJIUzI1NiJ9...",
        "user": {
            "id": 1,
            "email": "user@example.com",
            "username": "cooldev",
            "points": 230,
            "role": "user",
            "avatar_url": null
        }
    }
}
```

**错误示例 `422`:**

```json
{
    "code": 10001,
    "message": "邮箱或密码错误"
}
```

**Tests 脚本：**

```javascript
const res = pm.response.json();
if (res.code === 0 && res.data && res.data.token) {
    pm.environment.set('token', res.data.token);
    console.log('Token saved:', res.data.token);
}
```

---

## 1.4 登出

`POST` `{{base_url}}/api/v1/auth/logout`

> 需要 `Authorization: Bearer {{token}}`

**Headers:**

```
Content-Type: application/json
Authorization: Bearer {{token}}
```

**Body:** 无

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "已登出"
}
```

---

## 1.5 刷新 Token

`POST` `{{base_url}}/api/v1/auth/refresh`

> 需要 `Authorization: Bearer {{token}}`（使用旧 Token）

**Headers:**

```
Content-Type: application/json
Authorization: Bearer {{token}}
```

**Body:** 无

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "success",
    "data": {
        "token": "eyJhbGciOiJIUzI1NiJ9..."
    }
}
```

**Tests 脚本（自动更新 Token）：**

```javascript
const res = pm.response.json();
if (res.code === 0 && res.data && res.data.token) {
    pm.environment.set('token', res.data.token);
}
```

---

## 1.6 重置密码

`POST` `{{base_url}}/api/v1/auth/reset_password`

> 无需认证（通过验证码验证身份）

**Body (raw JSON):**

```json
{
    "email": "user@example.com",
    "verification_code": "123456",
    "new_password": "newpassword123"
}
```

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "密码已重置"
}
```

---

---

# 2. Topics — 话题模块

---

## 2.1 话题列表

`GET` `{{base_url}}/api/v1/topics`

> 无需认证（登录后返回 `is_cooled` 等个人状态）

**Query Params:**

| Key | Value | 说明 |
|-----|-------|------|
| `scope` | `recent` | `recent` \| `hot` \| `followed` \| `trending` |
| `node_id` | `1` | 按节点筛选（可选） |
| `kind` | `system` | `system` \| `interest`（可选） |
| `page` | `1` | 页码 |
| `per_page` | `20` | 每页条数（最大 50） |

**响应 `200 OK`:**

```json
{
    "code": 0,
    "data": [
        {
            "id": 1,
            "title": "Rails 8 新特性探讨",
            "slug": "rails-8-new-features",
            "excerpt": "最近 Rails 8 发布了，带来了许多新特性...",
            "node": {
                "id": 1,
                "name": "技术讨论",
                "slug": "tech"
            },
            "author": {
                "id": 1,
                "username": "cooldev",
                "avatar_url": null
            },
            "comments_count": 15,
            "cools_count": 32,
            "views_count": 520,
            "pinned": false,
            "is_cooled": false,
            "has_poll": false,
            "created_at": "2026-04-05T10:30:00.000+08:00"
        }
    ]
}
```

**Response Headers:**

```
X-Page: 1
X-Per-Page: 20
X-Total: 150
X-Total-Pages: 8
```

---

## 2.2 搜索话题

`GET` `{{base_url}}/api/v1/topics/search`

> 无需认证

**Query Params:**

| Key | Value | 说明 |
|-----|-------|------|
| `q` | `Rails` | 搜索关键词（必填） |
| `page` | `1` | 页码 |
| `per_page` | `20` | 每页条数 |

**响应:** 同 2.1 话题列表格式

---

## 2.3 话题详情

`GET` `{{base_url}}/api/v1/topics/1`

> 无需认证（登录后返回 `is_cooled` / `is_author` 等状态）

**响应 `200 OK`:**

```json
{
    "code": 0,
    "data": {
        "id": 1,
        "title": "Rails 8 新特性探讨",
        "slug": "rails-8-new-features",
        "content": "<p>最近 Rails 8 发布了，带来了许多新特性...</p>",
        "node": {
            "id": 1,
            "name": "技术讨论",
            "slug": "tech"
        },
        "author": {
            "id": 1,
            "username": "cooldev",
            "avatar_url": null
        },
        "comments_count": 15,
        "cools_count": 32,
        "views_count": 521,
        "pinned": false,
        "is_repost": false,
        "source_url": null,
        "is_cooled": false,
        "is_author": false,
        "has_poll": true,
        "poll": {
            "id": 1,
            "closed": false,
            "options": [
                { "id": 1, "title": "非常喜欢", "votes_count": 20, "percentage": 62.5, "voted": false },
                { "id": 2, "title": "一般般", "votes_count": 8, "percentage": 25.0, "voted": true },
                { "id": 3, "title": "不喜欢", "votes_count": 4, "percentage": 12.5, "voted": false }
            ]
        },
        "comments": [
            {
                "id": 1,
                "content": "<p>非常赞同！</p>",
                "author": {
                    "id": 2,
                    "username": "another_user",
                    "avatar_url": null
                },
                "cools_count": 5,
                "is_cooled": false,
                "is_author": false,
                "login_only": false,
                "tips_total": 50,
                "created_at": "2026-04-05T11:00:00.000+08:00",
                "replies": [
                    {
                        "id": 2,
                        "content": "<p>同意</p>",
                        "author": {
                            "id": 3,
                            "username": "third_user",
                            "avatar_url": null
                        },
                        "cools_count": 1,
                        "is_cooled": false,
                        "is_author": false,
                        "login_only": false,
                        "tips_total": 0,
                        "created_at": "2026-04-05T12:00:00.000+08:00",
                        "replies": []
                    }
                ]
            }
        ],
        "created_at": "2026-04-05T10:30:00.000+08:00",
        "updated_at": "2026-04-05T10:30:00.000+08:00"
    }
}
```

> 评论以树形嵌套结构返回，`replies` 为子回复数组

---

## 2.4 创建话题

`POST` `{{base_url}}/api/v1/topics`

> 需要 `Authorization: Bearer {{token}}`

**Body (raw JSON):**

```json
{
    "title": "我的第一个话题",
    "content": "<p>这是话题内容，至少 10 个字符。</p>",
    "node_id": 1
}
```

> 转发话题时额外添加:
> ```json
> {
>     "is_repost": true,
>     "source_url": "https://example.com/article"
> }
> ```

**响应 `201 Created`:**

```json
{
    "code": 0,
    "message": "话题创建成功",
    "data": {
        "id": 10,
        "slug": "my-first-topic",
        "title": "我的第一个话题"
    }
}
```

---

## 2.5 更新话题

`PUT` `{{base_url}}/api/v1/topics/1`

> 需要 `Authorization: Bearer {{token}}`（仅作者可操作）

**Body (raw JSON):**

```json
{
    "title": "更新后的标题",
    "content": "<p>更新后的内容</p>",
    "node_id": 2
}
```

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "更新成功",
    "data": {
        "id": 1,
        "title": "更新后的标题"
    }
}
```

---

## 2.6 删除话题

`DELETE` `{{base_url}}/api/v1/topics/1`

> 需要 `Authorization: Bearer {{token}}`（仅作者/管理员可操作）

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "删除成功"
}
```

---

---

# 3. Comments — 评论模块

---

## 3.1 评论列表（树形）

`GET` `{{base_url}}/api/v1/topics/1/comments`

> 无需认证（登录后返回 `is_cooled` / `is_author` 等状态）

**Query Params:**

| Key | Value | 说明 |
|-----|-------|------|
| `page` | `1` | 页码（按根评论分页） |
| `per_page` | `20` | 每页根评论数 |

**响应 `200 OK`:**

```json
{
    "code": 0,
    "data": [
        {
            "id": 1,
            "content": "<p>非常赞同！</p>",
            "author": { "id": 2, "username": "another_user", "avatar_url": null },
            "cools_count": 5,
            "is_cooled": false,
            "is_author": false,
            "login_only": false,
            "tips_total": 50,
            "created_at": "2026-04-05T11:00:00.000+08:00",
            "replies": []
        }
    ]
}
```

---

## 3.2 创建评论

`POST` `{{base_url}}/api/v1/topics/1/comments`

> 需要 `Authorization: Bearer {{token}}`

**Body (raw JSON) — 根评论：**

```json
{
    "comment": {
        "content": "<p>这是我的评论</p>"
    }
}
```

**Body (raw JSON) — 回复评论：**

```json
{
    "comment": {
        "content": "<p>回复楼上</p>",
        "parent_id": 1
    }
}
```

> `parent_id` 为空则是根评论，有值则为嵌套回复

**响应 `201 Created`:**

```json
{
    "code": 0,
    "message": "评论成功",
    "data": {
        "id": 10,
        "content": "<p>这是我的评论</p>",
        "author": { "id": 1, "username": "cooldev", "avatar_url": null },
        "cools_count": 0,
        "is_cooled": false,
        "is_author": true,
        "login_only": false,
        "tips_total": 0,
        "created_at": "2026-04-06T15:00:00.000+08:00",
        "replies": []
    }
}
```

---

## 3.3 删除评论

`DELETE` `{{base_url}}/api/v1/topics/1/comments/5`

> 需要 `Authorization: Bearer {{token}}`（仅作者/管理员可操作）

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "已删除"
}
```

---

## 3.4 切换评论"仅登录可见"

`POST` `{{base_url}}/api/v1/topics/1/comments/5/toggle_login_only`

> 需要 `Authorization: Bearer {{token}}`（仅评论作者可操作）

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "success",
    "data": {
        "id": 5,
        "login_only": true
    }
}
```

---

---

# 4. Interactions — 互动模块

---

## 4.1 话题点赞

`POST` `{{base_url}}/api/v1/topics/1/cool`

> 需要 `Authorization: Bearer {{token}}`

> 点赞者 -10 酷能量，话题作者 +10 酷能量

**Body:** 无

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "已点赞",
    "data": {
        "cools_count": 33
    }
}
```

---

## 4.2 取消话题点赞

`DELETE` `{{base_url}}/api/v1/topics/1/cool`

> 需要 `Authorization: Bearer {{token}}`

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "已取消点赞",
    "data": {
        "cools_count": 32
    }
}
```

---

## 4.3 评论点赞

`POST` `{{base_url}}/api/v1/comments/5/cool`

> 需要 `Authorization: Bearer {{token}}`

> 点赞者 -10 酷能量，评论作者 +10 酷能量。不能给自己点赞。

**Body:** 无

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "已点赞",
    "data": {
        "cools_count": 6,
        "points": 220
    }
}
```

---

## 4.4 取消评论点赞

`DELETE` `{{base_url}}/api/v1/comments/5/cool`

> 需要 `Authorization: Bearer {{token}}`

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "已取消点赞",
    "data": {
        "cools_count": 5,
        "points": 230
    }
}
```

---

## 4.5 打赏评论

`POST` `{{base_url}}/api/v1/topics/1/tips`

> 需要 `Authorization: Bearer {{token}}`

> 只有话题作者可以打赏评论。打赏者 -金额 酷能量，评论作者 +金额 酷能量。

**Body (raw JSON):**

```json
{
    "comment_id": 5,
    "amount": 20
}
```

> `amount` 可选值: `10` | `20` | `30` | `50` | `100`

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "打赏成功",
    "data": {
        "tip": {
            "id": 1,
            "amount": 20,
            "from_user": { "id": 1, "username": "cooldev" },
            "to_user": { "id": 2, "username": "another_user" }
        },
        "my_points": 210
    }
}
```

**错误示例 `422`:**

```json
{
    "code": 422,
    "message": "酷能量不足"
}
```

---

---

# 5. Polls — 投票模块

---

## 5.1 创建投票

`POST` `{{base_url}}/api/v1/topics/1/poll`

> 需要 `Authorization: Bearer {{token}}`（仅话题作者可操作）

**Body (raw JSON):**

```json
{
    "poll": {
        "options": ["选项A", "选项B", "选项C"],
        "closed": false
    }
}
```

> `options` 至少 2 个，`closed` 默认 `false`

**响应 `201 Created`:**

```json
{
    "code": 0,
    "message": "投票创建成功",
    "data": {
        "id": 1,
        "closed": false,
        "options": [
            { "id": 1, "title": "选项A", "votes_count": 0, "percentage": 0.0, "voted": false },
            { "id": 2, "title": "选项B", "votes_count": 0, "percentage": 0.0, "voted": false },
            { "id": 3, "title": "选项C", "votes_count": 0, "percentage": 0.0, "voted": false }
        ]
    }
}
```

---

## 5.2 删除投票

`DELETE` `{{base_url}}/api/v1/topics/1/poll`

> 需要 `Authorization: Bearer {{token}}`（仅话题作者可操作）

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "投票已删除"
}
```

---

## 5.3 投票

`POST` `{{base_url}}/api/v1/polls/1/vote`

> 需要 `Authorization: Bearer {{token}}`

> 不能给自己的投票投票。投票已关闭时不可投票。

**Body (raw JSON):**

```json
{
    "poll_option_id": 2
}
```

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "投票成功",
    "data": {
        "poll": {
            "id": 1,
            "closed": false,
            "options": [
                { "id": 1, "title": "选项A", "votes_count": 21, "percentage": 62.5, "voted": false },
                { "id": 2, "title": "选项B", "votes_count": 9, "percentage": 26.8, "voted": true },
                { "id": 3, "title": "选项C", "votes_count": 4, "percentage": 12.5, "voted": false }
            ]
        }
    }
}
```

---

## 5.4 关闭投票

`POST` `{{base_url}}/api/v1/polls/1/close`

> 需要 `Authorization: Bearer {{token}}`（仅话题作者可操作）

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "投票已关闭"
}
```

---

## 5.5 开启投票

`POST` `{{base_url}}/api/v1/polls/1/open`

> 需要 `Authorization: Bearer {{token}}`（仅话题作者可操作）

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "投票已开启"
}
```

---

---

# 6. Users — 用户模块

---

## 6.1 用户公开主页

`GET` `{{base_url}}/api/v1/users/1`

> 无需认证（登录后返回 `is_followed` / `is_blocked` 等状态）

**响应 `200 OK`:**

```json
{
    "code": 0,
    "data": {
        "id": 1,
        "username": "cooldev",
        "avatar_url": null,
        "points": 230,
        "topics_count": 12,
        "comments_count": 45,
        "followers_count": 30,
        "following_count": 15,
        "is_followed": false,
        "is_blocked": false,
        "created_at": "2025-01-15T08:00:00.000+08:00"
    }
}
```

---

## 6.2 搜索用户

`GET` `{{base_url}}/api/v1/users/search`

> 需要 `Authorization: Bearer {{token}}`

**Query Params:**

| Key | Value | 说明 |
|-----|-------|------|
| `q` | `cool` | 搜索用户名（必填） |

**响应 `200 OK`:**

```json
{
    "code": 0,
    "data": [
        { "id": 1, "username": "cooldev", "avatar_url": null },
        { "id": 5, "username": "cooldev2", "avatar_url": null }
    ]
}
```

---

## 6.3 关注用户

`POST` `{{base_url}}/api/v1/users/2/follow`

> 需要 `Authorization: Bearer {{token}}`

**Body:** 无

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "已关注",
    "data": {
        "followers_count": 31
    }
}
```

---

## 6.4 取消关注用户

`DELETE` `{{base_url}}/api/v1/users/2/follow`

> 需要 `Authorization: Bearer {{token}}`

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "已取消关注",
    "data": {
        "followers_count": 30
    }
}
```

---

## 6.5 屏蔽用户

`POST` `{{base_url}}/api/v1/users/2/block`

> 需要 `Authorization: Bearer {{token}}`

**Body:** 无

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "已屏蔽"
}
```

---

## 6.6 取消屏蔽用户

`DELETE` `{{base_url}}/api/v1/users/2/block`

> 需要 `Authorization: Bearer {{token}}`

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "已取消屏蔽"
}
```

---

---

# 7. Nodes — 节点模块

---

## 7.1 节点列表

`GET` `{{base_url}}/api/v1/nodes`

> 无需认证（登录后返回 `is_followed` 状态）

**Query Params:**

| Key | Value | 说明 |
|-----|-------|------|
| `kind` | `system` | `system` \| `interest`（可选） |

**响应 `200 OK`:**

```json
{
    "code": 0,
    "data": [
        {
            "id": 1,
            "name": "技术讨论",
            "slug": "tech",
            "kind": "system",
            "topics_count": 150,
            "is_followed": false,
            "position": 1
        },
        {
            "id": 2,
            "name": "前端开发",
            "slug": "frontend",
            "kind": "interest",
            "topics_count": 85,
            "is_followed": true,
            "position": 2
        }
    ]
}
```

---

## 7.2 关注节点

`POST` `{{base_url}}/api/v1/nodes/2/follow`

> 需要 `Authorization: Bearer {{token}}`

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "已关注"
}
```

---

## 7.3 取消关注节点

`DELETE` `{{base_url}}/api/v1/nodes/2/follow`

> 需要 `Authorization: Bearer {{token}}`

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "已取消关注"
}
```

---

---

# 8. Profile — 个人中心

---

## 8.1 获取当前用户信息

`GET` `{{base_url}}/api/v1/profile`

> 需要 `Authorization: Bearer {{token}}`

**响应 `200 OK`:**

```json
{
    "code": 0,
    "data": {
        "user": {
            "id": 1,
            "email": "user@example.com",
            "username": "cooldev",
            "avatar_url": null,
            "points": 230,
            "role": "user",
            "profile_public": true,
            "created_at": "2025-01-15T08:00:00.000+08:00"
        },
        "stats": {
            "topics_count": 12,
            "comments_count": 45,
            "followers_count": 30,
            "following_count": 15,
            "blocks_count": 2
        }
    }
}
```

---

## 8.2 更新个人信息

`PATCH` `{{base_url}}/api/v1/profile`

> 需要 `Authorization: Bearer {{token}}`

**修改用户名 — Body (raw JSON):**

```json
{
    "username": "new_name"
}
```

**修改头像 — Body (form-data):**

| Key | Type | Value | 说明 |
|-----|------|-------|------|
| `avatar` | File | *(选择文件)* | 头像图片 |

> `Content-Type` 设为 `multipart/form-data`

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "用户名修改成功",
    "data": {
        "id": 1,
        "email": "user@example.com",
        "username": "new_name",
        "avatar_url": null,
        "points": 230,
        "role": "user",
        "profile_public": true,
        "created_at": "2025-01-15T08:00:00.000+08:00"
    }
}
```

---

## 8.3 修改密码

`PATCH` `{{base_url}}/api/v1/profile/password`

> 需要 `Authorization: Bearer {{token}}`

**Body (raw JSON):**

```json
{
    "current_password": "123456",
    "new_password": "newpass123",
    "new_password_confirmation": "newpass123"
}
```

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "密码已修改"
}
```

**错误示例 `422`:**

```json
{
    "code": 422,
    "message": "当前密码错误"
}
```

---

---

# 9. CheckIn — 签到

---

## 9.1 每日签到

`POST` `{{base_url}}/api/v1/check_in`

> 需要 `Authorization: Bearer {{token}}`

> 每日限一次，+10 酷能量

**Body:** 无

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "签到成功，获得 10 酷能量",
    "data": {
        "points_earned": 10,
        "total_points": 240,
        "today_checked_in": true
    }
}
```

**已签到时 `422`:**

```json
{
    "code": 10006,
    "message": "今日已签到"
}
```

---

---

# 10. Notifications — 通知

---

## 10.1 通知列表

`GET` `{{base_url}}/api/v1/notifications`

> 需要 `Authorization: Bearer {{token}}`

**Query Params:**

| Key | Value | 说明 |
|-----|-------|------|
| `scope` | `unread` | `all` \| `unread`（可选，默认全部） |
| `page` | `1` | 页码 |
| `per_page` | `20` | 每页条数 |

**响应 `200 OK`:**

```json
{
    "code": 0,
    "data": [
        {
            "id": 1,
            "notify_type": "new_comment",
            "read": false,
            "actor": {
                "id": 2,
                "username": "another_user",
                "avatar_url": null
            },
            "notifiable": {
                "type": "Comment",
                "id": 5,
                "content": "非常赞同！",
                "topic": {
                    "id": 1,
                    "title": "Rails 8 新特性探讨",
                    "slug": "rails-8-new-features"
                }
            },
            "created_at": "2026-04-05T11:00:00.000+08:00"
        }
    ]
}
```

**通知类型 `notify_type` 枚举：**

| 类型 | 说明 |
|------|------|
| `topic_cool` | 话题被点赞 |
| `comment_cool` | 评论被点赞 |
| `tip` | 被打赏 |
| `new_comment` | 话题被评论 |
| `new_reply` | 评论被回复 |
| `new_follower` | 被关注 |
| `mention` | 被 @提及 |
| `topic_vote` | 投票被参与 |

---

## 10.2 未读通知数

`GET` `{{base_url}}/api/v1/notifications/unread_count`

> 需要 `Authorization: Bearer {{token}}`

**响应 `200 OK`:**

```json
{
    "code": 0,
    "data": {
        "unread_count": 5
    }
}
```

---

## 10.3 标记单条通知已读

`PUT` `{{base_url}}/api/v1/notifications/1/read`

> 需要 `Authorization: Bearer {{token}}`

**Body:** 无

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "已标记为已读"
}
```

---

## 10.4 全部标记为已读

`PUT` `{{base_url}}/api/v1/notifications/read_all`

> 需要 `Authorization: Bearer {{token}}`

**Body:** 无

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "已全部标记为已读"
}
```

---

---

# 11. Images — 图片上传

---

## 11.1 上传图片

`POST` `{{base_url}}/api/v1/images`

> 需要 `Authorization: Bearer {{token}}`

**Headers:**

```
Content-Type: multipart/form-data
Authorization: Bearer {{token}}
```

**Body (form-data):**

| Key | Type | Value | 说明 |
|-----|------|-------|------|
| `file` | File | *(选择文件)* | 图片（JPG/PNG/GIF/WebP，最大 5MB） |

**响应 `200 OK`:**

```json
{
    "code": 0,
    "message": "上传成功",
    "data": {
        "id": 1,
        "url": "/rails/active_storage/blobs/redirect/..."
    }
}
```

**错误示例 `422`:**

```json
{
    "code": 422,
    "message": "上传失败：File is too large (maximum is 5MB)"
}
```

---

---

# 12. Misc — 杂项

---

## 12.1 交流群列表

`GET` `{{base_url}}/api/v1/chat_groups`

> 无需认证

**响应 `200 OK`:**

```json
{
    "code": 0,
    "data": {
        "enabled": true,
        "groups": {
            "微信群": [
                {
                    "id": 1,
                    "name": "Rails 中文交流群",
                    "description": "一起讨论 Ruby on Rails",
                    "members_count": 150
                }
            ],
            "QQ群": [
                {
                    "id": 2,
                    "name": "SoloDev QQ 群",
                    "description": "独立开发者交流",
                    "members_count": 200
                }
            ],
            "Telegram": [],
            "Discord": []
        }
    }
}
```

> 功能未开启时 `enabled` 为 `false`

---

## 12.2 站点公开信息

`GET` `{{base_url}}/api/v1/site_info`

> 无需认证

**响应 `200 OK`:**

```json
{
    "code": 0,
    "data": {
        "site_name": "SoloDev.Cool",
        "site_title": "SoloDev.Cool",
        "site_description": "面向独立开发者的中文技术社区",
        "logo_url": null,
        "favicon_url": null,
        "stats": {
            "users_count": 1200,
            "topics_count": 3500,
            "comments_count": 18000
        },
        "features": {
            "registration_enabled": true,
            "invitation_code_required": true,
            "friend_links_enabled": true,
            "chat_groups_enabled": true
        }
    }
}
```

> App 启动时可调用此接口获取站点名称、统计、功能开关等

---

## 12.3 友情链接

`GET` `{{base_url}}/api/v1/friend_links`

> 无需认证

**响应 `200 OK`:**

```json
{
    "code": 0,
    "data": [
        {
            "id": 1,
            "name": "Ruby China",
            "url": "https://ruby-china.org",
            "description": "Ruby 中文社区",
            "logo": null,
            "sort_order": 1
        },
        {
            "id": 2,
            "name": "V2EX",
            "url": "https://v2ex.com",
            "description": "创意工作者的社区",
            "logo": null,
            "sort_order": 2
        }
    ]
}
```

> 功能未开启时返回空数组 `"data": []`

---

---

# Postman 快速导入指南

## 方式一：手动创建 Collection

1. 打开 Postman → 新建 Collection → 命名为 `SoloDev.Cool API`
2. 设置 Collection 级 Variables: `base_url` = `http://localhost:3000`
3. 按上方 12 个模块创建 Folder，逐个添加 Request
4. 在需要认证的 Request 上添加 Header: `Authorization: Bearer {{token}}`
5. 在登录 Request 的 `Tests` 标签粘贴自动保存 Token 脚本

## 方式二：通过 OpenAPI 导入

1. 打开 Postman → Import → 选择 `docs/api_openapi.yaml`
2. Postman 会自动生成完整 Collection
3. 补充环境变量和 Tests 脚本

## 推荐测试顺序

```
1. 发送验证码 → 2. 注册 → 3. 登录（自动保存 Token）
→ 4. 话题列表 → 5. 话题详情
→ 6. 创建评论 → 7. 话题点赞 → 8. 评论点赞
→ 9. 签到 → 10. 通知列表 → 11. 个人中心
→ 12. 上传图片 → 13. 站点信息
```

---

## 积分规则速查

| 行为 | 积分变化 |
|------|---------|
| 每日签到 | +10 |
| 话题被点赞 | 作者 +10 / 点赞者 -10 |
| 评论被点赞 | 评论作者 +10 / 点赞者 -10 |
| 被打赏 | 评论作者 +金额 / 打赏者 -金额 |
