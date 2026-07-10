# 发布说明

## v0.1.0

- macOS 菜单栏显示 Codex 短周期与长周期额度；
- 显示精确重置倒计时；
- 支持多个用户配置的 `CODEX_HOME` Profile；
- 以 70% 短周期 + 30% 长周期给出账号建议；
- 快照持久化与默认 15 分钟陈旧保护；
- 本机临时签名 `.app` 打包与安装脚本；
- 无 Cookie、令牌、聊天内容和远程遥测采集。

## 安装包

从 GitHub Release 下载 `CodexCompanion-v0.1.0-macos-arm64.zip`，解压后将 `Codex Companion.app` 拖入 Applications。由于 v0.1.0 使用临时签名，macOS 若提示来源不明，请在系统设置中明确允许本应用运行。

## 升级

覆盖安装应用即可；配置和快照位于 `~/Library/Application Support/CodexCompanion/`，不会被覆盖。
