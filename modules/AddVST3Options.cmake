
include(SetupVST3LibraryDefaultPath)
include(AddCommonOptions)
include(SMTG_Platform_Windows)

# Add VSTGUI
option(SMTG_ADD_VSTGUI "Add VSTGUI Support" ON)

# Add VST3 Plug-ins Samples
option(SMTG_ADD_VST3_PLUGINS_SAMPLES "Add VST3 Plug-ins Samples to the solution" ON)
# do not build AGain VST 2 by default
option(SMTG_CREATE_VST2_AGAIN_SAMPLE_VERSION "Legacy: Create the VST2 version of the Sample Plug-in AGain, be sure that you have copied the VST2 interfaces into the folder VST_SDK/VST3_SDK/pluginterfaces/vst2.x" OFF)

# Add VST3 Hosting Samples
option(SMTG_ADD_VST3_HOSTING_SAMPLES "Add VST3 Hosting Samples to the solution" ON)

# Run the Validator after each new compilation of VST3 Plug-ins
option(SMTG_RUN_VST_VALIDATOR "Run VST validator on VST3 Plug-ins" ON)

# Enable Sample audioHost (based on Jack Audio)
if (SMTG_LINUX)
    option(SMTG_ENABLE_USE_OF_JACK "Enable Use of Jack" ON)
else()
    # not yet tested on Windows and Mac
    option(SMTG_ENABLE_USE_OF_JACK "Enable Use of Jack" OFF)
endif()

# here you can define the VST3 Plug-ins folder (it will be created)
smtg_get_default_vst3_path(DEFAULT_VST3_FOLDER)
set(SMTG_PLUGIN_TARGET_PATH "${DEFAULT_VST3_FOLDER}" CACHE PATH "Here you can redefine the VST3 Plug-ins folder")
if (NOT ${SMTG_PLUGIN_TARGET_PATH} STREQUAL "")
    if(NOT EXISTS ${SMTG_PLUGIN_TARGET_PATH})
        if(SMTG_WIN)
            smtg_create_directory_as_admin_win (${SMTG_PLUGIN_TARGET_PATH})
        else()
            file(MAKE_DIRECTORY ${SMTG_PLUGIN_TARGET_PATH})
        endif()
    endif()
    if(EXISTS ${SMTG_PLUGIN_TARGET_PATH})
        message(STATUS "SMTG_PLUGIN_TARGET_PATH is set to : " ${SMTG_PLUGIN_TARGET_PATH})
    else()
        message(STATUS "SMTG_PLUGIN_TARGET_PATH is not set!")
    endif()
endif()

# Here you can add Your own VST3 Plug-ins folder (by default we add the HelloWorld included in my_plugins folder)
set(SMTG_MYPLUGINS_SRC_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../my_plugins" CACHE PATH "Here you can add Your VST3 Plug-ins folder")

if(EXISTS ${SMTG_MYPLUGINS_SRC_PATH})
    message(STATUS "SMTG_MYPLUGINS_SRC_PATH is set to : " ${SMTG_MYPLUGINS_SRC_PATH})
else()
    message(STATUS "SMTG_MYPLUGINS_SRC_PATH is not set. If you want to add your own Plug-ins folder, specify it!")
endif()

if(SMTG_WIN)
    set(DEFAULT_ICON_PATH ${CMAKE_CURRENT_SOURCE_DIR}/doc/artwork/VST_Logo_Steinberg.ico)
    set(MSG_ICON_PATH "Path to the package icon (VST_Logo_Steinberg.ico) (Windows only)")
    if(EXISTS ${DEFAULT_ICON_PATH})
        set(SMTG_PACKAGE_ICON_PATH ${DEFAULT_ICON_PATH} CACHE FILEPATH ${MSG_ICON_PATH})
        message(STATUS "SMTG_PACKAGE_ICON_PATH is set to : " ${SMTG_PACKAGE_ICON_PATH})
    else()
        set(SMTG_PACKAGE_ICON_PATH "" CACHE FILEPATH ${MSG_ICON_PATH})
        message(STATUS "SMTG_PACKAGE_ICON_PATH is not set to (as expected) : " ${DEFAULT_ICON_PATH})
    endif()
endif()

if(SMTG_MAC)
    set(SMTG_CODE_SIGN_IDENTITY_MAC "Mac Developer" CACHE STRING "macOS Code Sign Identity")
    set(SMTG_CODE_SIGN_IDENTITY_IOS "iPhone Developer" CACHE STRING "iOS Code Sign Identity")
    option(SMTG_AUV3_WRAPPER_EXTERNAL_PLUGIN_FACTORY "Use externally provided GetPluginFactory()" OFF)
endif()
