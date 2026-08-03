cmake_minimum_required(VERSION 3.21)
project(ClavisZshTheme VERSION 0.1.0 LANGUAGES CXX)

include(GNUInstallDirs)
include(CTest)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_executable(clavis_prompt
    src/main.cpp
    src/modules.cpp
    src/utils.h
)
set_target_properties(clavis_prompt PROPERTIES OUTPUT_NAME prompt)
target_include_directories(clavis_prompt PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")

install(TARGETS clavis_prompt RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
install(FILES
    src/clavis_prompt.zsh
    src/matugen-colors.zsh.in
    DESTINATION "${CMAKE_INSTALL_DATADIR}/clavis-zsh-theme"
)
install(PROGRAMS
    src/clavis-zsh-theme.sh
    src/apply.sh
    DESTINATION "${CMAKE_INSTALL_DATADIR}/clavis-zsh-theme"
)

if(BUILD_TESTING)
    add_executable(clavis_prompt_tests
        tests/prompt_tests.cpp
        src/modules.cpp
        src/utils.h
    )
    target_include_directories(clavis_prompt_tests PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")
    add_test(NAME clavis_zsh_prompt_tests COMMAND clavis_prompt_tests)
    find_program(BASH_EXECUTABLE bash REQUIRED)
    add_test(
        NAME clavis_zsh_managed_block_tests
        COMMAND "${BASH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_theme.sh"
    )
endif()
