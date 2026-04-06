# SoloDev.Cool App API 设计文档

> 版本: v1 | 更新日期: 2026-04-06

---

## 一、概述

本文档为 SoloDev.Cool 社区论坛的 App 端 RESTful API 接口设计。所有接口统一挂载在 `/api/v1/` 路径下，默认返回 JSON 格式数据。

### 技术选型

| 组件 | 方案 | 说明 |
|------|------|------|
| 认证 | `devise-jwt` | 基于 JWT 的 Token 认证，适合移动端无状态场景 |
| 序列化 | `jbuilder` | 轻量级 JSON 模板引擎 |
| 分页 | `pagy`（项目已有） | 通过响应头返回分页元数据 |
| 版本控制 | URL 路径 `/api/v1/` | 直观、兼容性好 |

---

## 二、通用规范

### 2.1 基础 URL

```
https://your-domain.com/api/v1
```

### 2.2 请求头

| Header | 必填 | 说明 |
|--------|------|------|
| `Content-Type` | 是 | `application/json`（上传接口为 `multipart/form-data`） |
| `Authorization` | 需认证接口必填 | `Bearer <jwt_token>` |
| `Accept-Language` | 否 | `zh-CN`（默认），`en` |

### 2.3 统一响应格式

**成功响应：**

```json
{
  "code": 0,
  "message": "success",
  "data": { ... }
}
```

**失败响应：**

```json
{
  "code": 422,
  "message": "验证失败",
  "errors": {
    "email": ["已被占用"]
  }
}
```

### 2.4 HTTP 状态码约定

| 状态码 | 含义 |
|--------|------|
| `200` | 请求成功 |
| `201` | 创建成功 |
| `204` | 删除成功（无返回体） |
| `400` | 请求参数错误 |
| `401` | 未认证（Token 无效或过期） |
| `403` | 无权限（非作者/非管理员） |
| `404` | 资源不存在 |
| `422` | 业务验证失败 |
| `429` | 请求频率超限 |
| `500` | 服务器内部错误 |

### 2.5 分页规范

分页接口通过**响应头**传递分页元数据：

```
X-Page: 1
X-Per-Page: 20
X-Total: 150
X-Total-Pages: 8
```

请求参数：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `page` | integer | 1 | 当前页码 |
| `per_page` | integer | 20 | 每页条数（最大 50） |

### 2.6 业务错误码

| code | 含义 |
|------|------|
| 0 | 成功 |
| 10001 | 邮箱或密码错误 |
| 10002 | 邮箱验证码错误或已过期 |
| 10003 | 邀请码无效 |
| 10004 | 邀请码已使用或已过期 |
| 10005 | 该邮箱已注册 |
| 10006 | 今日已签到 |
| 10007 | 不能给自己点赞 |
| 10008 | 不能给自己打赏 |
| 10009 | 不能给自己投票 |
| 10010 | 投票已关闭 |
| 10011 | 您已被该用户屏蔽 |
| 10012 | 验证码发送过于频繁 |

---

## 三、目录结构

```
app/
├── controllers/
│   └── api/
│       └── v1/
│           ├── base_controller.rb          # 基础控制器（认证/错误处理/分页）
│           ├── auth_controller.rb          # 认证：注册/登录/登出/刷新/重置密码
│           ├── topics_controller.rb        # 话题：列表/详情/创建/更新/删除/搜索
│           ├── comments_controller.rb      # 评论：列表/创建/删除/切换可见性
│           ├── interactions_controller.rb  # 互动：话题点赞/评论点赞/打赏
│           ├── polls_controller.rb         # 投票：创建/删除/投票/关闭/开启
│           ├── users_controller.rb         # 用户：主页/搜索/关注/屏蔽
│           ├── nodes_controller.rb         # 节点：列表/关注
│           ├── profile_controller.rb       # 个人中心：信息/更新/修改密码
│           ├── check_ins_controller.rb     # 签到
│           ├── notifications_controller.rb # 通知：列表/未读数/标记已读
│           ├── images_controller.rb        # 图片上传
│           └── misc_controller.rb          # 杂项：交流群/站点信息/友情链接
├── views/
│   └── api/
│       └── v1/
│           ├── auth/
│           │   ├── login.json.jbuilder
│           │   └── register.json.jbuilder
│           ├── topics/
│           │   ├── index.json.jbuilder
│           │   └── show.json.jbuilder
│           ├── comments/
│           │   └── index.json.jbuilder
│           └── ...（其他 jbuilder 模板）
├── controllers/concerns/
│   └── api/
│       └── authenticatable.rb              # JWT 认证 concern
└── models/
    └── concerns/
        └── api/
            └── serializable.rb              # 序列化辅助方法（可选）
```

