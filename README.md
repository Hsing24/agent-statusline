# Agent Statusline 🚀

各式 AI Agent CLI（如 **Claude Code**、**Google Antigravity CLI** 等）的終端機狀態列（Statusline）與標題列（Title）設定與美化腳本集合。

本專案採分支架構管理不同 AI 工具的配置，主分支（`main`）作為整體專案概覽，各工具的具體腳本與使用指引請切換至對應分支。

---

## 🌿 分支導覽 (Branches)

| 分支名稱 | 適用工具 | 包含內容 | 說明 |
| :--- | :--- | :--- | :--- |
| [`claude-code`](https://github.com/Hsing24/agent-statusline/tree/claude-code) | Anthropic Claude Code | `statusline.sh`, `install.sh`, `settings-snippet.json`, `tools/` | 支援 Git 狀態、變更行數、Token 消耗統計與進度條，具備一鍵安裝配置腳本。 |
| [`antigravity-cli`](https://github.com/Hsing24/agent-statusline/tree/antigravity-cli) | Google Antigravity CLI (`agy`) | `statusline.sh`, `title.sh` | 4 行彩色樹狀結構，整合即時狀態、Context 使用率、Subagents、背景任務與配額（5h / 7d）進度條，外加終端標題列同步。 |

---

## ⚡ 快速取得方式

### 方式一：複製特定分支

若只需特定工具的腳本，可使用 `git clone --single-branch -b <分支名稱>`：

```bash
# 取得 Claude Code 配置
git clone -b claude-code https://github.com/Hsing24/agent-statusline.git claude-statusline

# 取得 Antigravity CLI 配置
git clone -b antigravity-cli https://github.com/Hsing24/agent-statusline.git antigravity-statusline
```

### 方式二：本地切換分支

克隆整個倉庫後直接切換：

```bash
git clone https://github.com/Hsing24/agent-statusline.git
cd agent-statusline

# 切換至 Claude Code
git switch claude-code

# 切換至 Antigravity CLI
git switch antigravity-cli
```

### 方式三：直接下載單一腳本

也可以透過 GitHub Raw 連結直接下載腳本：

```bash
# 下載 Claude Code statusline
curl -fsSL https://raw.githubusercontent.com/Hsing24/agent-statusline/claude-code/statusline.sh -o ~/.claude/statusline.sh

# 下載 Antigravity CLI statusline & title
mkdir -p ~/.gemini/antigravity-cli
curl -fsSL https://raw.githubusercontent.com/Hsing24/agent-statusline/antigravity-cli/statusline.sh -o ~/.gemini/antigravity-cli/statusline.sh
curl -fsSL https://raw.githubusercontent.com/Hsing24/agent-statusline/antigravity-cli/title.sh -o ~/.gemini/antigravity-cli/title.sh
```

---

## 📌 前置需求

- **Bash 4.0+**
- **jq**：處理 JSON 資料流輸出
- **Nerd Fonts**：建議在終端機（如 iTerm2、Ghostty、WezTerm 等）安裝並使用任一 Nerd Font 字型（例如 JetBrainsMono Nerd Font、FiraCode Nerd Font），以正確渲染狀態圖示。

---

## 📄 License

MIT License
