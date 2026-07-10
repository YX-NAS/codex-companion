# 开源项目调研与方案审核

调研日期：2026-07-10。

## 参考项目

| 项目 | 可借鉴内容 | 本项目的取舍 |
|---|---|---|
| [openai/codex](https://github.com/openai/codex) | 本机 `app-server` 的 JSON-RPC 协议与额度字段 | 直接使用其本地只读接口，不解析会话日志 |
| [steipete/CodexBar](https://github.com/steipete/CodexBar) | macOS 菜单栏、账号 Profile、短周期/周窗口、打包与测试实践 | 不复制代码；保持单一 Codex Provider、无 Cookie 导入、无复杂设置 |
| [openai/codex #20310](https://github.com/openai/codex/issues/20310) | 使用者明确需要 5 小时、周额度和重置时间 | 将这三项作为菜单栏一等信息 |
| [openai/codex app-server README](https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md) | `account/rateLimits/read` 返回已用比例、窗口分钟与重置时间 | 将 RPC 返回作为额度真相来源 |

## 审核结论

### 原方案的问题

浏览器扩展读取 Usage Dashboard 的方案虽然不接触 CLI 认证，但有四个问题：

1. 页面结构和文案容易变化；
2. 用户必须为每个账号保持页面打开；
3. 多 Profile 的扩展安装与 Native Messaging 增加了安装复杂度；
4. 已有 Codex CLI 本身就能返回结构化窗口数据。

### 优化后的方案

使用本机 Codex CLI 的 app-server，按 Profile 设置 `CODEX_HOME` 后依次执行：

```text
initialize → account/rateLimits/read
```

实际验证中，当前本机 Plus Profile 返回：

- `primary.windowDurationMins = 300`；
- `secondary.windowDurationMins = 10080`；
- 两个窗口均含 `usedPercent` 与 `resetsAt`。

因此应用按窗口分钟数显示“5小时额度”和“周额度”，而非依赖文本抓取或用 Token 推断。

### 安全审核

- 本项目不读取 `auth.json` 内容；仅由 Codex CLI 在自己的进程中处理认证。
- 不复制浏览器 Cookie，避免 Keychain、浏览器数据库和 Full Disk Access 风险。
- 账号 Profile 由用户显式指定；不尝试从会话日志推断账号归属。
- 对可能出现在 CLI 错误中的凭证形态做展示层脱敏。

### 未采纳功能

- 浏览器页面抓取：仅作为 app-server 不可用时的后续备选，不在 v0.1 引入。
- 从 JSONL 日志推算剩余额度：不可靠，且多账号下无法安全归属。
- Credits 自动购买/重置、自动切号：不属于只读监控工具。
