
#-------------------------------------------------------------------------------
# Includes
#-------------------------------------------------------------------------------
include(SMTG_SetupVST3LibraryDefaultPath)
include(SMTG_AddCommonOptions)
include(SMTG_Platform_Windows)

# here you can define the VST3 Plug-ins folder (it will be created)
smtg_get_default_vst3_path(DEFAULT_VST3_FOLDER)
set(SMTG_PLUGIN_TARGET_PATH "${DEFAULT_VST3_FOLDER}" CACHE PATH "Here you can redefine the VST3 Plug-ins folder")
if(NOT ${SMTG_PLUGIN_TARGET_PATH} STREQUAL "" AND SMTG_CREATE_PLUGIN_LINK)
    if(NOT EXISTS ${SMTG_PLUGIN_TARGET_PATH})
        message(STATUS "[SMTG] Create folder: " ${SMTG_PLUGIN_TARGET_PATH})
        if(SMTG_WIN)
            smtg_create_directory_as_admin_win(${SMTG_PLUGIN_TARGET_PATH})
        else()
            file(MAKE_DIRECTORY ${SMTG_PLUGIN_TARGET_PATH})
        endif(SMTG_WIN)
    endif(NOT EXISTS ${SMTG_PLUGIN_TARGET_PATH})
endif(NOT ${SMTG_PLUGIN_TARGET_PATH} STREQUAL "" AND SMTG_CREATE_PLUGIN_LINK)
if(EXISTS ${SMTG_PLUGIN_TARGET_PATH})
    message(STATUS "[SMTG] SMTG_PLUGIN_TARGET_PATH is set to: " ${SMTG_PLUGIN_TARGET_PATH})
else()
    message(STATUS "[SMTG] SMTG_PLUGIN_TARGET_PATH is not set!")
endif(EXISTS ${SMTG_PLUGIN_TARGET_PATH})

if(SMTG_MAC)
    set(SMTG_CODE_SIGN_IDENTITY_MAC "Mac Developer" CACHE STRING "macOS Code Sign Identity")
    set(SMTG_CODE_SIGN_IDENTITY_IOS "iPhone Developer" CACHE STRING "iOS Code Sign Identity")
endif(SMTG_MAC)
