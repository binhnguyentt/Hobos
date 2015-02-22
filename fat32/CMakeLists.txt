cmake_minimum_required(VERSION 2.8.4)
project(code)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

set(SOURCE_FILES fat32.cpp)
add_executable(code ${SOURCE_FILES})