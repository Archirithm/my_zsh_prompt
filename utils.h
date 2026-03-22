#pragma once
#include <string>

// Catppuccin Mocha 官方配色板
const std::string C_BASE = "#1E1E2E";   // 药丸内文字色
const std::string C_GREEN = "#A6E3A1";  // 语言胶囊, 播放键
const std::string C_BLUE = "#89B4FA";   // 路径胶囊
const std::string C_CYAN = "#94E2D5";   // Git 胶囊 (复刻 end_4)
const std::string C_PURPLE = "#CBA6F7"; // 备用色
const std::string C_YELLOW = "#F9E2AF"; // 时间戳(成功), 耗时
const std::string C_RED = "#F38BA8";    // 时间戳(错误)
const std::string C_GRAY = "#A6ADC8";   // 连线, 节点符号

struct RenderedPill {
  std::string zsh_code;
  int visible_width;
};

std::string exec_cmd(const char *cmd);
