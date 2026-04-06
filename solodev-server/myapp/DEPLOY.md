# 部署说明

## Docker 日志配置

生产环境日志输出到文件 `/rails/log/production.log`，自动轮转，保留 5 个文件，每个最大 10MB。

### 运行容器

```bash
docker build -t myapp .

docker run -d -p 80:80 \
  -v ./log:/rails/log \
  -e RAILS_MASTER_KEY=<value from config/master.key> \
  --name myapp myapp
```

### 查看日志

```bash
# 实时查看
tail -f log/production.log

# 查看最近 100 行
tail -n 100 log/production.log
```

### 日志轮转规则

| 文件 | 说明 |
|---|---|
| `production.log` | 当前日志文件 |
| `production.log.0` | 上一份 |
| `production.log.1` | 上两份 |
| ... | 最多到 `.log.4` |

每个文件最大 10MB，超出后自动轮转，旧文件会被删除。
