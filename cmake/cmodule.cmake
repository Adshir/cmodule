include(FetchContent)

string(TOUPPER ${CMAKE_FIND_PACKAGE_NAME} upper_find_package_name)

if(CMODULE_SHARED_LIBS OR CMODULE_${upper_find_package_name}_SHARED_LIB)
  set(CMODULE_SHARED_LIB YES)
  set(CMODULE_STATIC_LIB NO)
  set(CMODULE_LIB_TYPE "SHARED")
else()
  set(CMODULE_SHARED_LIB NO)
  set(CMODULE_STATIC_LIB YES)
  set(CMODULE_LIB_TYPE "STATIC")
endif()

#if(MSVC)
#  add_compile_definitions(_CRT_SECURE_NO_WARNINGS)
#endif()

if(CMODULE_DISABLE_WARNINGS)
  if(${CMAKE_CXX_COMPILER_ID} STREQUAL MSVC)
    add_compile_options(/W0)
  else()
    add_compile_options(-w)
  endif()
endif()

set_directory_properties(PROPERTIES USE_FOLDERS TRUE)
set(CMAKE_FOLDER "cmodule")

macro(find_package_next name)
  set(TEMP ${CMAKE_MODULE_PATH})
  list(REMOVE_ITEM CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")
  find_package(${name})
  set(CMAKE_MODULE_PATH ${TEMP})
endmacro()

macro(cmodule_select_target shared static)
  if(CMODULE_SHARED_LIB)
    set(CMODULE_TARGET ${shared})
  else()
    set(CMODULE_TARGET ${static})
  endif()
endmacro()

function(cmodule_add name version)
  set(content_name ${name}-${version})
  set(content_source_dir "")

  if(CMODULE_CACHE_SOURCE_DIR)
    set(source_dir ${CMODULE_CACHE_SOURCE_DIR}/${name}/${version})
    file(LOCK ${source_dir}.lock)
    file(GLOB source_dir_files ${source_dir}/*)
    if (EXISTS ${source_dir} AND source_dir_files)
      string(TOUPPER ${content_name} upper_content_name)
      set(FETCHCONTENT_SOURCE_DIR_${upper_content_name} ${source_dir})
    else()
      set(content_source_dir SOURCE_DIR ${source_dir})
    endif()
  endif()

  FetchContent_Declare(
    ${content_name}
    ${content_source_dir}
    ${ARGN}
  )

  FetchContent_GetProperties(${content_name})
  string(TOLOWER ${content_name} lower_content_name)
  if(NOT ${lower_content_name}_POPULATED)
    FetchContent_Populate(${content_name})
    if(EXISTS "${${content_name}_SOURCE_DIR}/CMakeLists.txt")
      add_subdirectory("${${content_name}_SOURCE_DIR}" "${${content_name}_BINARY_DIR}" EXCLUDE_FROM_ALL)
    endif()
  endif()

  if(CMODULE_CACHE_SOURCE_DIR)
    file(LOCK ${source_dir}.lock RELEASE)
  endif()

  set(CMODULE_${name}_SOURCE_DIR ${${content_name}_SOURCE_DIR} PARENT_SCOPE)
  set(CMODULE_${name}_BINARY_DIR ${${content_name}_BINARY_DIR} PARENT_SCOPE)

  string(TOUPPER ${CMAKE_FIND_PACKAGE_NAME} upper_find_package_name)
  set(${upper_find_package_name}_FOUND TRUE PARENT_SCOPE)
  set(${CMAKE_FIND_PACKAGE_NAME}_FOUND TRUE PARENT_SCOPE)
endfunction()
