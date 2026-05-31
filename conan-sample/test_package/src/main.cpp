#include <iostream>
#include "hello.h"

int main() {
    std::cout << hello::greet("JFrog") << std::endl;
    std::cout << hello::compress_info() << std::endl;
    return 0;
}
