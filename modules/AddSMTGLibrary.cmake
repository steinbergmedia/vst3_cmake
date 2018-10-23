
# TODO: Rename SMTG_VST3_TARGET_PATH

include(CMakePrintHelpers)

# Prints out all relevant properties of a target for debugging.
#
# @param target The target whose properties will be printed.
function(smtg_dump_plugin_package_variables target)
    cmake_print_properties(
        TARGETS
            ${target}
        PROPERTIES
            SMTG_PLUGIN_PACKAGE_NAME
            SMTG_PLUGIN_BINARY_DIR
            SMTG_PLUGIN_EXTENSION
            LIBRARY_OUTPUT_DIRECTORY
            SMTG_PLUGIN_PACKAGE_CONTENTS
            SMTG_PLUGIN_PACKAGE_RESOURCES
            SMTG_PLUGIN_PACKAGE_SNAPSHOTS
            SMTG_PLUGIN_USER_DEFINED_TARGET
            SMTG_WIN_ARCHITECTURE_NAME
    )
endfunction()

# Strips all symbols on linux
#
# @param target The target whose build symbols will be stripped
function (smtg_strip_symbols target)
    add_custom_command(TARGET ${target} POST_BUILD
        COMMAND ${CMAKE_COMMAND_STRIP} strip --strip-debug --strip-unneeded $<TARGET_FILE:${target}>
    )
endfunction()

#! smtg_strip_symbols : Strips all symbols on and creates debug file on linux 
#
# @param target The target whose build symbols will be stripped
function (smtg_strip_symbols_with_dbg target)
    add_custom_command(TARGET ${target} POST_BUILD
        # Create a target.so.dbg file with debug information
        COMMAND ${CMAKE_COMMAND_OBJECT_COPY} objcopy --only-keep-debug $<TARGET_FILE:${target}> $<TARGET_FILE:${target}>.dbg
        COMMAND ${CMAKE_COMMAND_STRIP} strip --strip-debug --strip-unneeded $<TARGET_FILE:${target}>
        COMMAND ${CMAKE_COMMAND_OBJECT_COPY} objcopy --add-gnu-debuglink=$<TARGET_FILE:${target}>.dbg $<TARGET_FILE:${target}>
    )
endfunction()

# Creates a symlink to the targets output resp plug-in.
#
# A symlink to the output plug-in will be created as a post build step.
#
# @param target The target whose output is the symlink's source.
function (smtg_create_link_to_plugin target)
    if(${SMTG_VST3_TARGET_PATH} STREQUAL "")
        message(FATAL_ERROR "Define a proper value for SMTG_VST3_TARGET_PATH")
    endif()

    get_target_property(TARGET_SOURCE       ${target} SMTG_PLUGIN_PACKAGE_PATH)
    get_target_property(TARGET_DESTINATION  ${target} SMTG_PLUGIN_USER_DEFINED_TARGET)
    if(WIN)
        get_target_property(PLUGIN_BINARY_DIR   ${target} SMTG_PLUGIN_BINARY_DIR)
        get_target_property(PLUGIN_PACKAGE_NAME ${target} SMTG_PLUGIN_PACKAGE_NAME)

        file(TO_NATIVE_PATH "${TARGET_DESTINATION}/${PLUGIN_PACKAGE_NAME}" SRC_NATIVE_PATH)
        file(TO_NATIVE_PATH "${PLUGIN_BINARY_DIR}/Debug/${PLUGIN_PACKAGE_NAME}" TARGET_DESTINATION_DEBUG)
        file(TO_NATIVE_PATH "${PLUGIN_BINARY_DIR}/Release/${PLUGIN_PACKAGE_NAME}" TARGET_DESTINATION_RELEASE)

        add_custom_command(
            TARGET ${target} POST_BUILD
            COMMAND del "${SRC_NATIVE_PATH}"
            COMMAND mklink 
                ${SRC_NATIVE_PATH}
                $<$<CONFIG:Debug>:${TARGET_DESTINATION_DEBUG}>
                $<$<CONFIG:Release>:${TARGET_DESTINATION_RELEASE}>
        )
    else()
        add_custom_command(
            TARGET ${target} POST_BUILD
            COMMAND ln -sfF "${TARGET_SOURCE}" "${TARGET_DESTINATION}"
        )
    endif()
