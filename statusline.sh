#!/bin/bash
set -euo pipefail
INPUT_JSON=$(cat)

# ─── ANSI & 24-bit TrueColor Palette ─────────────────────────────────────────
R="\033[0m"         # Reset
B="\033[1m"         # Bold
D="\033[2m"         # Dim
I="\033[3m"         # Italic

# User Alert Threshold Colors (Only applied to progress bars & % numbers)
# 80%+      : #E03C31
# 50% - 79% : #FFD166
# 0% - 49%  : #3FE0C5
C_OK="\033[38;2;63;224;197m"      # #3FE0C5 (0 - 49%)
C_WARN="\033[38;2;255;209;102m"   # #FFD166 (50 - 79%)
C_CRIT="\033[38;2;224;60;49m"     # #E03C31 (80%+)

# ── Gemini Blue Tone Palette (All text, icons, labels, reset times) ──
BLUE_MAIN="\033[38;2;66;165;245m"    # #42A5F5 (Header)
BLUE_LIGHT="\033[38;2;144;202;249m"  # #90CAF9 (Labels & Icons)
BLUE_MUTED="\033[38;2;100;155;200m"  # (Reset time)
BLUE_SEP="\033[38;2;50;110;170m"     # (Divider)

# ── Argon Purple Tone Palette (All text, icons, labels, reset times) ──
ARGON_MAIN="\033[38;2;186;104;200m"   # #BA68C8 (Header)
ARGON_LIGHT="\033[38;2;206;147;216m" # #CE93D8 (Labels & Icons)
ARGON_MUTED="\033[38;2;160;120;180m" # (Reset time)
ARGON_SEP="\033[38;2;120;70;140m"    # (Divider)

# ── Others Orange Tone Palette (All text, icons, labels, reset times) ──
ORANGE_MAIN="\033[38;2;255;152;0m"    # #FF9800 (Header)
ORANGE_LIGHT="\033[38;2;255;183;77m"  # #FFB74D (Labels & Icons)
ORANGE_MUTED="\033[38;2;200;140;90m"  # (Reset time)
ORANGE_SEP="\033[38;2;160;95;45m"     # (Divider)

# ── General Palette ──
FG_GRAY="\033[38;2;120;120;120m"
FG_TRACK="\033[38;2;70;70;70m"
FG_CYAN="\033[38;2;100;200;255m"
FG_MAGENTA="\033[38;2;220;130;255m"
FG_BLUE="\033[38;2;100;160;255m"
FG_YELLOW="\033[38;2;255;209;102m"
FG_RED="\033[38;2;224;60;49m"
FG_GREEN="\033[38;2;63;224;197m"
NUM_COLOR="\033[1;37m"

DOT="${FG_GRAY} | ${R}"

# Helper for selecting color by percentage
get_alert_color() {
  local pct=${1:-0}
  if [ "$pct" -ge 80 ]; then
    echo -ne "$C_CRIT"
  elif [ "$pct" -ge 50 ]; then
    echo -ne "$C_WARN"
  else
    echo -ne "$C_OK"
  fi
}

format_seconds() {
  local sec=$1
  if [ -z "$sec" ] || [ "$sec" -le 0 ] 2>/dev/null; then
    echo ""
    return
  fi
  local d=$(( sec / 86400 ))
  local h=$(( (sec % 86400) / 3600 ))
  local m=$(( (sec % 3600) / 60 ))
  
  if [ "$d" -gt 0 ]; then
    echo "${d}d${h}h${m}m"
  elif [ "$h" -gt 0 ]; then
    echo "${h}h${m}m"
  elif [ "$m" -gt 0 ]; then
    echo "${m}m"
  else
    echo "<1m"
  fi
}

# ─── Block Progress Bar Helper (███▒░░░) ─────────────────────────────────────
render_block_bar() {
  local used_pct=$1
  local len=${2:-12}
  local bar_color=$3
  local track_color=${4:-$FG_TRACK}

  if [ -z "$used_pct" ] || [ "$used_pct" -lt 0 ] 2>/dev/null; then
    echo -ne "${FG_GRAY}────── N/A${R}"
    return
  fi

  local pct_int=${used_pct%.*}
  pct_int=${pct_int:-0}
  [ "$pct_int" -lt 0 ] && pct_int=0
  [ "$pct_int" -gt 100 ] && pct_int=100

  local filled=$(( pct_int * len / 100 ))
  local remainder=$(( (pct_int * len) % 100 ))

  local bar=""
  for ((i = 0; i < len; i++)); do
    if [ "$i" -lt "$filled" ]; then
      bar="${bar}${bar_color}█${R}"
    elif [ "$i" -eq "$filled" ]; then
      if   [ "$remainder" -ge 75 ]; then bar="${bar}${bar_color}▓${R}${track_color}"
      elif [ "$remainder" -ge 50 ]; then bar="${bar}${bar_color}▒${R}${track_color}"
      elif [ "$remainder" -ge 25 ]; then bar="${bar}${bar_color}░${R}${track_color}"
      else                               bar="${bar}${track_color}░${R}"
      fi
    else
      bar="${bar}${track_color}░${R}"
    fi
  done

  echo -ne "$bar"
}

