
# Detect the platform which cmake builds for.
#
# The detected platform var is stored within the internal cache of cmake in order to make it
# available globally.
set(SMTG_PLATFORM_DETECTION_COMMENT "The platform which was detected my SMTG")

macro(smtg_detect_platform)
	if(APPLE)
		set(SMTG_MAC TRUE CACHE INTERNAL ${SMTG_PLATFORM_DETECTION_COMMENT})
	elseif(UNIX OR ANDROID_PLATFORM)
		set(SMTG_LINUX TRUE CACHE INTERNAL ${SMTG_PLATFORM_DETECTION_COMMENT})
	elseif(WIN32)
		set(SMTG_WIN TRUE CACHE INTERNAL ${SMTG_PLATFORM_DETECTION_COMMENT})
	endif()
endmacro()