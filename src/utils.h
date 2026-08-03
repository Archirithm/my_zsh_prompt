#pragma once
#include <string>

struct PillColors {
        std::string background;
        std::string foreground;
};

struct PromptPalette {
        PillColors path;
        PillColors git;
        PillColors language;
        PillColors time;
        PillColors error;
        std::string connector;
        std::string arrow;
};

struct RenderedPill {
        std::string zsh_code;
        int visible_width;
};

PromptPalette prompt_palette();
int visible_width(const std::string &text);
RenderedPill render_text(const std::string &color, const std::string &text);
RenderedPill render_pill(const std::string &background,
                const std::string &foreground, const std::string &inner_text);
RenderedPill render_pill(const std::string &background,
                const std::string &foreground, const std::string &inner_zsh_code,
                const std::string &visible_text);
std::string exec_cmd(const char *cmd);
RenderedPill get_lang_env();
RenderedPill get_directory_pill();
RenderedPill get_git_pill();
