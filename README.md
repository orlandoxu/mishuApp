# mishuApp Monorepo

## 目录

- `ios`：iOS 工程
- `backend`：Node/Bun 后端服务
- `mishuAppUI`：前端子项目
- `SDao`：协作/服务模块

## backend 使用 FRP 暴露本地服务到 `api.landeng.fun/local`

目标：把你本地跑在 `127.0.0.1:3000` 的 backend，通过 FRP 映射到线上域名路径 `https://api.landeng.fun/local`。

### 1. 配置文件位置

- FRP 服务端（部署在公网服务器）：`backend/nginx/frps.toml`
- FRP 客户端（运行在本地开发机）：`backend/nginx/frpc.toml`
- Nginx 转发配置：`backend/nginx/nginx.conf`

### 2. 先改密钥

把 `backend/nginx/frps.toml` 和 `backend/nginx/frpc.toml` 里的：

- `auth.token = "replace-with-strong-token"`

改成同一个强密码。

### 3. 一键后台启动脚本（会先终止上一个进程）

仓库根目录提供了：

- `./startFrps.sh`：启动 frps（服务端）
- `./startFrpc.sh`：启动 frpc（客户端）

它们会自动：

- 查找并终止同配置的旧进程
- 使用 `nohup` 在后台启动
- 输出日志到：
  - `backend/nginx/frps.log`
  - `backend/nginx/frpc.log`

直接运行：

```bash
./startFrps.sh
./startFrpc.sh
```

如果 `frps/frpc` 不在 PATH，可临时指定：

```bash
FRPS_BIN=/path/to/frps ./startFrps.sh
FRPC_BIN=/path/to/frpc ./startFrpc.sh
```

### 4. nginx 转发说明

`backend/nginx/nginx.conf` 已增加：

- `location = /local`
- `location ^~ /local/`

这两个路由会转发到 `127.0.0.1:18080`（frps），并去掉 `/local` 前缀后再发给本地 backend。

例如：

- `https://api.landeng.fun/local/health` -> 本地 backend 的 `/health`

### 5. 重载 nginx

在公网服务器执行：

```bash
nginx -t
nginx -s reload
```

### 6. 快速验证

```bash
curl -i https://api.landeng.fun/local/health
```

返回本地 backend 的健康检查结果即说明链路可用。
