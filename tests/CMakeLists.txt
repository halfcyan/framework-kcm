# SPDX-License-Identifier: GPL-3.0-or-later

add_executable(framework-kcm-tests
    frameworkbackend_test.cpp
    ../src/frameworkbackend.cpp
    ../src/frameworkbackend.hpp
)

target_include_directories(framework-kcm-tests PRIVATE ../src)
target_link_libraries(framework-kcm-tests PRIVATE Qt6::Core)

add_test(NAME framework-backend COMMAND framework-kcm-tests)
