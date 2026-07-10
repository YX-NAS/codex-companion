# 发布说明

## v0.1.0

- macOS 菜单栏显示 Codex 短周期与长周期额度；
- 显示精确重置倒计时；
- 支持多个用户配置的 `CODEX_HOME` Profile；
- 以 70% 短周期 + 30% 长周期给出账号建议；
- 快照持久化与默认 15 分钟陈旧保护；
- 本机临时签名 `.app` 打包与安装脚本；
- 无 Cookie、令牌、聊天内容和远程遥测采集。

## v0.1.1

- 双击应用时默认显示“Codex 额度总览”状态面板；
- 增加菜单栏“打开状态面板”入口；
- 本机安装脚本更新应用前会先退出旧进程，避免旧应用残留。

## v0.1.2

- 改为常规 macOS 应用：Dock 中显示图标，窗口不会再作为纯菜单栏应用被隐藏；
- 启动后直接在当前桌面显示状态面板。

## 安装包

从 GitHub Release 下载 `CodexCompanion-v0.1.0-macos-arm64.zip`，解压后将 `Codex Companion.app` 拖入 Applications。由于 v0.1.0 使用临时签名，macOS 若提示来源不明，请在系统设置中明确允许本应用运行。

## 升级

覆盖安装应用即可；配置和快照位于 `~/Library/Application Support/CodexCompanion/`，不会被覆盖。
