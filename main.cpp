#include "utils.h"
#include <iostream>
#include <string>

RenderedPill get_lang_env();
RenderedPill get_directory_pill();
RenderedPill get_git_pill();

int main(int argc, char *argv[]) {
  int exit_code = (argc > 1) ? std::stoi(argv[1]) : 0;
  std::string duration = (argc > 2) ? argv[2] : "";
  int term_width = (argc > 3) ? std::stoi(argv[3]) : 80;

  std::string time_color = (exit_code == 0) ? C_YELLOW : C_RED;

  // 回调：节点符号 󰜥 前后各留 1 个空格，防止药丸粘连
  std::string wave_link = "%F{" + C_GRAY + "} 󰜥 %f";
  int wave_width = 3;

  // ====== 构建第一行左侧 ======
  // 回调：╭─ 后加空格
  std::string left_prompt = "\n%F{" + C_GRAY + "}╭─ %f";
  int left_width = 3;

  if (!duration.empty() && duration != "0ms") {
    // 回调：󰔚 之后，结束之前加空格
    left_prompt += "%F{" + C_YELLOW + "}%K{" + C_YELLOW + "}%F{" + C_BASE +
                   "}󰔚 " + duration + " %k%F{" + C_YELLOW + "}%f" +
                   wave_link;
    // (1) + 󰔚(1) + 空(1) + duration长 + 空(1) + (1) = 5 + duration
    left_width += 5 + duration.length() + wave_width;
  }

  RenderedPill dir_pill = get_directory_pill();
  left_prompt += dir_pill.zsh_code;
  left_width += dir_pill.visible_width;

  RenderedPill git_pill = get_git_pill();
  if (git_pill.visible_width > 0) {
    left_prompt += wave_link + git_pill.zsh_code;
    left_width += wave_width + git_pill.visible_width;
  }

  // ====== 构建第一行右侧 ======
  std::string right_prompt = "";
  int right_width = 0;

  RenderedPill lang_pill = get_lang_env();
  if (lang_pill.visible_width > 0) {
    right_prompt += lang_pill.zsh_code + wave_link;
    right_width += lang_pill.visible_width + wave_width;
  }

  // 回调：增加前置空格和  后置空格
  std::string time_zsh = "%F{" + time_color + "}%K{" + time_color + "}%F{" +
                         C_BASE + "}  " + "%D{%H:%M:%S} %k%F{" + time_color +
                         "}%f";

  // (1) + 前置空(1) + (1) + 标后空(1) + 时间(8) + 尾部空(1) + (1) =
  // 14
  int time_width = 14;

  right_prompt += time_zsh;
  right_width += time_width;

  // ====== 核心对齐魔法 ======
  int spaces_needed = term_width - left_width - right_width;
  if (spaces_needed < 0)
    spaces_needed = 0;
  std::string fill_spaces(spaces_needed, ' ');

  // ====== 第二行光标输入层 ======
  // ╰─ 后面和  后面都留 1 个标准空格
  std::string second_line =
      "\n%F{" + C_GRAY + "}╰─ %f%F{" + C_GREEN + "} %f";

  std::cout << left_prompt << fill_spaces << right_prompt << second_line;

  return 0;
}
