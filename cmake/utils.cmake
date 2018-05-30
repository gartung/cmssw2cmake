function(get_compiler_flags var compiler target)
#  cms_find_package(${compiler}_cxxcompiler)
  get_cppflags(${var} ${target})
  #string(REPLACE " " ";" v ${CMAKE_CXX_FLAGS})
  set(${var} ${${var}} ${PROJECT_CXXFLAGS} PARENT_SCOPE)
endfunction()

function(get_cppflags var target)
  set(v "")
  get_target_property(defs ${target} COMPILE_DEFINITIONS)
  if(defs)
    foreach(d ${defs})
      set(v ${v} -D${d})
    endforeach()
  endif()
  get_target_property(dirs ${target} INCLUDE_DIRECTORIES)
  if(dirs)
    foreach(inc ${dirs})
      set(v ${v} -I${inc})
    endforeach()
  endif()
  set(${var} ${${var}} ${v} PARENT_SCOPE)
endfunction()
