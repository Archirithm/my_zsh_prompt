#include "utils.h"
#include <algorithm>
#include <array>
#include <filesystem>
#include <memory>
#include <unordered_set>
#include <vector>

namespace fs = std::filesystem;

struct LangDetect {
  std::string name;
  std::string icon;
  int weight;
  std::vector<std::string> triggers;
  std::vector<std::string> extensions;
};

std::string exec_cmd(const char *cmd) {
  std::array<char, 128> buffer;
  std::string result;
  std::unique_ptr<FILE, int (*)(FILE *)> pipe(popen(cmd, "r"), pclose);
  if (!pipe)
    return "";
  while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
    result += buffer.data();
  }
  return result;
}

RenderedPill get_lang_env() {
  std::vector<LangDetect> languages = {
      {"Python", "󰌠", 100, {"requirements.txt", "pyproject.toml"}, {".py"}},
      {"Go", "", 95, {"go.mod"}, {".go"}},
      {"C++",
       "",
       90,
       {"CMakeLists.txt", "Makefile"},
       {".cpp", ".hpp", ".cc", ".cxx"}},
      {"Java", "", 85, {"pom.xml", "build.gradle"}, {".java"}},
      {"C", "", 80, {}, {".c", ".h"}},
      {"JavaScript", "", 75, {"package.json"}, {".js", ".jsx", ".ts"}},
      {"QML", "", 70, {"qmldir"}, {".qml"}},
      {"Rust", "", 65, {"Cargo.toml"}, {".rs"}},
      {"Lua", "", 60, {".luarc.json"}, {".lua"}},
      {"Bash", "", 10, {}, {".sh", ".bash"}}};

  std::unordered_set<std::string> dir_files;
  std::unordered_set<std::string> dir_exts;

  try {
    int count = 0;
    for (const auto &entry : fs::directory_iterator(fs::current_path())) {
      if (count++ > 1000)
        break;
      dir_files.insert(entry.path().filename().string());
      dir_exts.insert(entry.path().extension().string());
    }
  } catch (...) {
  }

  std::vector<LangDetect> found_langs;
  for (const auto &lang : languages) {
    bool match = false;
    for (const auto &trigger : lang.triggers) {
      if (dir_files.count(trigger)) {
        match = true;
        break;
      }
    }
    if (!match) {
      for (const auto &ext : lang.extensions) {
        if (dir_exts.count(ext)) {
          match = true;
          break;
        }
      }
    }
    if (match)
      found_langs.push_back(lang);
  }

  if (found_langs.empty())
    return {"", 0};

  std::sort(found_langs.begin(), found_langs.end(),
            [](const LangDetect &a, const LangDetect &b) {
              return a.weight > b.weight;
            });

  std::string icons = "";
  int icon_width = 0;
  for (size_t i = 0; i < found_langs.size(); ++i) {
    icons += found_langs[i].icon + " ";
    icon_width += 2;
  }

  std::string zsh_code = "%F{" + C_GREEN + "}%K{" + C_GREEN + "}%F{" +
                         C_BASE + "} " + icons + "%k%F{" + C_GREEN + "}%f";
  int width = 3 + icon_width;

  return {zsh_code, width};
}

RenderedPill get_directory_pill() {
  std::string pwd;
  try {
    pwd = fs::current_path().string();
  } catch (...) {
    pwd = "?";
  }

  std::string home = getenv("HOME") ? getenv("HOME") : "";
  if (!home.empty() && pwd.find(home) == 0) {
    pwd.replace(0, home.length(), "~");
  }

  // 1. 定义已知目录前缀和它们对应的图标
  // (注意：我去掉了图标自带的空格，便于拼接)
  struct DirSub {
    std::string prefix;
    std::string icon;
  };
  std::vector<DirSub> subs = {
      {"~/Downloads", ""},  {"~/Desktop", ""},    {"~/Documents", ""},
      {"~/Pictures", ""},   {"~/Videos", ""},     {"~/Music", "󰎈"},
      {"~/Templates", "󰏪"}, {"~/Public", "󰙨"},    {"~/GitHub", "󰊤"},
      {"~/Projects", "󰊤"},  {"~/Workspace", "󰊤"}, {"~", ""}};

  std::string icon = "";
  std::string display_path = pwd;
  bool matched = false;

  // 2. 匹配并剔除冗余前缀文本
  for (const auto &sub : subs) {
    if (pwd == sub.prefix) {
      icon = sub.icon;
      display_path = ""; // 完全匹配，直接清空文本
      matched = true;
      break;
    } else if (pwd.find(sub.prefix + "/") == 0) {
      icon = sub.icon;
      // 截取掉前缀，只保留后续路径
      display_path = pwd.substr(sub.prefix.length() + 1);
      matched = true;
      break;
    }
  }

  if (!matched && pwd == "/") {
    icon = "󰀘";
    display_path = "";
  }

  // 3. 截断逻辑 (最大显示 3 级目录，同款 end_4 的 ••/ 逻辑)
  int max_components = 3;
  std::vector<std::string> parts;
  size_t start = 0, end;
  while ((end = display_path.find('/', start)) != std::string::npos) {
    if (end != start) {
      parts.push_back(display_path.substr(start, end - start));
    }
    start = end + 1;
  }
  if (start < display_path.length()) {
    parts.push_back(display_path.substr(start));
  }

  std::string final_path = display_path;
  if (parts.size() > max_components) {
    final_path = "••/";
    // 只保留最后的 max_components 个目录
    for (size_t i = parts.size() - max_components; i < parts.size(); ++i) {
      final_path += parts[i];
      if (i != parts.size() - 1)
        final_path += "/";
    }
  }

  // 4. 组装胶囊内部文本与计算宽度
  std::string inner_text = icon;
  int inner_width = 1; // 仅图标本身占 1 格

  // 如果后面还有路径，我们加上空格隔开
  if (!final_path.empty()) {
    inner_text += " " + final_path;
    inner_width += 1 + final_path.length(); // 空格(1) + 路径长度
  }

  // 5. 生成最终的 Zsh 代码
  std::string zsh_code = "%F{" + C_BLUE + "}%K{" + C_BLUE + "}%F{" + C_BASE +
                         "}" + inner_text + " %k%F{" + C_BLUE + "}%f";

  // (1) + inner_width + 尾部空格(1) + (1) = 3 + inner_width
  int width = 3 + inner_width;

  return {zsh_code, width};
}

