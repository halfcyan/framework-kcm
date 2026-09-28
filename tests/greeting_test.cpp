#include <cassert>
#include <string_view>

#include "greeting.hpp"

int main() {
    assert(cpp_template::greeting() == std::string_view{"Hello from C++!"});
    return 0;
}
