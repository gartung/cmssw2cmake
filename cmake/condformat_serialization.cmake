macro(condformat_serialization name header)
  get_compiler_flags(FLAGS llvm ${name} CPPFLAGS CPPDEFINED CXXFLAGS)
  target_sources(${name} PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/Serialization.cc)
  add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/Serialization.cc
                    COMMAND ${COND_SERIALIZATION_SCRIPT} --output ${CMAKE_CURRENT_BINARY_DIR}/Serialization.cc --package ${CMAKE_CURRENT_SOURCE_DIR} -- ${FLAGS}
                    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${header}
                    )
  unset(FLAGS)
endmacro()
