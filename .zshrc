# ==========================================
# 1. 开机问候 (Fastfetch 搭配高精度字符画)
# ==========================================
fastfetch

# ==========================================
# 2. 基础设置与历史记录
# ==========================================
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY

# ==========================================
# 3. 补全系统准备与启动 (极其重要的顺序)
# ==========================================
# 将额外的补全包源目录加入 fpath
fpath=(~/.zsh/plugins/zsh-completions/src $fpath)

# 初始化补全引擎
autoload -Uz compinit
compinit

# 开启原生菜单选择UI (作为 fzf-tab 的底层兜底)
zstyle ':completion:*' menu select

# ==========================================
# 4. 加载核心功能插件 (必须在 compinit 之后)
# ==========================================
source ~/.zsh/plugins/fzf-tab/fzf-tab.zsh
source ~/.zsh/plugins/z/z.sh
source ~/.zsh/plugins/zsh-autopair/autopair.zsh
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# ==========================================
# 5. 语法高亮 (根据官方文档，必须放在 substring-search 之前)
# ==========================================
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ==========================================
# 6. 历史子串搜索插件与快捷键绑定
# ==========================================
source ~/.zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# 绑定 向上方向键 搜索更老的历史记录
bindkey '^[[A' history-substring-search-up
# 绑定 向下方向键 搜索更新的历史记录
bindkey '^[[B' history-substring-search-down

# 官方文档推荐的配置变量：确保搜索结果不重复 (强烈建议开启)
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

# ==========================================
# Archirithm Custom Prompt (C++ Powered)
# ==========================================
# 允许 PROMPT 变量内执行命令和颜色转义
setopt PROMPT_SUBST
zmodload zsh/datetime

# 1. 记录命令开始时间
function preexec() {
    typeset -g cmd_start_time=$EPOCHREALTIME
}

# 2. 计算耗时与保存状态码 (彻底剥离静态 PROMPT 赋值)
# 2. 渲染完整提示符与计算耗时
function precmd() {
    # 捕获状态码，并声明为全局变量
    typeset -g PROMPT_EXIT_CODE=$?
    typeset -g PROMPT_CMD_DURATION=""
    
    if [[ -n $cmd_start_time ]]; then
        local cmd_end_time=$EPOCHREALTIME
        local elapsed=$(( cmd_end_time - cmd_start_time ))
        local ms=$(( elapsed * 1000 ))
        PROMPT_CMD_DURATION="${ms%.*}ms" 
        if (( ms > 1000 )); then
            local sec=$(( ms / 1000.0 ))
            printf -v PROMPT_CMD_DURATION "%.1fs" $sec
        fi
        unset cmd_start_time
    fi

    # 【核心修复】：必须在 precmd 里重新把 PROMPT 恢复为 C++ 引擎的动态求值！
    # 这样才能把 zle-line-finish 覆盖掉的历史记录样式给顶掉，召唤回药丸。
    # (注意：一定要用单引号，这样缩放窗口时依然能触发重算)
    PROMPT='$(~/.local/bin/prompt $PROMPT_EXIT_CODE "$PROMPT_CMD_DURATION" $COLUMNS)'
    RPROMPT=""
}

# 4. 监听窗口缩放信号 (SIGWINCH) - 专治 Niri 平铺窗口缩放 Bug
TRAPWINCH() {
    # 强制 Zsh 立即重绘当前提示符，触发 C++ 重新计算宽度对齐
    if [[ -o zle ]]; then
        zle reset-prompt
    fi
}

# 5. 瞬态坍缩魔法：当你按下回车键的一瞬间
function zle-line-finish() {
    # 历史记录左侧：Catppuccin Mocha 绿色，搭配锐利修长的  箭头
    PROMPT="%F{#A6E3A1}%f "
    
    # 历史记录右侧：Catppuccin Mocha 黄色，纯净时间戳
    RPROMPT="%F{#F9E2AF} %D{%H:%M:%S}%f"
    
    zle reset-prompt
}
zle -N zle-line-finish

# ==========================================
# Eza: 现代化的 ls 替代品
# ==========================================
# 基础替换：带图标、优先显示目录、跨平台着色
alias ls='eza --icons=always --color=always --group-directories-first'

# ll: 详细列表模式 (显示权限、大小、修改时间、Git状态)
alias ll='eza -alF --icons=always --color=always --group-directories-first --git'

# la: 显示所有文件 (包括隐藏文件)
alias la='eza -a --icons=always --color=always --group-directories-first'

# lt: 树状图模式 (同款 end_4 视觉效果)
# 默认展示 2 层深度，你可以随时用 lt -L 1 覆盖它
alias lt='eza --tree --level=2 --icons=always --color=always --group-directories-first'

# lsi: 像截图里一样，只显示带图标的干净网格阵列
alias lsi='eza --icons=always --grid -a'
