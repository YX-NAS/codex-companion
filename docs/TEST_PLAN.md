# 测试计划

## 自动测试

执行：

```bash
swift run CodexCompanionTestRunner
```

覆盖项：

| 模块 | 验证点 |
|---|---|
| App-server 解码 | 读取 `primary`、`secondary`、百分比、窗口分钟和重置时间 |
| 建议算法 | 忽略陈旧快照、避开短周期不足 10% 的账号、额度接近时避免频繁切换 |
| 隐私 | 错误文本中的疑似 Bearer Token、token、cookie 被隐藏 |

## 本机验收

1. 运行 `./scripts/install_local.sh`。
2. 确认菜单栏出现 `C <百分比>`；点击查看短周期与长周期，以及“多少小时多少分后重置”。
3. 点击“立即刷新”，确认同步时间更新。
4. 配置两个已登录 Profile，确认两个账号分别显示且推荐结果与 70/30 规则一致。
5. 临时将 `staleAfterSeconds` 设为 `1`，重启后等待 2 秒，确认标题显示 `C ?` 且不继续推荐。
6. 用不存在的 `codexHome` 配置一个账号，确认应用保留其他账号数据并显示读取失败，不崩溃。
7. 检查 `~/Library/Application Support/CodexCompanion/`，确认没有 Cookie、Bearer、聊天内容或认证文件副本。

## 发布前检查

```bash
swift run CodexCompanionTestRunner
swift build -c release
./scripts/package_app.sh
codesign --verify --deep --strict "dist/CodexCompanion.app"
plutil -lint "dist/CodexCompanion.app/Contents/Info.plist"
```
