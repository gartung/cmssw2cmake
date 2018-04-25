set(COND_SERIALIZATION_SCRIPT_NAME CondFormats/Serialization/python/condformats_serialization_generate.py)
if(EXISTS ${CMAKE_SOURCE_DIR}/${COND_SERIALIZATION_SCRIPT_NAME})
  set(COND_SERIALIZATION_SCRIPT ${CMAKE_SOURCE_DIR}/${COND_SERIALIZATION_SCRIPT_NAME})
endif()
include (${CMAKE_CURRENT_LIST_DIR}/common.cmake)
include (${CMAKE_CURRENT_LIST_DIR}/root_dict.cmake)
include (${CMAKE_CURRENT_LIST_DIR}/utils.cmake)
include (${CMAKE_CURRENT_LIST_DIR}/condformat_serialization.cmake)

