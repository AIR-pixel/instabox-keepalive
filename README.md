# instabox-keepalive

InstaBox 免费档沙箱的保活控制器。

## 为什么需要它

免费档的两条硬限制实测无法修改：

| 限制 | 值 | 改不了的原因 |
| --- | --- | --- |
| 空闲暂停 | 30 分钟（`autoSuspendAfterSeconds: 1800`） | `spec_not_allowed: Free users are not able to change idle time` |
| 单次运行上限 | 120 分钟（`maxRunMinutes: 120`） | `permission_denied: free machines have a managed maxRunMinutes` |

所以「保活」不是单纯 ping 一下就行：**每 120 分钟沙箱会被强制停机**，必须有人把它重新拉起来。
这个工作流每 10 分钟做一轮：

1. 用 InstaBox API 查沙箱状态；
2. 只要不是 `running` 就 `resume`（暂停态）或 `start`（停机态）；
3. 轮询 `/healthz` 直到返回 200（冷启动一般 30–60 秒，最多等约 7 分钟）。

## 需要的仓库 secrets

| 名称 | 说明 |
| --- | --- |
| `INSTABOX_API_KEY` | `ibk_...`，scope 需要 `machines:read` + `machines:write` |
| `INSTABOX_BOX` | 沙箱 ID（`m_...`）或名字 |
| `INSTABOX_URL` | 站点公网地址，不带末尾斜杠 |

## 仓库必须是 public

private 仓库的 Actions 免费额度是 2000 分钟/月。10 分钟一轮 ≈ 4300 轮/月，
每轮最少计 1 分钟，必然超额；public 仓库不限分钟数。

## 每月一次提交

GitHub 会在仓库 60 天无提交后停用 `schedule`。工作流里带了一个每月 1 号的
heartbeat 提交，用来把 schedule 一直续上去。

## 沙箱里配套的两个 systemd 单元

机器被重新拉起后要能自己恢复服务，两个都必须是 `enabled`：

- `instabox-site.service` —— 站点本体（`/data/home/site/server.js`）
- `dsh-web.service` —— 无头 DSH（`dsh web --port 3080`，WorkBuddy shim 宿主）

注意：unit 名不能以 `instabox-` 开头去自定义，平台把这批名字管着，会直接判成 masked。

`dsh-web-setup.sh` 就是安装 `dsh-web.service` 的脚本（在沙箱里 `bash dsh-web-setup.sh` 即可复现）。
它把 DSH 的 stdout 落到 `/data/home/site/dsh-web.log`，站点侧 `/dsh/` 会从这份日志里
读当前访问 token 做自动登录 —— 所以 DSH 每次重启后 token 变了也不用管，
直接打开 `https://<域名>/dsh/?k=<页面口令>` 就能进。
