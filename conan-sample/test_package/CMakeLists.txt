cmake_minimum_required(VERSION 3.15)
project(test_hello CXX)

find_package(hello REQUIRED)

add_executable(test_hello src/main.cpp)
target_link_libraries(test_hello hello::hello)
