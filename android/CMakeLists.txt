cmake_minimum_required(VERSION 3.4.1)

project(synclib_flutter)

# Add prebuilt synclib library
add_library(synclib STATIC IMPORTED)
set_target_properties(synclib PROPERTIES
    IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libsynclib.a
)

# Create dummy source file since we're using prebuilt library
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/dummy.c "")

# Define the shared library that will export synclib symbols
add_library(synclib_flutter SHARED ${CMAKE_CURRENT_BINARY_DIR}/dummy.c)

# Link with synclib using --whole-archive to ensure all symbols are exported
# Add 16 KB page size support
target_link_libraries(synclib_flutter
    -Wl,--whole-archive
    synclib
    -Wl,--no-whole-archive
    -Wl,-z,max-page-size=16384
    log
)