---

## 四、接口详情

### 4.1 认证模块 — Auth

认证模块处理用户注册、登录、Token 刷新和密码重置。

---

#### POST `/api/v1/auth/send_verification_code`

发送邮箱验证码。

**请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `email` | string | 是 | 邮箱地址 |
| `purpose` | string | 是 | 用途：`register` / `reset_password` |

**响应示例：**

```json
{
  "code": 0,
  "message": "验证码已发送"
}
```

---

#### POST `/api/v1/auth/register`

邮箱注册。

**请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `email` | string | 是 | 邮箱地址 |
| `username` | string | 是 | 用户名（2-20 字符） |
| `password` | string | 是 | 密码（至少 6 位） |
| `verification_code` | string | 是 | 6 位邮箱验证码 |
| `invitation_code` | string | 视情况 | 邀请码（后台开启邀请码时必填） |

**响应示例：**

```json
{
  "code": 0,
  "message": "注册成功",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "user": {
      "id": 1,
      "email": "user@example.com",
      "username": "cooldev",
      "points": 0,
      "role": "user"
    }
  }
}
```

---

#### POST `/api/v1/auth/login`

邮箱登录。

**请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `email` | string | 是 | 邮箱地址 |
| `password` | string | 是 | 密码 |

**响应示例：**

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
      "role": "user"
    }
  }
}
```

---

#### POST `/api/v1/auth/refresh`

刷新 JWT Token。

**请求头：** `Authorization: Bearer <old_token>`

**响应示例：**

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9..."
  }
}
```

---

#### POST `/api/v1/auth/logout`

登出，使当前 Token 失效。

**请求头：** `Authorization: Bearer <token>`

**响应示例：**

```json
{
  "code": 0,
  "message": "已登出"
}
```

---

#### POST `/api/v1/auth/reset_password`

重置密码（通过邮箱验证码）。

**请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `email` | string | 是 | 邮箱地址 |
| `verification_code` | string | 是 | 6 位验证码 |
| `new_password` | string | 是 | 新密码（至少 6 位） |

**响应示例：**

```json
{
  "code": 0,
  "message": "密码已重置"
}
```

---

#### POST `/api/v1/auth/oauth/:provider`

第三方 OAuth 登录。

**路径参数：** `provider` — `github` / `google` / `gitee`

**请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `access_token` | string | 是 | OAuth 提供方的 access_token |
| `invitation_code` | string | 视情况 | 邀请码（新用户且后台开启时必填） |

**响应示例：**

```json
{
  "code": 0,
  "message": "登录成功",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "user": { ... }
  }
}
```

新用户缺少邀请码时：

```json
{
  "code": 10003,
  "message": "请输入邀请码",
  "data": {
    "oauth_temp_token": "temp_xxx",
    "provider": "github",
    "uid": "12345"
  }
}
```

---

### 4.2 话题模块 — Topics

---

#### GET `/api/v1/topics`

话题列表。

**认证：** 不需要

**查询参数：**

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `scope` | string | 否 | `recent` | 排序方式：`recent`（最新）、`hot`（热门）、`followed`（关注）、`trending`（趋势） |
| `node_id` | integer | 否 | - | 按节点筛选 |
| `kind` | string | 否 | `all` | 类型筛选：`all`（全部）、`poll`（含投票） |
| `page` | integer | 否 | 1 | 页码 |
| `per_page` | integer | 否 | 20 | 每页条数 |

**响应示例：**