RenderedPill get_git_pill() {
  std::string git_status = exec_cmd("git status --porcelain -b 2>/dev/null");
  if (git_status.empty())
    return {"", 0};

  std::string branch = "Git";
  std::string first_line = "";
  size_t nl_pos = git_status.find('\n');
  if (nl_pos != std::string::npos)
    first_line = git_status.substr(0, nl_pos);
  else
    first_line = git_status;

  size_t hash_pos = first_line.find("## ");
  if (hash_pos != std::string::npos) {
    size_t dot_pos = first_line.find("...", hash_pos);
    size_t space_pos = first_line.find(' ', hash_pos + 3);
    size_t end_pos = std::min(dot_pos, space_pos);
    if (end_pos != std::string::npos)
      branch = first_line.substr(hash_pos + 3, end_pos - hash_pos - 3);
    else
      branch = first_line.substr(hash_pos + 3);
  }

  if (branch.length() > 12) {
    branch = branch.substr(0, 12);
  }

  bool is_ahead = first_line.find("ahead") != std::string::npos;
  bool is_behind = first_line.find("behind") != std::string::npos;
  bool is_diverged = is_ahead && is_behind;

  bool is_untracked = false, is_modified = false, is_renamed = false,
       is_deleted = false, is_conflicted = false;
  int staged_count = 0;

  size_t pos = nl_pos != std::string::npos ? nl_pos + 1 : std::string::npos;
  while (pos != std::string::npos && pos < git_status.length()) {
    size_t next_nl = git_status.find('\n', pos);
    if (pos + 2 <= git_status.length()) {
      std::string st = git_status.substr(pos, 2);
      if (st == "??")
        is_untracked = true;
      else if (st == "UU")
        is_conflicted = true;
      else {
        if (st[1] == 'M')
          is_modified = true;
        if (st[0] == 'R')
          is_renamed = true;
        if (st[0] == 'D' || st[1] == 'D')
          is_deleted = true;
        if (st[0] == 'M' || st[0] == 'A')
          staged_count++;
      }
    }
    pos = next_nl != std::string::npos ? next_nl + 1 : std::string::npos;
  }

  std::string status_str = "";
  int status_width = 0;

  if (is_conflicted) {
    status_str += " 🏳";
    status_width += 3;
  } else if (is_diverged) {
    status_str += " 😵";
    status_width += 3;
  } else if (is_ahead) {
    status_str += " 🏎💨";
    status_width += 5;
  } else if (is_behind) {
    status_str += " 😰";
    status_width += 3;
  }

  if (staged_count > 0) {
    std::string cnt = std::to_string(staged_count);
    status_str += " ++" + cnt;
    status_width += 3 + cnt.length();
  }
  if (is_renamed) {
    status_str += " ✍️";
    status_width += 3;
  }
  if (is_modified) {
    status_str += " 📝";
    status_width += 3;
  }
  if (is_deleted) {
    status_str += " 🗑";
    status_width += 3;
  }
  if (is_untracked) {
    status_str += " 🤷";
    status_width += 3;
  }

  std::string zsh_code = "%F{" + C_PURPLE + "}%K{" + C_PURPLE + "}%F{" +
                         C_BASE + "}󰘬 " + branch + status_str + " %k%F{" +
                         C_PURPLE + "}%f";
  int width = 5 + branch.length() + status_width;

  return {zsh_code, width};
}
