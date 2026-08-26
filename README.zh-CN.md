# 光之守护者桌面宠物

[English README](README.md)

“光之守护者”是一款原创特摄宇宙英雄风格的 Windows 桌面宠物，同时附带兼容 Codex v2 的宠物图集。

![光之守护者动画预览](docs/preview.png)

## 功能

- 每 3 分钟自动切换红色与蓝色形态。
- 点击宠物会显示“给你光的力量”，并播放挥手动作。
- 5 分钟没有互动后，宠物会在主屏幕底部左右巡航。
- 右键可将大小调整为 50%、75%、100%、125%、150% 或 200%。
- 支持拖动位置、立即切换形态、回到右下角和退出。
- 附带 8 × 11、sprite version 2 图集及 16 个注视方向。

## 快速开始

运行环境：Windows 10/11，Windows PowerShell 5.1 或更高版本。

1. 下载并解压最新 Release 压缩包。
2. 双击 `launch.cmd` 或 `启动光之守护者.cmd`。
3. 如果 Windows 显示安全提示，可先查看仓库中的 PowerShell 源代码再决定是否运行。

可选启动参数：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\LightGuardianPet.ps1 -StartForm blue -Scale 1.25 -IdleSeconds 300
```

## 安装到 Codex

将 `codex-pet` 文件夹复制到：

```text
%USERPROFILE%\.codex\pets\light-guardian
```

随后重启 Codex，在宠物列表中选择“光之守护者”。定时切换、点击文字、大小菜单与闲置飞行由独立 Windows 启动器实现。

## 授权与声明

- 程序源代码使用 [MIT License](LICENSE)。
- 角色美术和精灵图仅限个人、非商业使用，详见 [ASSET-LICENSE.md](ASSET-LICENSE.md)。
- 本项目是原创的特摄英雄致敬作品，与圆谷制作或其他权利方无隶属、授权或背书关系；项目不包含原作标志，也不含从游戏或动画中提取的素材。

## 制作说明

角色图像采用 AI 辅助生成，并通过确定性图集组装与方向、透明度和布局检查。
