# Meowa 游戏资产生成与 GitHub 发布指南

本文档记录本项目使用 Meowa 生成写实像素游戏资产、接入 Godot，
以及将正式资源提交到 GitHub 的完整流程。

## 1. 安装 Codex 技能

```powershell
npx skills add https://github.com/Meowa-AI/meowa-skills --skill game-assets
```

也可以使用 Codex 自带的技能安装器，从仓库中的
`skills/game-assets` 安装。安装完成后需要重启 Codex。

技能默认位于：

```text
%USERPROFILE%\.codex\skills\game-assets
```

CLI 主程序：

```text
%USERPROFILE%\.codex\skills\game-assets\meowart_api.py
```

Python 需要安装 `requests`：

```powershell
python -m pip install requests
```

## 2. 配置 API 密钥

在 [Meowa API Keys](https://meowa.ai/#/api-keys) 创建用户密钥。

Windows 推荐保存为用户环境变量：

```powershell
setx MEOWART_API_KEY "ma_live_你的密钥"
```

设置后重启 Codex 或终端。不要：

- 把密钥发到聊天中；
- 把密钥写进 Git 仓库；
- 将包含密钥的 `.env` 提交到 GitHub；
- 在截图、日志或 PR 描述里展示密钥。

如果当前 PowerShell 进程还没有继承密钥，可以临时读取用户变量：

```powershell
$env:MEOWART_API_KEY = [Environment]::GetEnvironmentVariable(
  "MEOWART_API_KEY",
  "User"
)
```

## 3. 每次任务先读取最新指南

Meowa 的模板、参数与接口可能更新。生成前先执行：

```powershell
cd "$env:USERPROFILE\.codex\skills\game-assets"
python .\meowart_api.py skill-doc --task "生成横版写实像素僵尸角色"
```

诊断 CLI 与动态文档：

```powershell
python .\meowart_api.py skill-doc-status --check
python .\meowart_api.py bootstrap-status --check
```

禁止自行调用不存在的 `/generate` 或 `/api/generate`。应始终通过 CLI
选择当前正确的 Meowa 工作流。

## 4. 检查账户与额度

```powershell
python .\meowart_api.py credits-balance
```

返回值中：

- `trial_credits`：试用额度；
- `credits`：付费额度；
- `next_trial_credit_expires_at`：试用额度到期时间。

某些工作流只接受付费额度。例如动画任务可能返回：

```text
credit_type_mismatch
```

这不代表密钥失效。可改用像素模板生成连续姿势帧，或充值后继续。
服务端参数验证失败时，应检查响应中的 `credit_refund`；正常情况下
失败任务会自动退款。

## 5. 选择正确的生成命令

| 资产类型 | 推荐命令 |
|---|---|
| 像素角色、僵尸、道具、枪械 | `pixel-gen-run` |
| 高清透明角色或图标 | `hd-gen-run` |
| 游戏 HUD、菜单、按钮和 UI sheet | `ui-gen-run` |
| 角色八方向图 | `character-multi-view-run` |
| 无缝横向或纵向背景 | `self-loop-run` |
| 地面纹理 | `texture-gen-run` |
| Dual-grid terrain | `tileset-gen-run` |
| 等距或六边形地图块 | 先 `map-reference-search`，再对应生成命令 |
| 去除像素图白底 | `remove-background-run --method pixel` |
| 动画、GIF 或 spritesheet | `animate-run` |
| 音效 | `sound-run` |
| BGM | `music-run` |

像素资产优先使用专用模板，不要先生成普通大图再随意缩小。

## 6. 查询像素模板

```powershell
python .\meowart_api.py pixel-gen-template-info
```

本项目用过的模板：

- `large_3_4`：写实像素人物，默认一次生成两张；
- `weapon`：64×64 武器包，固定 4×4 网格，单批最多 8 件。

模板的 `target_count`、输出尺寸和方向支持以实时返回为准。

## 7. 先 dry-run，再正式生成

dry-run 不提交任务、不消耗额度：

```powershell
python .\meowart_api.py pixel-gen-run `
  --template-name "weapon" `
  --job-name "realistic_firearms" `
  --requirement "Seven separate side-view realistic pixel-art firearms..." `
  --template-config '{\"target_count\":7,\"remove_bg_method\":\"pixel\"}' `
  --output-dir "D:\project\art\meowa" `
  --dry-run
```

确认以下信息：

- `template_name` 是否正确；
- `target_count` 是否在模板范围内；
- `reference_file` 是否存在；
- `planned_output_dir` 是否足够短；
- 输出目录是否位于明确的任务文件夹。

Windows PowerShell 传 JSON 时，需要保留转义后的双引号：

```powershell
'{\"target_count\":7,\"remove_bg_method\":\"pixel\"}'
```

## 8. 正式生成示例

### 8.1 生成人物双帧

```powershell
python .\meowart_api.py pixel-gen-run `
  --template-name "large_3_4" `
  --job-name "survivor_walk_frames" `
  --requirement "Two consecutive realistic pixel-art survivor walk frames..." `
  --reference-file "D:\project\references\survivor.png" `
  --output-dir "D:\project\art\meowa" `
  --max-wait 600 `
  --poll-interval 5
```

### 8.2 生成武器包

```powershell
python .\meowart_api.py pixel-gen-run `
  --template-name "weapon" `
  --job-name "realistic_firearm_overlays" `
  --requirement "Seven separate side-view realistic pixel-art firearms..." `
  --template-config '{\"target_count\":7,\"remove_bg_method\":\"pixel\"}' `
  --output-dir "D:\project\art\meowa" `
  --max-wait 600 `
  --poll-interval 5
```

注意：实际输出顺序可能与提示词顺序不同。必须查看响应中的
`sprite_pack_names`，再将 `sprite_00.png` 等文件映射到正确名称。

## 9. 提示词编写原则

角色或武器提示词应明确：

- 视角：`side-view`；
- 朝向：`facing right` 或 `facing left`；
- 风格：`realistic pixel-art`；
- 解剖：`mature realistic anatomy`；
- 调色：`restrained earthy palette`；
- 光照方向；
- 透明背景；
- 每张图只出现一个目标；
- 禁止文字、标签、人物手部或多余道具；
- 多帧时要求保持角色身份、服装、比例和像素密度一致。

武器覆盖层还应要求：

```text
all pointing right and aligned horizontally
```

## 10. 验证生成结果

交付前至少检查：

1. 图片尺寸；
2. 是否为 RGBA/透明 PNG；
3. 透明边缘是否干净；
4. 像素是否保持硬边；
5. 角色或武器朝向；
6. 多帧是否为同一角色；
7. 武器名称与下载顺序；
8. 预览图是否存在重复、缺失或错误对象；
9. 额度是否正确扣除或退款。

像素预览和缩放必须使用 nearest-neighbor。不要使用双线性缩放，
否则边缘会变糊。

## 11. Windows 常见问题

### 11.1 路径过长

如果没有指定 `--job-name`，CLI 可能用完整提示词生成目录名，导致：

```text
WinError 3
```

解决方法：

```powershell
--job-name "short_task_name"
```

并使用短输出根目录，例如：

```text
D:\project\art\meowa
```

### 11.2 找不到 requests

```powershell
python -m pip install requests
```

### 11.3 新 PNG 在 Godot 中无法 preload

先让 Godot 执行一次资源导入：

```powershell
godot --headless --editor --path godot --quit
```

随后再运行测试。

### 11.4 找不到 Godot 命令

本项目曾使用便携版 Godot，路径不一定在 `PATH` 中。可以直接调用
完整可执行文件路径，或将其加入环境变量。

## 12. 接入 Godot

推荐保留两层：

1. 无武器人物基础动画；
2. 独立武器 `Sprite2D` 覆盖层。

这样无需为每把枪重新生成整套人物动画。

每把武器应配置：

- 覆盖层纹理；
- `overlay_scale`；
- 人物握持锚点；
- `muzzle_distance`；
- 射击后坐距离；
- 换弹旋转与下压幅度；
- 近战挥动角度；
- HUD/商店图标。

枪口火焰、子弹出生点和枪口粒子必须共用同一个枪口计算结果，
否则会出现枪口和弹道分离。

Godot 项目资源目录示例：

```text
godot/assets/weapons/
  pistol.png
  uzi.png
  kar98k.png
  shotgun.png
  ak47.png
  m4.png
  m249.png
  knife.png
  machete.png
```

## 13. 原始资产与正式资产

建议目录分工：

```text
art/meowa/                    原始生成任务、预览和响应
godot/assets/weapons/         游戏正式使用的资源
godot/assets/sprites/         正式人物与敌人资源
```

原始目录可能包含大量预览、任务 JSON 和重复版本，通常不应全部提交。
只将最终选中的资产复制到 Godot 正式目录。

## 14. 上传到 GitHub

先检查状态：

```powershell
git status -sb
git diff --check
```

工作区存在无关修改时，不要运行 `git add -A`。应显式暂存：

```powershell
git add -- `
  docs/MEOWA_GAME_ASSETS_GUIDE.md `
  godot/assets/weapons `
  godot/src/entities/player.gd
```

提交并推送：

```powershell
git commit -m "document Meowa asset workflow"
git push
```

创建草稿 PR：

```powershell
gh pr create --draft --fill
```

已有 PR 时，推送同一分支即可自动更新。PR 描述应说明：

- 生成了哪些资产；
- 为什么选择这些模板；
- 如何接入游戏；
- 运行了哪些测试；
- 是否包含原始生成目录；
- 是否仍有未提交的用户改动。

## 15. 本项目发布前检查清单

- [ ] `MEOWART_API_KEY` 未进入仓库；
- [ ] 最终 PNG 名称与实际武器一致；
- [ ] Godot 已导入新资源；
- [ ] 武器覆盖层与人物双手对齐；
- [ ] 枪口火焰、弹道和后坐位置一致；
- [ ] 换弹与近战动画可见；
- [ ] HUD、商店与装备选择使用正确图标；
- [ ] Godot 无头测试通过；
- [ ] `git diff --check` 通过；
- [ ] 仅暂存本次文档和正式资产；
- [ ] 原始 `art/meowa/` 未意外进入提交；
- [ ] GitHub PR 已更新。
