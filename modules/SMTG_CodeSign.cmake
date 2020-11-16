
if(XCODE)
    option(SMTG_DISABLE_CODE_SIGNING "Disable All Code Signing" OFF)
endif()

function(smtg_codesign_target target)
    if(XCODE AND (NOT SMTG_DISABLE_CODE_SIGNING))
        if(ARGC GREATER 2)
            set(team "${ARGV1}")
            set(identity "${ARGV2}")
            message(STATUS "Codesign ${target} with team '${team}' and identity '${identity}")
            set(SMTG_CODESIGN_ATTRIBUTES 
                XCODE_ATTRIBUTE_DEVELOPMENT_TEAM ${team}
                XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "${identity}"
            )
        else()
            message(STATUS "Codesign ${target} for local machine only")
            set(SMTG_CODESIGN_ATTRIBUTES 
                XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "-"
            )
        endif()
        set_target_properties(${target} PROPERTIES ${SMTG_CODESIGN_ATTRIBUTES})
    endif()
endfunction()
