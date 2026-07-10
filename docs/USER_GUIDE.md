# 使用手册

## 刷新当前账号

1. 在屏幕右上角菜单栏点击 `◈ xx%`。
2. 在浮层底部点击 **↻ 刷新额度**。
3. 应用会重新调用本机 Codex CLI；数秒后 5 小时、周额度和重置时间更新。

每次打开浮层也会自动触发一次刷新。

## 添加第二个账号

### 1. 建立独立 Codex Profile

在终端运行以下命令，并按页面提示登录第二个 ChatGPT 账号：

```bash
mkdir -p ~/.codex-account-b
CODEX_HOME=~/.codex-account-b codex
```

完成登录后退出 Codex。这个目录只由 Codex CLI 管理；Codex Companion 不会读取或复制其中的认证内容。

### 2. 在应用中登记 Profile

1. 点击状态栏的 `◈ xx%`。
2. 点击 **⚙ 账号设置**。
3. 将 `accounts` 改为以下形式（保留你的当前账号，加入第二项）：

```json
{
  "accounts": [
    {
      "id": "account-a",
      "displayName": "账号 A",
      "isEnabled": true
    },
    {
      "id": "account-b",
      "displayName": "账号 B",
      "codexHome": "~/.codex-account-b",
      "isEnabled": true
    }
  ],
  "refreshIntervalSeconds": 300,
  "schemaVersion": 1,
  "staleAfterSeconds": 900
}
```

4. 保存文件，回到状态栏浮层点击 **↻ 刷新额度**。

应用会依次读取两个 Profile，并在推荐算法中优先显示当前最适合使用的账号。浮层保持紧凑，因此默认展示推荐账号；状态栏数字也对应推荐账号的短周期可用额度。

## 常见问题

### 点击刷新后没有数据

- 先在终端执行 `codex --version`，确认 Codex CLI 可运行。
- 对第二账号确认 `~/.codex-account-b/auth.json` 已由登录流程生成；不要把该文件内容发给任何人。
- 点击刷新后稍等数秒；读取失败时浮层会显示脱敏的同步提示。
