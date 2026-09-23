# 《风铃谷》进度与下一步（2026-09-22）

## 一句话

Godot 4 全平台田园生活冒险 **《风铃谷》**：玩法与数据基本齐，**Windows / Web / Android 安装包已能本地导出**；下一步把构建搬到 **NAS Docker Runner**，与本机脱钩。

---

## 已完成

### 玩法 / 代码
- 数据表完整并通过校验：items 221+、crops 48、recipes 72+、npcs 8、mine 26 层等
- 工具升级线：木→铜→铁→银晶→星纹（4 类工具 × 5 阶 + 16 条升级配方）
- 品阶实效：采集/挖矿产出、伤害随 power 提升
- 共鸣田园 3×3：风铃/晶灯家具促生长、加闪光
- 矿洞谜题：压力板 + 推石箱，每 3 层一组
- 对话日志（暂停菜单可回看，存档持久化）
- 多存档槽：slot0–2 + auto，暂停菜单可选槽
- 工坊阶梯：木工坊 / 铜炉 / 晶灯工坊 + 配方按站归属
- 图鉴：蝴蝶 6 种、风铃音色 6 种
- 冒烟测试 `SMOKE OK`，主场景可无头启动

### 构建 / 发布
| 产物 | 路径 | 状态 |
|---|---|---|
| Windows | `dist/fenglinggu_win.exe` | 已导出（约 316MB，embed pck） |
| Web | `dist/web/index.html` 等 | 已导出 |
| Android | `dist/fenglinggu.apk` | 已签名导出（调试 keystore） |
| iOS IPA | — | **无法在 Windows 出包**（需 macOS + Xcode） |

### 工具链
- Godot 4.7.2 + 全平台导出模板（`%APPDATA%\Godot\export_templates\4.7.2.stable\`）
- Android SDK：`D:\Android\Sdk`（platform-tools + build-tools 34）
- 调试 keystore：`dist/debug.keystore`（密码 android / alias androiddebugkey）
- Gitea 远程：`http://192.168.31.125:13000/banshengci/fenglinggu.git`
- 本机 `act_runner` v0.2.11 已注册（标签 `windows`），可停用

### 关键修复
- `export_presets.cfg` 补全字段；`project.godot` 开 ETC2/ASTC
- `gen_content.py` 配方占位与产出 id
- `world.gd` 类型推断编译错误
- 工作流去掉 GitHub 依赖（外网不通）；改为本机/容器直接导出

---

## 下一步（到公司接着做）

### 优先 1：NAS 独立云端构建（已备好配置，待部署）
1. 仓库里已有 `deploy/nas-runner/`：
   - `docker-compose.yml` — act_runner 容器
   - `README.md` — 部署步骤
2. 在绿联云 NAS 上：
   - Gitea 网页创建新 Runner，复制 Token
   - 把 `deploy/nas-runner/` 拷到 NAS，填 Token
   - `docker compose up -d`
3. `.gitea/workflows/build.yml` 已改为 **容器构建**（`barichello/godot-ci:4.7`）：
   - jobs：windows / web / android
   - 与 Windows 本机无关
4. **注意**：刚才 `git push` 因本机代理 `127.0.0.1:7897` 失败，本地已有提交 `7b5964d`，到公司或恢复网络后：
   ```powershell
   git push
   ```
5. 若 NAS 拉不动 `barichello/godot-ci`，配置 Docker 镜像加速后重试

### 优先 2：验证 NAS 构建
- push 后看 Gitea Actions 是否三个 job 都绿
- 确认产物大小合理（win ~300MB / apk ~250MB / web 含 pck）

### 优先 3：iOS（可选）
- 需 macOS：GitHub Actions `macos-latest` 或公司 Mac / macOS 云机
- 无付费开发者账号：免费 Apple ID 自签 7 天、3 台设备
- 可先用 Web 版给 iPhone

### 其它可选
- 集市周溢价、共鸣同族差异化
- ObjectDB 退出时 2 个实例泄漏（非阻塞）
- 手柄/触屏真机走查
- 正式发布 keystore（替换调试签名）

---

## 常用命令

```powershell
# 数据校验
node tools\check_data.mjs

# 重新生成内容表
& $env:MIMO_PYTHON tools\gen_content.py

# 冒烟
& "C:\Users\半生此\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --path game -s res://tools/smoke_test.gd

# 导出 Windows
& "...Godot_v4.7.2-stable_win64_console.exe" --headless --path game --export-release "Windows Desktop" dist/fenglinggu_win.exe
```

## 仓库

- 远程：`http://192.168.31.125:13000/banshengci/fenglinggu.git`
- 本地最新提交：`7b5964d`（可能未 push，见上）
