# Prompt source and attribution

The prompt implementation in `src/main.cpp`, `src/modules.cpp`, `src/utils.h` and
`tests/prompt_tests.cpp` was copied from the local source provider
`/home/archirithm/prompt_dev`.

The source provider was inspected at migration time and reported a clean Git
history relative to `origin/main` except for the user's existing modifications to
`.zshrc`, `README.md`, `main.cpp`, `modules.cpp`, `tests.cpp` and `utils.h`. Those
changes were copied as source input and the provider was not modified.

The provider README attributes the prompt screenshots and project background to
`Archirithm/my_zsh_prompt`. No standalone upstream license file was present, so
this package does not claim a different upstream license or silently copy the
provider's personal `.zshrc` and screenshots.
