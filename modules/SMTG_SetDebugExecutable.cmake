
function(smtg_set_debug_executable target executable)
    if(CMAKE_GENERATOR STREQUAL Xcode)
        set_target_properties(${target}
            PROPERTIES
                XCODE_GENERATE_SCHEME       YES
                XCODE_SCHEME_EXECUTABLE     "${executable}"
        )
        if(ARGC GREATER 2 AND ARGV2)
            set_target_properties(${target}
                PROPERTIES
                    XCODE_SCHEME_ARGUMENTS  "${ARGV2}"
            )
        endif()
    endif()

    if(MSVC)
        set_target_properties(${target}
            PROPERTIES
                VS_DEBUGGER_COMMAND         "${executable}"
        )
        if(ARGC GREATER 2 AND ARGV2)
            set_target_properties(${target}
                PROPERTIES
                    VS_DEBUGGER_COMMAND_ARGUMENTS "${ARGV2}"
            ) 
        endif()
    endif(MSVC)
endfunction(smtg_set_debug_executable)
