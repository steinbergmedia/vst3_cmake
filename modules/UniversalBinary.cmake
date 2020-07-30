
if(SMTG_MAC)
  if (XCODE_VERSION VERSION_GREATER_EQUAL 12)
    option(SMTG_BUILD_UNIVERSAL_BINARY "Build universal binary (x86_64 & arm64)" OFF)
  else()
    option(SMTG_BUILD_UNIVERSAL_BINARY "Build universal binary (32 & 64 bit)" OFF)
  endif()
endif()

#-------------------------------------------------------------------------------
# smtg_setup_universal_binary
#-------------------------------------------------------------------------------
function(smtg_setup_universal_binary target)
    if(SMTG_MAC)
        if(SMTG_BUILD_UNIVERSAL_BINARY)
          if (XCODE_VERSION VERSION_GREATER_EQUAL 12)
            set_target_properties(${target} PROPERTIES XCODE_ATTRIBUTE_OSX_ARCHITECTURES "x86_64;arm64;arm64e")
            set_target_properties(${target} PROPERTIES XCODE_ATTRIBUTE_ARCHS "$(ARCHS_STANDARD_64_BIT)")
          else()
            set_target_properties(${target} PROPERTIES XCODE_ATTRIBUTE_OSX_ARCHITECTURES "x86_64;i386")
            set_target_properties(${target} PROPERTIES XCODE_ATTRIBUTE_ARCHS "$(ARCHS_STANDARD_32_64_BIT)")
          endif()
          set_target_properties(${target} PROPERTIES XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH "$<$<CONFIG:Debug>:YES>$<$<CONFIG:Release>:NO>")
        endif()
    endif()
endfunction()
