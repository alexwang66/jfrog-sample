#include "hello.h"
#include <openssl/opensslv.h>
#include <string>

namespace hello {
    std::string greet(const std::string& name) {
        return "Hello, " + name + "! Built with Conan + JFrog Artifactory.";
    }

    std::string compress_info() {
        return std::string("OpenSSL version: ") + OPENSSL_VERSION_TEXT;
    }
}
