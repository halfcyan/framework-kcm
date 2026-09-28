#pragma once

#include <string_view>

namespace cpp_template {

    [[nodiscard]] constexpr std::string_view greeting() noexcept { return "Hello from C++!"; }

} // namespace cpp_template
