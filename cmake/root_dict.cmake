macro(cms_rootdict name)
  cms_find_package(rootrflx)
  cms_find_package(rootcling)
  if("${ARGN}" STREQUAL "")
    set(classes_h classes.h)
    set(classes_xml classes_def.xml)
    set(${name}_ROOTDICT ${name}_x)
  else()
    set(classes_h ${ARGV1})
    set(classes_xml ${ARGV2})
    if(${name}_ROOTDICT)
      MATH(EXPR ${name}_DICT_COUNT "${${name}_DICT_COUNT}+1")
      set(${name}_ROOTDICT ${name}_x${${name}_DICT_COUNT})
    else()
      set(${name}_DICT_COUNT 0)
      set(${name}_ROOTDICT ${name}_x)
    endif()
  endif()
  set(${name}_EXTRA_SOURCES ${${name}_EXTRA_SOURCES} ${CMAKE_CURRENT_BINARY_DIR}/${${name}_ROOTDICT}.cc)
  set(${name}_ROOTDICTS ${${name}_ROOTDICTS} ${${name}_ROOTDICT})
  set(ROOTDICT_${${name}_ROOTDICT} ${classes_h} ${classes_xml} ${CMAKE_CURRENT_BINARY_DIR}/${${name}_ROOTDICT}.cc)
  unset(clases_h)
  unset(classes_xml)
endmacro()

macro(add_rootdict_rules name)
  foreach(dict ${${name}_ROOTDICTS})
    list(GET ROOTDICT_${dict} 0 classes_h)
    list(GET ROOTDICT_${dict} 1 classes_xml)
    list(GET ROOTDICT_${dict} 2 classes_cc)
    get_filename_component(classname ${classes_h} NAME_WE)
    set_source_files_properties(${classes_cc} PROPERTIES COMPILE_FLAGS "-Os -Wno-unused-variable")
    get_cppflags(FLAGS ${name})
    add_custom_command(OUTPUT ${classes_cc}
                    COMMAND ${ROOTRFLX_ROOT}/bin/genreflex ${CMAKE_CURRENT_SOURCE_DIR}/${classes_h}
                    -s ${CMAKE_CURRENT_SOURCE_DIR}/${classes_xml}
                    -o ${classes_cc}
                    --deep
                    --rootmap=${CMAKE_BINARY_DIR}/lib/${dict}.rootmap
                    --rootmap-lib=${CMAKE_BINARY_DIR}/lib/lib${name}.so
                    --library ${CMAKE_BINARY_DIR}/lib/lib${name}.so --multiDict
                    -DCMS_DICT_IMPL -D_REENTRANT -DGNUSOURCE -D__STRICT_ANSI__ ${FLAGS} -DCMSSW_REFLEX_DICT -I${CMAKE_CURRENT_SOURCE_DIR}
                    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${classes_h} ${CMAKE_CURRENT_SOURCE_DIR}/${classes_xml}
                    )
  endforeach()
  unset(clases_h)
  unset(classes_xml)
  unset(classname)
  unset(FLAGS)
endmacro()
