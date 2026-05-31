from conan import ConanFile
from conan.tools.cmake import CMakeToolchain, CMake, cmake_layout
from conan.tools.build import check_min_cppstd


class HelloConan(ConanFile):
    name = "hello"
    version = "1.0.0"
    description = "A simple hello world C++ library"
    license = "MIT"
    url = "https://github.com/jfrog/jfrog-sample"
    homepage = "https://github.com/jfrog/jfrog-sample"
    topics = ("hello", "sample", "jfrog")

    settings = "os", "compiler", "build_type", "arch"
    options = {"shared": [True, False], "fPIC": [True, False]}
    default_options = {"shared": False, "fPIC": True}

    exports_sources = "CMakeLists.txt", "src/*", "include/*"
    generators = "CMakeToolchain", "CMakeDeps"

    requires = "openssl/1.1.1w"

    def config_options(self):
        if self.settings.os == "Windows":
            del self.options.fPIC

    def layout(self):
        cmake_layout(self)

    def validate(self):
        check_min_cppstd(self, 11)

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()

    def package_info(self):
        self.cpp_info.libs = ["hello"]
