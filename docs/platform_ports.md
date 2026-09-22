# 全平台移植说明

| 平台 | 预设 | 备注 |
|---|---|---|
| Windows | Windows Desktop | 主 Demo |
| Linux | Linux | 独立分发 |
| macOS | macOS | 上架需签名公证 |
| Android | Android | 触屏摇杆自动启用 |
| iOS | iOS | TestFlight / 商店 |
| Web | Web | 试玩 Demo |
| 主机 | 控制台模板 | 需厂商 SDK |

## 操作矩阵

| 输入 | 移动 | 交互 | 工具 | UI |
|---|---|---|---|---|
| 键鼠 | WASD | E / 左键 | 左键 | I C M Esc |
| 手柄 | 左摇杆 | A | X | Y / LB / Start |
| 触屏 | 左侧虚拟摇杆 | 点击目标 | 同交互 | 屏幕按钮 |

## 分辨率

- 逻辑 1280x720，canvas_items 拉伸，keep 宽高比
- 手机横屏优先；UI 热区 >= 48px

## 构建

```powershell
godot --headless --path game --export-release "Windows Desktop" ..\dist\fenglinggu_win.exe
godot --headless --path game --export-release "Android" ..\dist\fenglinggu.apk
godot --headless --path game --export-release "Web" ..\dist\web\index.html
```