endfunction()

# Customizes folder icon on windows
#
# Customizes folder icon on windows by copying desktop.ini and PlugIn.ico into the package.
#
# @param target The target whose folder icon will be customized.
function(smtg_add_folder_icon target)
    get_target_property(PLUGIN_PACKAGE_PATH ${target} SMTG_PLUGIN_PACKAGE_PATH)
    add_custom_command(TARGET ${target}
        COMMENT "Copy PlugIn.ico and desktop.ini and change their attributes."   
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
            ${PROJECT_SOURCE_DIR}/doc/artwork/VST_Logo_Steinberg.ico
            ${PLUGIN_PACKAGE_PATH}/PlugIn.ico
        COMMAND ${CMAKE_COMMAND} -E copy
            ${PROJECT_SOURCE_DIR}/cmake/templates/desktop.ini.in
            ${PLUGIN_PACKAGE_PATH}/desktop.ini
        COMMAND attrib +s ${PLUGIN_PACKAGE_PATH}/desktop.ini
        COMMAND attrib +s ${PLUGIN_PACKAGE_PATH}/PlugIn.ico
        COMMAND attrib +s ${PLUGIN_PACKAGE_PATH}
    )
endfunction()

# Adds the plug-in's main entry point.
#
# The variable public_sdk_SOURCE_DIR needs to be specified.
#
# @param target The target to which the main entry point will be added.
function(smtg_add_library_main target)
    if(NOT public_sdk_SOURCE_DIR)
        message(FATAL_ERROR "The variable public_sdk_SOURCE_DIR is not set. Please specify the path to public.sdk's source dir.")
    endif()
    if(MAC)
        target_sources (${target} 
            PRIVATE 
                ${public_sdk_SOURCE_DIR}/source/main/macmain.cpp
        )
        smtg_set_exported_symbols(${target} ${public_sdk_SOURCE_DIR}/source/main/macexport.exp)
    elseif(WIN)
        target_sources (${target} 
            PRIVATE 
                ${public_sdk_SOURCE_DIR}/source/main/dllmain.cpp
        )
    elseif(LINUX)
        target_sources (${target} 
            PRIVATE 
                ${public_sdk_SOURCE_DIR}/source/main/linuxmain.cpp
        )
    endif()
endfunction()

# Returns the linux architecture name.
#
# This name will be used as a folder name inside the plug-in package.
# The variable LINUX_ARCHITECTURE_NAME will be set.
function(smtg_get_linux_architecture_name)
    EXECUTE_PROCESS(
        COMMAND uname -m 
        COMMAND tr -d '\n' 
        OUTPUT_VARIABLE ARCHITECTURE
    )

    set(LINUX_ARCHITECTURE_NAME ${ARCHITECTURE}-linux PARENT_SCOPE)
endfunction()

