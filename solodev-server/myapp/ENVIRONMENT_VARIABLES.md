# 环境变量配置文档

本项目使用 PostgreSQL 数据库，通过环境变量进行配置。

## 容器运行环境

⚠️ **重要**: Docker 容器默认运行在 **production** 环境。

Dockerfile 中已设置 `RAILS_ENV="production"`，容器启动时会自动连接到生产数据库 `myapp_production`。

如需在容器中使用其他环境，可以在运行时覆盖：

```bash
docker run -e RAILS_ENV=development ...
```

## 存储目录挂载

⚠️ **重要**: 为避免容器删除后上传的图片丢失，必须挂载存储目录。

### 上传文件存储位置

生产环境使用本地磁盘存储，路径：`/rails/storage`

### 容器运行命令示例

```bash
# 挂载存储目录到宿主机
docker run -d \
  -p 80:80 \
  -v /path/on/host/storage:/rails/storage \
  -e SECRET_KEY_BASE=<your_secret_key_base> \
  -e DB_HOST=<your_db_host> \
  -e DB_USERNAME=<your_db_user> \
  -e DB_PASSWORD=<your_db_password> \
  --name myapp \
  myapp
```

### 生成 SECRET_KEY_BASE

在生产环境中运行以下命令生成一个安全的密钥：

```bash
# 在 Rails 项目目录下执行
rails secret
```

或者使用 Ruby：

```bash
ruby -rsecurerandom -e 'puts SecureRandom.hex(64)'
```

**参数说明：**
- `-v /path/on/host/storage:/rails/storage` - 将宿主机的 `/path/on/host/storage` 目录挂载到容器的 `/rails/storage`，确保文件持久化
- `-e SECRET_KEY_BASE` - **必需**，Rails 生产环境密钥（使用 `rails secret` 生成）
- 其他数据库环境变量

## 必需的环境变量

| 变量名 | 必填 | 说明 |
|--------|------|------|
| `SECRET_KEY_BASE` | **是** | Rails 生产环境密钥，用于加密会话、cookies 等 |

## 数据库配置

| 变量名 | 必填 | 默认值 | 说明 |
|--------|------|--------|------|
| `DB_HOST` | 否 | `127.0.0.1` | 数据库服务器地址 |
| `DB_PORT` | 否 | `5432` | 数据库端口 |
| `DB_USERNAME` | 否 | `solodev` | 数据库用户名 |
| `DB_PASSWORD` | 否 | `solodev` | 数据库密码 |
| `RAILS_MAX_THREADS` | 否 | `5` | Rails 数据库连接池最大线程数 |

## 环境说明

### Development 环境
- 数据库名: `myapp_development`

### Test 环境
- 数据库名: `myapp_test`

### Production 环境
- 数据库名: `myapp_production`

## 使用方式

### 方式 1: 设置系统环境变量

```bash
export DB_HOST=your_database_host
export DB_PORT=5432
export DB_USERNAME=your_username
export DB_PASSWORD=your_password
export RAILS_MAX_THREADS=10
```

### 方式 2: 使用 .env 文件（需配合 dotenv gem）

创建 `.env` 文件（已在 `.gitignore` 中，不会被提交到版本控制）：

```env
DB_HOST=your_database_host
DB_PORT=5432
DB_USERNAME=your_username
DB_PASSWORD=your_password
RAILS_MAX_THREADS=10
```

### 方式 3: 在启动命令中直接指定

```bash
DB_HOST=your_host DB_USERNAME=your_user DB_PASSWORD=your_pass rails server
```

## 安全提示

- ⚠️ **不要**将包含敏感信息的环境变量文件提交到版本控制系统
- `.env*` 文件已在 `.dockerignore` 中被忽略
- 生产环境请使用强密码
- 建议使用专业的密钥管理工具（如 Rails credentials、AWS Secrets Manager 等）
