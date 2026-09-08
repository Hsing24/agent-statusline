# Antigravity CLI Statusline & Title

Google Antigravity CLI (`agy`) 的自訂狀態列（Statusline）與終端標題列（Title）腳本。

## 📦 檔案清單

- **`statusline.sh`**: 4 行美化樹狀狀態列腳本，支援 ANSI 24-bit TrueColor，整合模型名稱、Token Context 使用率、Git 分支與 Dirty 狀態、Artifacts、Subagents、背景任務以及配額條（5h / 7d）。
- **`title.sh`**: 終端視窗 / 分頁標題即時狀態同步腳本，支援依據 Agent 當前運作狀態（`idle`, `thinking`, `working`, `tool_use`）切換圖示與工作目錄顯示。

## 🎨 狀態列外觀預覽

```text
╭─  READY |  my-project |  main* | +2 ~1 |  3
├─ 󰚩  Gemini 3.8 Flash |  █████░░░░░░░░░░ 35.0% (350.0k/1.0M) |  0 |  1
├─ Gemini  5h  ███░░░░░ 30% 2h15m | 7d  █░░░░░░░ 12% 4d10h
╰─ Others  5h  ░░░░░░░░ 0% | 7d  ░░░░░░░░ 0%
```

### 功能特色
- **第一行 (狀態與環境)**：即時狀態（READY / THINKING / WORKING / TOOL）、工作目錄縮寫、Git 分支與未提交狀態（Dirty）、變更行數統計、已產出 Artifacts 數量。
- **第二行 (模型與負載)**：當前使用模型、Context 視窗使用率與長條圖（支援三段顏色預警：綠 / 黃 / 紅）、Subagents 數量、背景任務數量。
- **第三行與第四行 (配額使用量)**：Gemini 及 其他模型的 5 小時（5h）與 7 天（7d）配額使用比例、進度條與重設倒數計時。

---

## 🚀 安裝與配置

### 1. 放置腳本

將腳本放置至 Antigravity CLI 配置目錄（通常為 `~/.gemini/antigravity-cli/`）：

```bash
mkdir -p ~/.gemini/antigravity-cli
cp statusline.sh ~/.gemini/antigravity-cli/statusline.sh
cp title.sh ~/.gemini/antigravity-cli/title.sh
chmod +x ~/.gemini/antigravity-cli/statusline.sh ~/.gemini/antigravity-cli/title.sh
```

### 2. 在 Antigravity CLI 設定中啟用

在 Antigravity 設定檔（如 `~/.gemini/antigravity-cli/settings.json` 或全域設定）中加入：

```json
{
  "statusline": {
    "command": "~/.gemini/antigravity-cli/statusline.sh"
  },
  "title": {
    "command": "~/.gemini/antigravity-cli/title.sh"
  }
}
```

> **注意**：需要系統安裝有 `jq` 以及支援 Nerd Fonts 的終端機字型以正常顯示圖示。