# Prepare the target to build a plug-in package.
#
# @param target The target whose output will be put into a package.
# @param extension The package's extension
function(smtg_make_plugin_package target extension)
    string(TOUPPER ${extension} PLUGIN_EXTENSION_UPPER)
    set_target_properties(${target} PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY        ${CMAKE_BINARY_DIR}/${PLUGIN_EXTENSION_UPPER}
        SMTG_PLUGIN_BINARY_DIR          ${CMAKE_BINARY_DIR}/${PLUGIN_EXTENSION_UPPER}
        SMTG_PLUGIN_EXTENSION           ${extension}
        SMTG_PLUGIN_PACKAGE_NAME        ${target}.${extension}
        SMTG_PLUGIN_PACKAGE_CONTENTS    Contents
        SMTG_PLUGIN_PACKAGE_RESOURCES   Contents/Resources
        SMTG_PLUGIN_PACKAGE_SNAPSHOTS   Snapshots
        SMTG_PLUGIN_USER_DEFINED_TARGET ${SMTG_VST3_TARGET_PATH}/${PLUGIN_PACKAGE_NAME}
    )

    get_target_property(PLUGIN_BINARY_DIR   ${target} SMTG_PLUGIN_BINARY_DIR)
    get_target_property(PLUGIN_EXTENSION    ${target} SMTG_PLUGIN_EXTENSION)
    get_target_property(PLUGIN_PACKAGE_NAME ${target} SMTG_PLUGIN_PACKAGE_NAME)

    smtg_add_library_main(${target})

    if(MAC)
        set_target_properties(${target} PROPERTIES
            BUNDLE TRUE
        )
        if(XCODE)
            set_target_properties(${target} PROPERTIES 
                XCODE_ATTRIBUTE_GENERATE_PKGINFO_FILE   YES
                XCODE_ATTRIBUTE_WRAPPER_EXTENSION       ${PLUGIN_EXTENSION}
                SMTG_PLUGIN_PACKAGE_PATH      
                    ${PLUGIN_BINARY_DIR}/$<$<CONFIG:Debug>:Debug>$<$<CONFIG:Release>:Release>/${PLUGIN_PACKAGE_NAME}
            )
        else()
            set_target_properties(${target} PROPERTIES 
                BUNDLE_EXTENSION            ${PLUGIN_EXTENSION}
                LIBRARY_OUTPUT_DIRECTORY    ${PLUGIN_BINARY_DIR}/${CMAKE_BUILD_TYPE}
                SMTG_PLUGIN_PACKAGE_PATH    ${PLUGIN_BINARY_DIR}/${CMAKE_BUILD_TYPE}/${PLUGIN_PACKAGE_NAME}
            )
        endif()

        target_link_libraries(${target} PRIVATE "-framework CoreFoundation")
        smtg_setup_universal_binary(${target})

    elseif(WIN)
        set_target_properties(${target} PROPERTIES 
            SUFFIX              .${PLUGIN_EXTENSION}
            LINK_FLAGS          /EXPORT:GetPluginFactory
            SMTG_PLUGIN_PACKAGE_PATH      
                ${PLUGIN_BINARY_DIR}/$<$<CONFIG:Debug>:Debug>$<$<CONFIG:Release>:Release>/${PLUGIN_PACKAGE_NAME}
        )
        
        # In order not to have the PDB inside the plug-in package in release builds, we specify a different location.
        set_target_properties(${target} PROPERTIES
            PDB_OUTPUT_DIRECTORY
                ${PROJECT_BINARY_DIR}/WIN_PDB
        )

        # Create Bundle on Windows
        if (SMTG_CREATE_BUNDLE_FOR_WINDOWS)
            get_target_property(WIN_ARCHITECTURE_NAME ${target} SMTG_WIN_ARCHITECTURE_NAME)

            # When using LIBRARY_OUTPUT_DIRECTORY, cmake adds another /Debug resp. /Release folder at the end of the path.
            # In order to prevent cmake from doing that we set LIBRARY_OUTPUT_DIRECTORY_DEBUG and LIBRARY_OUTPUT_DIRECTORY_RELEASE
            # (or LIBRARY_OUTPUT_DIRECTORY_${CONFIG_UPPERCASE}) directly.
            get_target_property(PLUGIN_PACKAGE_CONTENTS ${target} SMTG_PLUGIN_PACKAGE_CONTENTS)
            foreach(OUTPUTCONFIG ${CMAKE_CONFIGURATION_TYPES})
                string(TOUPPER ${OUTPUTCONFIG} OUTPUTCONFIG_UPPER)
                set_target_properties(${target} PROPERTIES 
                    LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG_UPPER}
                        ${PLUGIN_BINARY_DIR}/${OUTPUTCONFIG}/${PLUGIN_PACKAGE_NAME}/${PLUGIN_PACKAGE_CONTENTS}/${WIN_ARCHITECTURE_NAME}
            )
            endforeach()
                
            smtg_add_folder_icon(${target})
        endif()
        # Disable warning LNK4221: "This object file does not define any previously undefined public symbols...".
        # Enable "Generate Debug Information" in release config by setting "/Zi" and "/DEBUG" flags.
        if(MSVC)
            target_compile_options(${target} 
                PRIVATE 
                    /wd4221
                    $<$<CONFIG:RELEASE>:/Zi>
            )
            set_property(TARGET ${target} 
                APPEND PROPERTY 
                    LINK_FLAGS_RELEASE /DEBUG
            )
        endif()
    elseif(LINUX)
        smtg_get_linux_architecture_name() # Sets var LINUX_ARCHITECTURE_NAME
        message(STATUS "Linux architecture name is ${LINUX_ARCHITECTURE_NAME}.")

        get_target_property(PLUGIN_PACKAGE_CONTENTS ${target} SMTG_PLUGIN_PACKAGE_CONTENTS)
        set_target_properties(${target} PROPERTIES
            PREFIX                   ""
            LIBRARY_OUTPUT_DIRECTORY ${PLUGIN_BINARY_DIR}/${CMAKE_BUILD_TYPE}/${PLUGIN_PACKAGE_NAME}/${PLUGIN_PACKAGE_CONTENTS}/${LINUX_ARCHITECTURE_NAME}
            SMTG_PLUGIN_PACKAGE_PATH ${PLUGIN_BINARY_DIR}/${CMAKE_BUILD_TYPE}/${PLUGIN_PACKAGE_NAME}
        )

        # Strip symbols in Release config
        if(${CMAKE_BUILD_TYPE} MATCHES Release)
            smtg_strip_symbols(${target})
        elseif(${CMAKE_BUILD_TYPE} MATCHES RelWithDebInfo)
            smtg_strip_symbols_with_dbg(${target})
        endif()
    endif()
