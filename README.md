# mishuApp Monorepo

## 目录

- `ios`：iOS 工程
- `backend`：Node/Bun 后端服务
- `mishuAppUI`：前端子项目
- `SDao`：协作/服务模块

## backend 使用 FRP 暴露本地服务到 `api.landeng.fun/local`

目标：把你本地跑在 `127.0.0.1:3000` 的 backend，通过 FRP 映射到线上域名路径 `https://api.landeng.fun/local`。

### 1. 运维目录结构（全部在根目录 `ops/`）

- 服务端配置：`ops/frp/conf/frps.toml`
- 客户端配置：`ops/frp/conf/frpc.toml`
- 内置二进制：
  - `ops/frp/bin/linux_amd64/frps`、`ops/frp/bin/linux_amd64/frpc`
  - `ops/frp/bin/linux_arm64/frps`、`ops/frp/bin/linux_arm64/frpc`
  - `ops/frp/bin/darwin_arm64/frps`、`ops/frp/bin/darwin_arm64/frpc`
- 日志目录：`ops/frp/logs`
- 启动脚本：`ops/frp/startFrps.sh`、`ops/frp/startFrpc.sh`
- Nginx 转发配置：`ops/nginx/nginx.conf`

### 2. 先改密钥

把 `ops/frp/conf/frps.toml` 和 `ops/frp/conf/frpc.toml` 里的：

- `auth.token = "replace-with-strong-token"`

改成同一个强密码。

### 3. 一键后台启动脚本（会先终止上一个进程）

仓库根目录提供了：

- `./startFrps.sh`：启动 frps（实际执行 `ops/frp/startFrps.sh`）
- `./startFrpc.sh`：启动 frpc（实际执行 `ops/frp/startFrpc.sh`）

它们会自动：

- 查找并终止同配置的旧进程
- 使用 `nohup` 在后台启动
- 输出日志到：
  - `ops/frp/logs/frps.log`
  - `ops/frp/logs/frpc.log`

直接运行：

```bash
./startFrps.sh
./startFrpc.sh
```

默认会自动选用 `ops/frp/bin` 下的二进制。  
如果需要手动指定，可临时设置：

```bash
FRPS_BIN=/path/to/frps ./startFrps.sh
FRPC_BIN=/path/to/frpc ./startFrpc.sh
```

### 4. nginx 转发说明

`ops/nginx/nginx.conf` 已增加：

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
