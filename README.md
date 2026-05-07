# mishuApp Monorepo

## 目录
- `ios`：iOS 工程
- `backend`：Bun 后端服务
- `admin`：管理后台（Vite）
- `h5`：H5 邀请页（Vite）
- `mishuAppUI`：Web 原型（UI 基准）

## 服务管理约定（必须）
- 本项目所有长期服务统一用 PM2 管理，不使用 `bun run dev` / `vite` / `startFrpc.sh` 前台常驻方式。
- 启动全部服务：`pnpm pm2:start`
- 重启全部服务：`pnpm pm2:restart`
- 停止全部服务：`pnpm pm2:stop`
- 查看状态：`pm2 list`
- 查看日志：`pm2 logs <name>`
- 修改 `ecosystem.config.cjs` 后，必须执行：`pm2 save`

## PM2 进程说明与访问方式
当前 `pm2 list` 中应包含以下 6 个进程：

1. `rest`
- 作用：主后端 HTTP API 服务（Bun/Fastify）。
- 本机访问：`http://127.0.0.1:3000`
- 健康检查：`http://127.0.0.1:3000/health`

2. `cron`
- 作用：后端定时任务进程（跑计划任务，不提供 HTTP 页面）。
- 访问方式：无独立 URL，通过 `pm2 logs cron` 观察执行日志。

3. `socket`
- 作用：后端 WebSocket 服务进程。
- 访问方式：按业务端口连接（以代码配置为准），通过 `pm2 logs socket` 观察连接与消息日志。

4. `admin`
- 作用：管理后台前端开发服务。
- 本机访问：`http://127.0.0.1:8300`
- 局域网访问：`http://<你的局域网IP>:8300`
- API 基址：默认 `https://api.landeng.fun/local`（与 iOS 统一）；可用 `VITE_API_BASE_URL` 覆盖。

5. `h5`
- 作用：H5 邀请页前端开发服务。
- 本机访问：`http://127.0.0.1:8200`
- 局域网访问：`http://<你的局域网IP>:8200`

6. `frpc`
- 作用：FRP 客户端隧道，把本地服务暴露到外网网关。
- 外网示例：`https://api.landeng.fun/local/health`（映射到本地 `rest` 的 `/health`）。

## FRP 与网关（`/local`）说明
目标：把本地 `rest`（`127.0.0.1:3000`）通过 FRP 映射到 `https://api.landeng.fun/local`。

- FRP 配置：`ops/frp/conf/frps.toml`、`ops/frp/conf/frpc.toml`
- FRP 二进制：`ops/frp/bin/*`
- FRP 日志：`ops/frp/logs/*`
- Nginx 配置：`ops/nginx/nginx.conf`

`nginx` 通过 `/local` 前缀转发到 FRP 入口，再回源本地 `rest` 服务。

## Admin API 基址覆盖（可选）
- 默认不需要配置：`admin` 会请求 `https://api.landeng.fun/local/admin/*`。
- 如需临时切本地后端，可在 `admin/.env.local` 增加：`VITE_API_BASE_URL=http://127.0.0.1:3000`
