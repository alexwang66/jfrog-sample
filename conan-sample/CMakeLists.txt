cmake_minimum_required(VERSION 3.15)
project(hello VERSION 1.0.0 LANGUAGES CXX)

find_package(OpenSSL REQUIRED)

add_library(hello src/hello.cpp)

target_include_directories(hello PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

target_link_libraries(hello PUBLIC OpenSSL::SSL OpenSSL::Crypto)

set_target_properties(hello PROPERTIES
    CXX_STANDARD 11
    CXX_STANDARD_REQUIRED ON
)

install(TARGETS hello
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)
install(DIRECTORY include/ DESTINATION include)