```json
{
  "code": 0,
  "data": [
    {
      "id": 1,
      "title": "Rails 8 新特性探讨",
      "slug": "rails-8-new-features",
      "excerpt": "最近 Rails 8 发布了...",
      "node": {
        "id": 1,
        "name": "技术讨论",
        "slug": "tech"
      },
      "author": {
        "id": 1,
        "username": "cooldev",
        "avatar_url": "https://..."
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

> 注：`is_cooled` 仅登录用户时返回，表示当前用户是否已点赞。

---

#### GET `/api/v1/topics/:id`

话题详情。

**认证：** 不需要（登录后返回 `is_cooled` 等个人状态）

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "id": 1,
    "title": "Rails 8 新特性探讨",
    "slug": "rails-8-new-features",
    "content": "<p>最近 Rails 8 发布了...</p>",
    "node": {
      "id": 1,
      "name": "技术讨论",
      "slug": "tech"
    },
    "author": {
      "id": 1,
      "username": "cooldev",
      "avatar_url": "https://..."
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
        { "id": 1, "title": "非常喜欢", "votes_count": 20, "voted": false },
        { "id": 2, "title": "一般般", "votes_count": 8, "voted": true },
        { "id": 3, "title": "不喜欢", "votes_count": 4, "voted": false }
      ]
    },
    "comments": [
      {
        "id": 1,
        "content": "<p>非常赞同！</p>",
        "author": {
          "id": 2,
          "username": "another_user",
          "avatar_url": "https://..."
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
            "author": { "id": 3, "username": "third_user", "avatar_url": "https://..." },
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

> 注：评论以**树形嵌套结构**返回，`replies` 为子回复数组。评论列表分页由响应头控制。

---

#### POST `/api/v1/topics`

创建话题。

**认证：** 需要

**请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `title` | string | 是 | 标题 |
| `content` | string | 是 | 内容（支持 HTML） |
| `node_id` | integer | 是 | 所属节点 ID |
| `is_repost` | boolean | 否 | 是否为转发（默认 `false`） |
| `source_url` | string | 否 | 转发来源 URL（`is_repost` 为 `true` 时） |

**响应：** 返回创建的话题对象（同详情格式，`201 Created`）。

---

#### PUT `/api/v1/topics/:id`

更新话题（仅作者可操作）。

**认证：** 需要

**请求参数：** 同创建接口。

**响应：** 返回更新后的话题对象（`200 OK`）。

---

#### DELETE `/api/v1/topics/:id`

删除话题（仅作者或管理员可操作）。

**认证：** 需要

**响应：** `204 No Content`

---

#### GET `/api/v1/topics/search`

搜索话题。

**认证：** 不需要

**查询参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `q` | string | 是 | 搜索关键词 |
| `page` | integer | 否 | 页码 |
| `per_page` | integer | 否 | 每页条数 |

**响应：** 同话题列表格式。

---

### 4.3 评论模块 — Comments

---

#### GET `/api/v1/topics/:topic_id/comments`

获取话题的评论列表（树形结构）。

**认证：** 不需要（登录后返回 `is_cooled` 等个人状态）

**查询参数：**

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `page` | integer | 否 | 1 | 页码（按根评论分页） |
| `per_page` | integer | 否 | 20 | 每页根评论数 |

**响应示例：**

```json
{
  "code": 0,
  "data": [
    {
      "id": 1,
      "content": "<p>非常赞同！</p>",
      "author": {
        "id": 2,
        "username": "another_user",
        "avatar_url": "https://..."
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
          "author": { ... },
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
  ]
}
```

> 注：`login_only` 为 `true` 的评论，未登录用户将看到隐藏提示文本。

---

#### POST `/api/v1/topics/:topic_id/comments`

创建评论。

**认证：** 需要

**请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `content` | string | 是 | 评论内容（支持 HTML） |
| `parent_id` | integer | 否 | 父评论 ID（为空则为根评论，否则为嵌套回复） |

**响应：** 返回创建的评论对象（`201 Created`）。

---

#### DELETE `/api/v1/topics/:topic_id/comments/:id`

删除评论（仅作者或管理员可操作）。

**认证：** 需要

**响应：** `204 No Content`

---

#### POST `/api/v1/comments/:id/toggle_login_only`

切换评论的"仅登录可见"状态（仅评论作者可操作）。

**认证：** 需要

**响应示例：**

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": 1,
    "login_only": true
  }
}
```

---

### 4.4 互动模块 — Interactions

---

#### POST `/api/v1/topics/:topic_id/cool`

话题点赞（+10 酷能量给话题作者）。

**认证：** 需要

**响应示例：**

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

#### DELETE `/api/v1/topics/:topic_id/cool`

取消话题点赞（-10 酷能量从话题作者扣除）。

**认证：** 需要

**响应示例：**

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

#### POST `/api/v1/comments/:id/cool`

评论点赞（从点赞者扣除 10 酷能量，转给评论作者）。

**认证：** 需要

**响应示例：**

```json
{
  "code": 0,
  "message": "已点赞",
  "data": {
    "cools_count": 6
  }
}
```

---

#### DELETE `/api/v1/comments/:id/cool`

取消评论点赞（10 酷能量退回点赞者，从评论作者扣除）。

**认证：** 需要

**响应示例：**

```json
{
  "code": 0,
  "message": "已取消点赞",
  "data": {
    "cools_count": 5
  }
}
```

---

#### POST `/api/v1/topics/:topic_id/tips`

打赏评论作者。

**认证：** 需要

**请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `comment_id` | integer | 是 | 被打赏的评论 ID |
| `amount` | integer | 是 | 打赏金额，可选值：`10`、`20`、`30`、`50`、`100` |

**响应示例：**

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

---

### 4.5 投票模块 — Polls

---

#### POST `/api/v1/topics/:topic_id/poll`

为话题创建投票（仅话题作者可操作）。

**认证：** 需要

**请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `poll[options][]` | string[] | 是 | 选项列表（至少 2 个） |
| `poll[closed]` | boolean | 否 | 是否立即关闭（默认 `false`） |

**请求示例：**

```json
{
  "poll": {
    "options": ["选项A", "选项B", "选项C"],
    "closed": false
  }
}
```

**响应示例：**

```json
{
  "code": 0,
  "message": "投票创建成功",
  "data": {
    "id": 1,
    "closed": false,
    "options": [
      { "id": 1, "title": "选项A", "votes_count": 0, "voted": false },
      { "id": 2, "title": "选项B", "votes_count": 0, "voted": false },
      { "id": 3, "title": "选项C", "votes_count": 0, "voted": false }
    ]
  }
}
```

---

#### DELETE `/api/v1/topics/:topic_id/poll`

删除话题的投票（仅话题作者可操作）。

**认证：** 需要

**响应：** `204 No Content`

---

#### POST `/api/v1/polls/:poll_id/vote`

为投票选项投票。

**认证：** 需要

**请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `poll_option_id` | integer | 是 | 选项 ID |

**响应示例：**

```json
{
  "code": 0,
  "message": "投票成功",
  "data": {
    "poll": {
      "id": 1,
      "closed": false,
      "options": [
        { "id": 1, "title": "选项A", "votes_count": 21, "voted": true },
        { "id": 2, "title": "选项B", "votes_count": 8, "voted": false },
        { "id": 3, "title": "选项C", "votes_count": 4, "voted": false }
      ]
    }
  }
}
```

---

#### POST `/api/v1/polls/:poll_id/close`

关闭投票（仅话题作者可操作）。

**认证：** 需要

**响应示例：**

```json
{
  "code": 0,
  "message": "投票已关闭"
}
```

---

#### POST `/api/v1/polls/:poll_id/open`

开启投票（仅话题作者可操作）。

**认证：** 需要

**响应示例：**

```json
{
  "code": 0,
  "message": "投票已开启"
}
```

---

### 4.6 用户模块 — Users

---

#### GET `/api/v1/users/:id`

用户公开主页。

**认证：** 不需要（登录后返回 `is_followed` 等状态）

**路径参数：** `id` — 用户 ID

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "id": 1,
    "username": "cooldev",
    "avatar_url": "https://...",
    "points": 230,
    "topics_count": 12,
    "comments_count": 45,
    "followers_count": 30,
    "following_count": 15,
    "is_followed": false,
    "is_blocked": false,
    "bio": null,
    "created_at": "2025-01-15T08:00:00.000+08:00"
  }
}
```

---

#### GET `/api/v1/users/search`

搜索用户（用于 @mention）。

**认证：** 需要

**查询参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `q` | string | 是 | 搜索关键词（用户名） |

**响应示例：**

```json
{
  "code": 0,
  "data": [
    { "id": 1, "username": "cooldev", "avatar_url": "https://..." },
    { "id": 2, "username": "cooldev2", "avatar_url": "https://..." }
  ]
}
```

---

#### POST `/api/v1/users/:id/follow`

关注用户。

**认证：** 需要

**响应示例：**

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

#### DELETE `/api/v1/users/:id/follow`

取消关注用户。

**认证：** 需要

**响应示例：**

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

#### POST `/api/v1/users/:id/block`

屏蔽用户。

**认证：** 需要

**响应示例：**

```json
{
  "code": 0,
  "message": "已屏蔽"
}
```

---

#### DELETE `/api/v1/users/:id/block`

取消屏蔽用户。

**认证：** 需要

**响应示例：**

```json
{
  "code": 0,
  "message": "已取消屏蔽"
}
```

---

### 4.7 节点模块 — Nodes

---

#### GET `/api/v1/nodes`

节点列表。

**认证：** 不需要

**查询参数：**

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `kind` | string | 否 | `all` | 筛选类型：`all`（全部）、`system`（系统节点）、`interest`（兴趣节点） |

**响应示例：**

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

> 注：`is_followed` 仅登录用户时返回。

---

#### POST `/api/v1/nodes/:id/follow`

关注节点。

**认证：** 需要

**响应示例：**

```json
{
  "code": 0,
  "message": "已关注"
}
```

---

#### DELETE `/api/v1/nodes/:id/follow`

取消关注节点。

**认证：** 需要

**响应示例：**

```json
{
  "code": 0,
  "message": "已取消关注"
}
```

---

### 4.8 个人中心模块 — Profile

---

#### GET `/api/v1/profile`

获取当前用户信息及统计数据。

**认证：** 需要

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "user": {
      "id": 1,
      "email": "user@example.com",
      "username": "cooldev",
      "avatar_url": "https://...",
      "points": 230,
      "role": "user",
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

#### PUT `/api/v1/profile`

更新个人信息。

**认证：** 需要

**请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `username` | string | 否 | 新用户名 |
| `avatar` | file | 否 | 新头像（multipart/form-data） |

**响应示例：**

```json
{
  "code": 0,
  "message": "更新成功",
  "data": {
    "id": 1,
    "email": "user@example.com",
    "username": "new_name",
    "avatar_url": "https://...",
    "points": 230
  }
}
```

---

#### PUT `/api/v1/profile/password`

修改密码。

**认证：** 需要

**请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `current_password` | string | 是 | 当前密码 |
| `new_password` | string | 是 | 新密码（至少 6 位） |
| `new_password_confirmation` | string | 是 | 确认新密码 |

**响应示例：**

```json
{
  "code": 0,
  "message": "密码已修改"
}
```

---

### 4.9 签到模块 — CheckIn

---

#### POST `/api/v1/check_in`

每日签到（+10 酷能量，每日限一次）。

**认证：** 需要

**响应示例：**

```json
{
  "code": 0,
  "message": "签到成功，酷能量 +10",
  "data": {
    "points_earned": 10,
    "total_points": 240,
    "consecutive_days": 5,
    "today_checked_in": true
  }
}
```

已签到时：

```json
{
  "code": 10006,
  "message": "今日已签到",
  "data": {
    "today_checked_in": true,
    "total_points": 230,
    "consecutive_days": 5
  }
}
```

---

### 4.10 通知模块 — Notifications

---

#### GET `/api/v1/notifications`

通知列表。

**认证：** 需要

**查询参数：**

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `page` | integer | 否 | 1 | 页码 |
| `per_page` | integer | 否 | 20 | 每页条数 |

**响应示例：**

```json
{
  "code": 0,
  "data": [
    {
      "id": 1,
      "notify_type": "comment",
      "read": false,
      "actor": {
        "id": 2,
        "username": "another_user",
        "avatar_url": "https://..."
      },
      "notifiable": {
        "type": "Comment",
        "id": 5,
        "content": "<p>非常赞同！</p>",
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
| `comment` | 评论通知 |
| `reply` | 回复通知 |
| `mention` | @提及通知 |
| `follow` | 关注通知 |
| `cool` | 话题点赞通知 |
| `comment_cool` | 评论点赞通知 |
| `tip` | 打赏通知 |
| `poll_vote` | 投票通知 |

---

#### GET `/api/v1/notifications/unread_count`

获取未读通知数。

**认证：** 需要

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "unread_count": 5
  }
}
```

---

#### PUT `/api/v1/notifications/:id/read`

标记单条通知为已读。

**认证：** 需要

**响应示例：**

```json
{
  "code": 0,
  "message": "已标记为已读"
}
```

---

#### PUT `/api/v1/notifications/read_all`

标记全部通知为已读。

**认证：** 需要

**响应示例：**

```json
{
  "code": 0,
  "message": "已全部标记为已读"
}
```

---

### 4.11 图片上传模块 — Images

---

#### POST `/api/v1/images`

上传图片。

**认证：** 需要

**请求类型：** `multipart/form-data`

**请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `file` | file | 是 | 图片文件（最大 5MB，支持 JPG/PNG/GIF/WebP） |

**响应示例：**

```json
{
  "code": 0,
  "message": "上传成功",
  "data": {
    "id": 1,
    "url": "https://your-domain.com/images/1"
  }
}
```

---

### 4.12 杂项模块 — Misc

---

#### GET `/api/v1/chat_groups`

获取交流群列表（按类别分组）。

**认证：** 不需要

**响应示例：**

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
          "members_count": 150,
          "is_active": true
        }
      ],
      "QQ群": [ ... ],
      "Telegram": [ ... ],
      "Discord": [ ... ]
    }
  }
}
```

---

#### GET `/api/v1/site_info`

获取站点公开信息。

**认证：** 不需要

**响应示例：**

```json
{
  "code": 0,
  "data": {
    "site_name": "SoloDev.Cool",
    "site_title": "SoloDev.Cool - 独立开发者社区",
    "site_description": "面向独立开发者的中文技术社区",
    "logo_url": "https://...",
    "favicon_url": "https://...",
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

---

#### GET `/api/v1/friend_links`

获取友情链接列表。

**认证：** 不需要

**响应示例：**

```json
{
  "code": 0,
  "data": [
    {
      "id": 1,
      "name": "Ruby China",
      "url": "https://ruby-china.org",
      "description": "Ruby 中文社区",
      "logo_url": "https://...",
      "sort_order": 1
    }
  ]
}
```

---

## 五、积分规则说明

| 行为 | 积分变化 | 说明 |
|------|---------|------|
| 每日签到 | +10 | 每日限一次 |
| 话题被点赞 | +10 | 点赞者 -10，话题作者 +10 |
| 取消话题点赞 | -10 | 话题作者 -10，点赞者 +10 |
| 评论被点赞 | +10 | 点赞者 -10，评论作者 +10 |
| 取消评论点赞 | -10 | 评论作者 -10，点赞者 +10 |
| 被打赏 | +打赏金额 | 打赏者 -金额，评论作者 +金额 |
| 投票 | 无积分变化 | — |

---

## 六、实施路线图

### 第一阶段：基础设施 + 核心功能

1. 添加 `devise-jwt` gem，配置 JWT 认证
2. 创建 `Api::V1::BaseController`（认证、统一错误处理、分页）
3. 实现认证接口（注册/登录/登出/刷新/重置密码）
4. 实现话题列表 + 详情
5. 实现评论列表 + 创建

### 第二阶段：社交互动

6. 实现点赞/取消点赞（话题 + 评论）
7. 实现关注/取消关注（用户 + 节点）
8. 实现通知模块
9. 实现用户主页 + 搜索

### 第三阶段：完整功能

10. 实现打赏
11. 实现投票
12. 实现签到
13. 实现图片上传
14. 实现个人中心
15. 实现杂项接口（交流群/站点信息/友情链接）

### 第四阶段：第三方登录

16. 实现 OAuth 第三方登录（GitHub / Google / Gitee）