render_quota_item() {
  local label=$1       # "5h" or "7d"
  local icon=$2        # "" or ""
  local used_pct=$3
  local reset_sec=$4
  local len=${5:-8}
  local label_color=$6
  local muted_color=$7

  if [ -z "$used_pct" ] || [ "$used_pct" -lt 0 ] 2>/dev/null; then
    echo -ne "${label_color}${icon} ${label}${R} ${FG_GRAY}────── N/A${R}"
    return
  fi

  local color
  color=$(get_alert_color "$used_pct")
  local bar_str
  bar_str=$(render_block_bar "$used_pct" "$len" "$color" "$FG_TRACK")

  local r_str=""
  local left_fmt
  left_fmt=$(format_seconds "$reset_sec")
  if [ -n "$left_fmt" ]; then
    r_str=" ${muted_color}${left_fmt}${R}"
  fi

  echo -ne "${label_color}${icon} ${label}${R} ${bar_str} ${color}${B}${used_pct}%${R}${r_str}"
}

# ─── Parse JSON from stdin (Single jq pass for performance) ──────────────────
{
  read -r STATE
  read -r USED_PCT
  read -r VCS_BRANCH
  read -r VCS_DIRTY
  read -r VCS_TYPE
  read -r VCS_CLIENT
  read -r ARTIFACTS
  read -r SUBAGENTS
  read -r BG_TASKS
  read -r MODEL_ID
  read -r MODEL_NAME
  read -r COLS
  read -r CWD
  read -r CONV_ID
  read -r PRODUCT
  read -r INPUT_TOKENS
  read -r OUTPUT_TOKENS
  read -r CTX_LIMIT
  read -r CTX_USED
  read -r REM_PCT
  read -r G5_PCT
  read -r G5_SEC
  read -r GW_PCT
  read -r GW_SEC
  read -r A5_PCT
  read -r A5_SEC
  read -r AW_PCT
  read -r AW_SEC
  read -r O5_PCT
  read -r O5_SEC
  read -r OW_PCT
  read -r OW_SEC
} <<< "$(
  echo "$INPUT_JSON" | jq -r '
    def parse_sec(obj):
      (obj.reset_in_seconds // (if obj.resets_at != null then (obj.resets_at - (now | floor)) elif obj.reset_time != null then (try ((obj.reset_time | fromdateiso8601) - (now | floor)) catch 0) else 0 end) // 0);

    def g5: (.quota["gemini-5h"] // .quota["gemini-rolling"] // (if ((.model.id // "") | contains("gemini")) or ((.model.display_name // "") | contains("Gemini")) then .quota else null end) // .rate_limits.five_hour // {});
    def g5_pct: (if g5.remaining_fraction != null then ((1.0 - g5.remaining_fraction) * 100 | round) elif g5.used_percentage != null then (g5.used_percentage | round) else -1 end);
    def g5_sec: parse_sec(g5);

    def gw: (.quota["gemini-weekly"] // .quota["gemini-7d"] // (if ((.model.id // "") | contains("gemini")) or ((.model.display_name // "") | contains("Gemini")) then .quota_weekly else null end) // .rate_limits.seven_day // {});
    def gw_pct: (if gw.remaining_fraction != null then ((1.0 - gw.remaining_fraction) * 100 | round) elif gw.used_percentage != null then (gw.used_percentage | round) else -1 end);
    def gw_sec: parse_sec(gw);

    def a5: (.quota["gemini-argon-5h"] // .quota["gemini-argon-wtu-5h"] // .quota["gemini-argon-rolling"] // .quota["argon-5h"] // {});
    def a5_pct: (if a5.remaining_fraction != null then ((1.0 - a5.remaining_fraction) * 100 | round) elif a5.used_percentage != null then (a5.used_percentage | round) else -1 end);
    def a5_sec: parse_sec(a5);

    def aw: (.quota["gemini-argon-wtu-weekly"] // .quota["gemini-argon-weekly"] // .quota["gemini-argon-7d"] // .quota["argon-wtu-weekly"] // .quota["argon-weekly"] // .quota["argon-7d"] // (if ((.model.id // "") | test("(?i)argon")) or ((.model.display_name // "") | test("(?i)argon")) then (.quota_weekly // .quota) else null end) // {});
    def aw_pct: (if aw.remaining_fraction != null then ((1.0 - aw.remaining_fraction) * 100 | round) elif aw.used_percentage != null then (aw.used_percentage | round) else -1 end);
    def aw_sec: parse_sec(aw);

    def o5: (.quota["3p-5h"] // .quota["claude-5h"] // .quota["gpt-5h"] // .quota["3p-rolling"] // (if (((.model.id // "") | contains("gemini")) or ((.model.display_name // "") | contains("Gemini"))) | not then .quota else null end) // {});
    def o5_pct: (if o5.remaining_fraction != null then ((1.0 - o5.remaining_fraction) * 100 | round) elif o5.used_percentage != null then (o5.used_percentage | round) else -1 end);
    def o5_sec: parse_sec(o5);

    def ow: (.quota["3p-weekly"] // .quota["3p-7d"] // .quota["claude-7d"] // .quota["gpt-7d"] // (if (((.model.id // "") | contains("gemini")) or ((.model.display_name // "") | contains("Gemini"))) | not then .quota_weekly else null end) // {});
    def ow_pct: (if ow.remaining_fraction != null then ((1.0 - ow.remaining_fraction) * 100 | round) elif ow.used_percentage != null then (ow.used_percentage | round) else -1 end);
    def ow_sec: parse_sec(ow);

    (.agent_state // "idle"),
    (.context_window.used_percentage // 0),
    (.vcs.branch // ""),
    (.vcs.dirty // false),
    (.vcs.type // ""),
    (.vcs.client // ""),
    (.artifact_count // 0),
    (if .subagents | type == "array" then (.subagents | length) else 0 end),
    (.task_count // 0),
    (.model.id // ""),
    (.model.display_name // ""),
    (.terminal_width // 80),
    (.cwd // ""),
    (.conversation_id // ""),
    (.product // ""),
    (.context_window.total_input_tokens // 0),
    (.context_window.total_output_tokens // 0),
    (.context_window.context_window_size // 0),
    ((.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0)),
    (.context_window.remaining_percentage // 100),
    g5_pct,
    g5_sec,
    gw_pct,
    gw_sec,
    a5_pct,
    a5_sec,
    aw_pct,
    aw_sec,
    o5_pct,
    o5_sec,
    ow_pct,
    ow_sec
  ' 2>/dev/null || printf "idle\n0\n\nfalse\n\n\n0\n0\n0\n\n\n80\n\n\n\n0\n0\n0\n0\n100\n-1\n0\n-1\n0\n-1\n0\n-1\n0\n-1\n0\n-1\n0\n"
)"

# ─── VCS & Git Diff directly from git ────────────────────────────────────────
GIT_DIR="${CWD:-.}"
VCS_BRANCH=$(git -C "$GIT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
DIFF_FMT=""
if [ -n "$VCS_BRANCH" ]; then
  if git -C "$GIT_DIR" status --porcelain 2>/dev/null | grep -q .; then
    VCS_DIRTY="true"
  else
    VCS_DIRTY="false"
  fi

  read -r DIFF_ADD DIFF_DEL <<< "$(git -C "$GIT_DIR" diff HEAD --numstat 2>/dev/null | awk '{add+=$1; del+=$2} END {printf "%d %d", add+0, del+0}')"
  if [ -n "$DIFF_ADD" ] && [ -n "$DIFF_DEL" ]; then
    if [ "$DIFF_ADD" -gt 0 ] || [ "$DIFF_DEL" -gt 0 ]; then
      DIFF_FMT="${FG_GREEN}+${DIFF_ADD}${R} ${FG_RED}-${DIFF_DEL}${R}"
    else
      DIFF_FMT="${FG_GRAY}+0 -0${R}"
    fi
  fi
else
  VCS_DIRTY="false"
fi

# ─── Computed & Formatted Values ─────────────────────────────────────────────
PCT_FMT=$(LC_NUMERIC=C printf "%.1f" "$USED_PCT")
PCT_INT=${USED_PCT%.*}; PCT_INT=${PCT_INT:-0}

human_format() {
  local num=$1
  if [ -z "$num" ] || [ "$num" -eq 0 ] 2>/dev/null; then
    echo "0"
    return
  fi
  if [ "$num" -ge 1000000 ] 2>/dev/null; then
    echo "$((num / 1000000)).$(((num % 1000000) / 100000))M"
  elif [ "$num" -ge 1000 ] 2>/dev/null; then
    echo "$((num / 1000)).$(((num % 1000) / 100))K"
  else
    echo "$num"
  fi
}

CTX_LIMIT_FMT=$(human_format "$CTX_LIMIT")
CTX_USED_FMT=$(human_format "$CTX_USED")

shorten_path() {
  local path=$1
  if [ -z "$path" ]; then
    echo ""
    return
  fi
  path="${path/#$HOME/\~}"
  if [ "${#path}" -gt 25 ]; then
    echo "...$(basename "$path")"
  else
    echo "$path"
  fi
}
CWD_SHORT=$(shorten_path "$CWD")

# ─── Row 1: Session Status, Directory, Git & Diff, Artifacts ─────────────────
case "$STATE" in
  idle)     S="${C_OK}${B}  READY${R}" ;;
  thinking) S="${C_WARN}${B}  THINKING${R}" ;;
  working)  S="${FG_CYAN}${B}  WORKING${R}" ;;
  tool_use) S="${FG_MAGENTA}${B}  TOOL${R}" ;;
  *)        S="${NUM_COLOR}${B}  $(echo "$STATE" | tr '[:lower:]' '[:upper:]')${R}" ;;
esac

DIR_FMT=""
if [ -n "$CWD_SHORT" ]; then
  DIR_FMT="${FG_CYAN} ${R}${CWD_SHORT}${R}"
fi

V_FMT=""
if [ -n "$VCS_BRANCH" ]; then
  if [ "$VCS_DIRTY" = "true" ]; then
    V_FMT="${FG_BLUE} ${VCS_BRANCH}${FG_YELLOW}*${R}"
  else
    V_FMT="${FG_BLUE} ${VCS_BRANCH}${R}"
  fi
fi

ART_FMT="${FG_BLUE} ${NUM_COLOR}${ARTIFACTS}${R}"
SUB_FMT="${FG_CYAN} ${NUM_COLOR}${SUBAGENTS}${R}"
BG_FMT="${FG_MAGENTA} ${NUM_COLOR}${BG_TASKS}${R}"

LINE1="${S}"
[ -n "$DIR_FMT" ] && LINE1="${LINE1}${DOT}${DIR_FMT}"
[ -n "$V_FMT" ]   && LINE1="${LINE1}${DOT}${V_FMT}"
[ -n "$DIFF_FMT" ] && LINE1="${LINE1}${DOT}${DIFF_FMT}"
LINE1="${LINE1}${DOT}${ART_FMT}"

# ─── Row 2: Model Name, Context Bar, Subagents, Background Tasks ─────────────
MODEL_TITLE="${MODEL_NAME:-$MODEL_ID}"
M_FMT="${FG_MAGENTA}󰚩  ${MODEL_TITLE:-Gemini}${R}"

CTX_COLOR=$(get_alert_color "$PCT_INT")
CTX_BAR_STR=$(render_block_bar "$PCT_INT" 15 "$CTX_COLOR" "$FG_TRACK")
CTX_FMT="${FG_YELLOW} ${R}${CTX_BAR_STR} ${CTX_COLOR}${B}${PCT_FMT}%${R} ${FG_GRAY}(${CTX_USED_FMT}/${CTX_LIMIT_FMT})${R}"

LINE2=" ${M_FMT}${DOT}${CTX_FMT}${DOT}${SUB_FMT}${DOT}${BG_FMT}"

# ─── Row 3: Gemini & Argon Quota - Unified Blue & Purple Tone ────────────────
G5_ITEM=$(render_quota_item "5h" "" "$G5_PCT" "$G5_SEC" 8 "$BLUE_LIGHT" "$BLUE_MUTED")
GW_ITEM=$(render_quota_item "7d" "" "$GW_PCT" "$GW_SEC" 8 "$BLUE_LIGHT" "$BLUE_MUTED")
DOT_BLUE="${BLUE_SEP} | ${R}"
LINE3=" ${BLUE_MAIN}${B}Gemini${R}  ${G5_ITEM}${DOT_BLUE}${GW_ITEM}"

if [ "$AW_PCT" -ge 0 ] 2>/dev/null; then
  ARGON_ITEM=$(render_quota_item "Argon" "󰚩" "$AW_PCT" "$AW_SEC" 8 "$ARGON_LIGHT" "$ARGON_MUTED")
  LINE3="${LINE3}${DOT_BLUE}${ARGON_ITEM}"
fi

# ─── Row 4: Others Quota (5h, 7d) - Unified Orange Tone ──────────────────────
O5_ITEM=$(render_quota_item "5h" "" "$O5_PCT" "$O5_SEC" 8 "$ORANGE_LIGHT" "$ORANGE_MUTED")
OW_ITEM=$(render_quota_item "7d" "" "$OW_PCT" "$OW_SEC" 8 "$ORANGE_LIGHT" "$ORANGE_MUTED")
DOT_ORANGE="${ORANGE_SEP} | ${R}"
LINE4=" ${ORANGE_MAIN}${B}Others${R}  ${O5_ITEM}${DOT_ORANGE}${OW_ITEM}"

# ─── 4-Row Tree Output Assembly ──────────────────────────────────────────────
echo -e "${FG_GRAY}╭─${R}${LINE1}"
echo -e "${FG_GRAY}├─${R}${LINE2}"
echo -e "${FG_GRAY}├─${R}${LINE3}"
echo -e "${FG_GRAY}╰─${R}${LINE4}"
