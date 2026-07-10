# 隐私与安全说明

## 采集与保存

Codex Companion 会从本机已登录的 Codex CLI 只读读取以下字段：

- 账号 Profile 的本地别名；
- `usedPercent`、`windowDurationMins`、`resetsAt`；
- Codex 返回的套餐类型和限额状态；
- 查询时间。

这些数据保存在 `~/Library/Application Support/CodexCompanion/` 的 `config.json` 与 `state.json`。

## 明确不做

- 不读取或保存密码、Cookie、Access Token、刷新令牌、聊天内容、项目代码或终端历史；
- 不上传遥测、统计、崩溃报告或配置到任何服务器；
- 不直接调用 OpenAI Web 后端；
- 不复制、修改、删除或重登录 `CODEX_HOME`；
- 不购买 Credits、不消耗额度、不触发额度重置。

## 本地调用

应用为每个已启用 Profile 启动本机 Codex CLI，并只调用：

```text
initialize
account/rateLimits/read
```

进程参数包含 `-s read-only -a untrusted app-server`。认证和网络请求仍由用户原有的 Codex CLI 完成；本应用不接触其认证文件内容。

## 错误处理

应用不保存错误信息。菜单栏临时显示的错误文本会隐藏 `Authorization: Bearer`、`token=` 和 `cookie=` 形式的疑似凭证，并限制长度。

## 删除数据

退出应用后删除以下目录即可清除全部本地配置与快照：

```bash
rm -rf ~/Library/Application\ Support/CodexCompanion
```

删除 `~/Applications/Codex Companion.app` 可卸载应用；它不会影响任何 Codex Profile。
