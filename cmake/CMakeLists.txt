cmake_minimum_required(VERSION ${CMAKE_VERSION})
project(cmsswdev NONE)
include(ExternalProject)

set_property(DIRECTORY PROPERTY EP_STEP_TARGETS
             configure build install test
  )

