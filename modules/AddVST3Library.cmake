
# File extension, folder name, output directory for VST3 Plug-Ins
set(VST_SDK TRUE) # used for Base module which provides only a subset of Base for VST-SDK
set(VST3_FOLDER_NAME VST3)
set(VST3_EXTENSION vst3)
set(VST3_OUTPUT_DIR ${CMAKE_BINARY_DIR}/${VST3_FOLDER_NAME})

include(SetupVST3LibraryDefaultPath)

if(WIN)
    set(DEF_OPT_LINK OFF) # be sure to start visual with admin right when enabling this
else()
    set(DEF_OPT_LINK ON)
endif()

#-------------------------------------------------------------------------------
# Run the validator after building 
function(smtg_run_vst_validator target)
    add_dependencies(${target} validator)
    if(WIN)
        set(TARGET_PATH $<TARGET_FILE:${target}>)
    else()
        set(TARGET_PATH "${VST3_OUTPUT_DIR}/${CMAKE_BUILD_TYPE}/${target}.${VST3_EXTENSION}")
    endif()
    add_custom_command(TARGET ${target} POST_BUILD COMMAND $<TARGET_FILE:validator> "${TARGET_PATH}" WORKING_DIRECTORY "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
endfunction()

#-------------------------------------------------------------------------------
# Strip symbols for Linux
function (smtg_strip_symbols target)
    add_custom_command(TARGET ${target} POST_BUILD
        COMMAND ${CMAKE_COMMAND_STRIP} strip --strip-debug --strip-unneeded $<TARGET_FILE:${target}>
    )
endfunction()

# Strip symbols with debug file for Linux
function (smtg_strip_symbols_with_dbg target)
    add_custom_command(TARGET ${target} POST_BUILD
        # Create a target.so.dbg file with debug information
        COMMAND ${CMAKE_COMMAND_OBJECT_COPY} objcopy --only-keep-debug $<TARGET_FILE:${target}> $<TARGET_FILE:${target}>.dbg
        COMMAND ${CMAKE_COMMAND_STRIP} strip --strip-debug --strip-unneeded $<TARGET_FILE:${target}>
        COMMAND ${CMAKE_COMMAND_OBJECT_COPY} objcopy --add-gnu-debuglink=$<TARGET_FILE:${target}>.dbg $<TARGET_FILE:${target}>
    )
endfunction()

#-------------------------------------------------------------------------------
# Create symbolic link to VST3 folder
function (smtg_create_link_to_VST3 target)
    if(${SMTG_VST3_TARGET_PATH} STREQUAL "")
        message(FATAL_ERROR "Define a proper value for SMTG_VST3_TARGET_PATH")
    endif()
    if(WIN)
        set(LOCAL_VST3_TARGET_PATH ${VST3_OUTPUT_DIR}\\${CMAKE_BUILD_TYPE}\\${target}.${VST3_EXTENSION})
        FILE(TO_NATIVE_PATH "${LOCAL_VST3_TARGET_PATH}" DEST_NATIVE_PATH)
        FILE(TO_NATIVE_PATH "${SMTG_VST3_TARGET_PATH}\\${target}.${VST3_EXTENSION}" SRC_NATIVE_PATH)

        add_custom_command(
            TARGET ${target} POST_BUILD
            COMMAND del "${SRC_NATIVE_PATH}"
            COMMAND mklink "${SRC_NATIVE_PATH}" ${DEST_NATIVE_PATH}
        )
    else()
        set(TARGET_SOURCE ${VST3_OUTPUT_DIR}/${CMAKE_BUILD_TYPE}/${target}.${VST3_EXTENSION})
        add_custom_command(
            TARGET ${target} POST_BUILD
            COMMAND rm -f ${SMTG_VST3_TARGET_PATH}/${target}.${VST3_EXTENSION}
            COMMAND ln -sfF ${TARGET_SOURCE} ${SMTG_VST3_TARGET_PATH}/${target}.${VST3_EXTENSION}
        )
    endif()
endfunction()

#-------------------------------------------------------------------------------
# VST3 Library Template
#-------------------------------------------------------------------------------
function(smtg_add_vst3plugin target sdkroot)
    set(sources ${ARGN})
    if(MAC)
        list(APPEND sources "${sdkroot}/public.sdk/source/main/macmain.cpp")
    elseif(WIN)
        list(APPEND sources "${sdkroot}/public.sdk/source/main/dllmain.cpp")
    elseif(LINUX)
        list(APPEND sources "${sdkroot}/public.sdk/source/main/linuxmain.cpp")
    endif()

    add_library(${target} MODULE ${sources})
    set_target_properties(${target} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${VST3_OUTPUT_DIR})
    target_compile_definitions(${target} PUBLIC $<$<CONFIG:Debug>:VSTGUI_LIVE_EDITING=1>)

    if(MAC)
        set_target_properties(${target} PROPERTIES BUNDLE TRUE)
        if(XCODE)
            set_target_properties(${target} PROPERTIES XCODE_ATTRIBUTE_GENERATE_PKGINFO_FILE "YES")
            set_target_properties(${target} PROPERTIES XCODE_ATTRIBUTE_WRAPPER_EXTENSION ${VST3_EXTENSION})
        else()
            set_target_properties(${target} PROPERTIES BUNDLE_EXTENSION ${VST3_EXTENSION})
        endif()
        smtg_set_exported_symbols(${target} "${sdkroot}/public.sdk/source/main/macexport.exp")

        target_link_libraries(${target} PRIVATE "-framework CoreFoundation")
        smtg_setup_universal_binary(${target})

    elseif(WIN)
        set_target_properties(${target} PROPERTIES SUFFIX ".${VST3_EXTENSION}")
        set_target_properties(${target} PROPERTIES LINK_FLAGS "/EXPORT:GetPluginFactory")
        set_target_properties(${target} PROPERTIES LINK_FLAGS_RELEASE "/EXPORT:GetPluginFactory /DEBUG:FASTLINK")
        if(MSVC)
            target_compile_options(${target} PRIVATE /wd4221)
        endif()
    elseif(LINUX)
        # ...
        EXECUTE_PROCESS( COMMAND uname -m COMMAND tr -d '\n' OUTPUT_VARIABLE ARCHITECTURE )
        set(target_lib_dir ${ARCHITECTURE}-linux)
        set(VST3_CONTENTS_PATH "${VST3_OUTPUT_DIR}/${CMAKE_BUILD_TYPE}/${target}.${VST3_EXTENSION}/Contents")
        set_target_properties(${target} PROPERTIES PREFIX "")
        set_target_properties(${target} PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${VST3_CONTENTS_PATH}/${target_lib_dir}")
        add_custom_command(TARGET ${target} PRE_LINK
            COMMAND ${CMAKE_COMMAND} -E make_directory
            "${VST3_CONTENTS_PATH}/Resources"
        )

        # Strip symbols in Release config
        if(${CMAKE_BUILD_TYPE} MATCHES Release)
            smtg_strip_symbols(${target})
        elseif(${CMAKE_BUILD_TYPE} MATCHES RelWithDebInfo)
            smtg_strip_symbols_with_dbg(${target})
        endif()
    endif()
    if(SMTG_RUN_VST_VALIDATOR)
        smtg_run_vst_validator(${target})
    endif()

    if(SMTG_CREATE_VST3_LINK)
        smtg_create_link_to_VST3(${target})
    endif()
endfunction()

function(smtg_add_vst3_resource target input_file)
    if (LINUX)
        set(VST3_CONTENTS_PATH "${VST3_OUTPUT_DIR}/${CMAKE_BUILD_TYPE}/${target}.${VST3_EXTENSION}/Contents")
        add_custom_command(TARGET ${target} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy
            "${CMAKE_CURRENT_LIST_DIR}/${input_file}"
            "${VST3_CONTENTS_PATH}/Resources/"
        )
    elseif(MAC)
        target_sources(${target} PRIVATE ${input_file})
        set_source_files_properties(${input_file} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
    endif()
endfunction()
