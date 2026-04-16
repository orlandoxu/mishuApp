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

### 3. 服务端（公网机器）启动 frps

示例（按你实际安装路径执行）：

```bash
cd /path/to/frp
./frps -c /path/to/mishuApp/backend/nginx/frps.toml
```

默认端口说明：

- `7000`：frpc 连接 frps 的控制端口
- `18080`：frps HTTP 虚拟主机端口（给 nginx 反向代理使用）

### 4. 本地开发机启动 backend + frpc

先启动本地 backend（监听 `3000`），再启动 frpc：

```bash
cd /path/to/frp
./frpc -c /path/to/mishuApp/backend/nginx/frpc.toml
```

### 5. nginx 转发说明

`backend/nginx/nginx.conf` 已增加：

- `location = /local`
- `location ^~ /local/`

这两个路由会转发到 `127.0.0.1:18080`（frps），并去掉 `/local` 前缀后再发给本地 backend。

例如：

- `https://api.landeng.fun/local/health` -> 本地 backend 的 `/health`

### 6. 重载 nginx

在公网服务器执行：

```bash
nginx -t
nginx -s reload
```

### 7. 快速验证

```bash
curl -i https://api.landeng.fun/local/health
```

返回本地 backend 的健康检查结果即说明链路可用。
