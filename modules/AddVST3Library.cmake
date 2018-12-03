
include(AddSMTGLibrary)

# Runs the validator on a VST3 target.
#
# The validator will be run on the target as a post build step.
#
# @param target The target which the validator will validate. 
function(smtg_run_vst_validator target)
    add_dependencies(${target} validator)
    if(SMTG_WIN)
        set(TARGET_PATH $<TARGET_FILE:${target}>)
        add_custom_command(TARGET ${target} 
            POST_BUILD COMMAND 
                $<TARGET_FILE:validator> 
                "${TARGET_PATH}" 
                WORKING_DIRECTORY "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}"
            )
    else()
        get_target_property(PLUGIN_PACKAGE_PATH ${target} SMTG_PLUGIN_PACKAGE_PATH)
        add_custom_command(TARGET ${target} 
            POST_BUILD COMMAND 
                $<TARGET_FILE:validator> 
                $<$<CONFIG:Debug>:${PLUGIN_PACKAGE_PATH}>
                $<$<CONFIG:Release>:${PLUGIN_PACKAGE_PATH}> 
                WORKING_DIRECTORY "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}"
        )
    endif()
endfunction()

# Returns the windows architecture.
#
# This name will be used as a folder name inside the plug-in package.
# The variable WIN_ARCHITECTURE_NAME will be set.
function(smtg_set_vst_win_architecture_name)
    if(SMTG_WIN AND CMAKE_SIZEOF_VOID_P EQUAL 8)
        if(${CMAKE_GENERATOR} MATCHES "ARM")
            set(WIN_ARCHITECTURE_NAME "arm_64-win")
        else()
            set(WIN_ARCHITECTURE_NAME "x86_64-win")
        endif()
    else()
        if(${CMAKE_GENERATOR} MATCHES "ARM")
            set(WIN_ARCHITECTURE_NAME "arm-win")
        else()
            set(WIN_ARCHITECTURE_NAME "x86-win")
        endif()
    endif()

    set_target_properties(${target}
        PROPERTIES
            SMTG_WIN_ARCHITECTURE_NAME ${WIN_ARCHITECTURE_NAME}           
    )
endfunction()

# Adds a vst3 target.
#
# @param target The target to which a vst3 plug-in will be added. 
function(smtg_add_vst3plugin target)
    add_library(${target} MODULE ${ARGN})
    smtg_set_vst_win_architecture_name(${target})
    smtg_make_plugin_package(${target} vst3)

    if(SMTG_ENABLE_TARGET_VARS_LOG)
        smtg_dump_plugin_package_variables(${target})
    endif()

    target_compile_definitions(${target} PUBLIC $<$<CONFIG:Debug>:VSTGUI_LIVE_EDITING=1>)
    
    if(SMTG_RUN_VST_VALIDATOR)
        smtg_run_vst_validator(${target})
    endif()

    if(SMTG_CREATE_VST3_LINK)
        smtg_create_link_to_plugin(${target})
    endif()

    if(SMTG_MAC AND XCODE AND SMTG_IOS_DEVELOPMENT_TEAM)
        set_target_properties(${target} PROPERTIES
            XCODE_ATTRIBUTE_DEVELOPMENT_TEAM ${SMTG_IOS_DEVELOPMENT_TEAM}
            XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "Mac Developer"
        )
    endif()
endfunction()

# Adds a vst3 target for iOS
#
# @param sign_identity which code signing identity to use
# @param target The target to which a vst3 plug-in will be added.
function(smtg_add_ios_vst3plugin sign_identity target)
    if(SMTG_MAC AND XCODE AND SMTG_IOS_DEVELOPMENT_TEAM)
        add_library(${target} MODULE ${ARGN})
        smtg_make_plugin_package(${target} vst3)

        if(SMTG_ENABLE_TARGET_VARS_LOG)
            smtg_dump_plugin_package_variables(${target})
        endif()

        target_compile_definitions(${target} PUBLIC $<$<CONFIG:Debug>:VSTGUI_LIVE_EDITING=1>)
    
        smtg_set_platform_ios(${target})
        set_target_properties(${target} PROPERTIES 
            XCODE_ATTRIBUTE_DEVELOPMENT_TEAM ${SMTG_IOS_DEVELOPMENT_TEAM}
            XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "iPhone Developer"
            XCODE_ATTRIBUTE_ENABLE_BITCODE "NO"
        )

        get_target_property(PLUGIN_PACKAGE_PATH ${target} SMTG_PLUGIN_PACKAGE_PATH)
        add_custom_command(TARGET ${target}
            COMMENT "Codesign"
            POST_BUILD
            COMMAND codesign --force --verbose --sign "${sign_identity}"
                "${PLUGIN_PACKAGE_PATH}"
        )

    endif()
endfunction()

function(smtg_add_vst3_resource target input_file)
    smtg_add_plugin_resource(${target} ${input_file})
endfunction()

function(smtg_add_vst3_snapshot target snapshot)
    smtg_add_plugin_snapshot(${target} ${snapshot})
endfunction()
