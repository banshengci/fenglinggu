# 绿联云 NAS · 独立云端构建

构建与你电脑无关：Runner 跑在 NAS 的 Docker 里。

## 1. 创建 Runner

Gitea → 仓库 → 设置 → 工作流 → 运行器 → **创建新运行器**，复制 Token。

## 2. 启动 Runner

把本目录 `deploy/nas-runner/` 拷到 NAS，编辑 `docker-compose.yml`：

- `GITEA_RUNNER_REGISTRATION_TOKEN` = 刚才的 Token
- `GITEA_INSTANCE_URL` = NAS 上的 Gitea 地址

然后：

```bash
docker compose up -d
```

刷新 Gitea「运行器管理」，应出现 **nas-docker / 空闲**。

## 3. 触发构建

`git push` 或网页手动触发工作流。产物在 job 日志里，或：

```bash
docker exec gitea-runner ls /data
```

## 说明

| 平台 | 镜像 | 说明 |
|---|---|---|
| Windows | `barichello/godot-ci:4.7` | 出 exe |
| Web | 同上 | 出 index.html |
| Android | 同上 | 出 apk（调试签名） |
| iOS | — | 仍需 macOS，本方案不覆盖 |

国内拉不动 `barichello/godot-ci` 时，给 NAS Docker 配镜像加速，或先 `docker pull` 再构建。

## 与本机 Runner 关系

- Windows 上的 `act_runner` 可停用（任务会跑到 NAS）
- 或保留双 Runner，标签区分（`windows` / `ubuntu-latest`）
