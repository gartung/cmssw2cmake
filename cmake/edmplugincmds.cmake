macro(edmpluginrefresh name)
    message("edmpluginrefresh ${CMAKE_BINARY_DIR}/bin/edmPluginRefresh ${CMAKE_BINARY_DIR}/lib//plugin*.so")
    set(ENV{LD_LIBRARY_PATH} "${CMAKE_BINARY_DIR}/lib:$ENV{LD_LIBRARY_PATH}")
    add_custom_command(TARGET ${name} PRE_BUILD
                    COMMAND ${CMAKE_BINARY_DIR}/bin/edmPluginRefresh "${CMAKE_BINARY_DIR}/lib/plugin*.so"
                    )
endmacro()

macro(edmplugingen name)
  add_custom_command(TARGET ${name} POST_BUILD
                     COMMAND echo "module plugin${name}" >${CMAKE_BINARY_DIR}/lib/plugin${name}.edmplugin
                    )
endmacro()

