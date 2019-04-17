cmake_minimum_required(VERSION 3.10 FATAL_ERROR)

project(cmssw VERSION 10.5.0 Languages C CXX Fortran)

include (${CMAKE_SOURCE_DIR}/cmssw-cmake/cmake/all.cmake)

set(CMAKE_COMPILER gcc)
# Used with Find${CMAKE_COMPILER}_(cxx,c,f77)compiler to set compilation flags.
# Might be expanded to handle clang flags if there is enough difference.

set(dirnames src bin test plugins interface)
foreach(dirname ${dirnames})
file(GLOB subdirs "*/*/${dirname}")
  foreach(dir ${subdirs})
    if(IS_DIRECTORY ${dir} AND EXISTS ${dir}/CMakeLists.txt)
      add_subdirectory(${dir})
    endif()
  endforeach()
endforeach()