endfunction()

# Adds a resource for a target 
#
# The resource which gets copied into the targets Resource Bundle directory.
#
# @param target cmake target
# @param input_file resource file
# @param ARGV2 destination subfolder
function(smtg_add_plugin_resource target input_file)
    if (LINUX OR (WIN AND SMTG_CREATE_BUNDLE_FOR_WINDOWS))
        get_target_property(PLUGIN_PACKAGE_PATH ${target} SMTG_PLUGIN_PACKAGE_PATH)
        get_target_property(PLUGIN_PACKAGE_RESOURCES ${target} SMTG_PLUGIN_PACKAGE_RESOURCES)
        set(destination_folder "${PLUGIN_PACKAGE_PATH}/${PLUGIN_PACKAGE_RESOURCES}")
        if(ARGV2)
            set(destination_folder "${destination_folder}/${ARGV2}")
        endif()
        if(NOT EXISTS ${destination_folder})
          add_custom_command(TARGET ${target} PRE_LINK
              COMMAND ${CMAKE_COMMAND} -E make_directory
              "${destination_folder}"
          )
        endif()
        add_custom_command(TARGET ${target} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy
            ${CMAKE_CURRENT_LIST_DIR}/${input_file}
            ${destination_folder}
        )
    elseif(MAC)
        target_sources(${target} PRIVATE ${input_file})
        set(destination_folder "Resources")
        if(ARGV2)
            set(destination_folder "${destination_folder}/${ARGV2}")
        endif()
        set_source_files_properties(${input_file} PROPERTIES MACOSX_PACKAGE_LOCATION "${destination_folder}")
    endif()
endfunction()

# Adds a snapshot for a target.
#
# Adds a snapshot for a target which gets copied into the targets Snapshot Bundle directory.
#
# @param target The target to which the snapshot will be added
# @param snapshot The snapshot to be added.
function(smtg_add_plugin_snapshot target snapshot)
    get_target_property(PLUGIN_PACKAGE_SNAPSHOTS ${target} SMTG_PLUGIN_PACKAGE_SNAPSHOTS)
    smtg_add_plugin_resource ("${target}" "${snapshot}" "${PLUGIN_PACKAGE_SNAPSHOTS}") 
endfunction()