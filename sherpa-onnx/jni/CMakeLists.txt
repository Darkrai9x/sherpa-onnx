include_directories(${PROJECT_SOURCE_DIR})

if(NOT DEFINED ANDROID_ABI)
  if(NOT DEFINED ENV{JAVA_HOME})
    message(FATAL_ERROR "Please set the environment variable JAVA_HOME")
  endif()
  include_directories($ENV{JAVA_HOME}/include)
  include_directories($ENV{JAVA_HOME}/include/linux)
  include_directories($ENV{JAVA_HOME}/include/darwin)
  include_directories($ENV{JAVA_HOME}/include/win32)
endif()

set(sources
  common.cc
  jni.cc
  offline-stream.cc
  online-stream.cc
  version.cc
  voice-activity-detector.cc
  wave-reader.cc
  wave-writer.cc
)

if(SHERPA_ONNX_ENABLE_ASR)
  list(APPEND sources
    offline-recognizer.cc
    online-recognizer.cc
    spoken-language-identification.cc
  )
endif()

if(SHERPA_ONNX_ENABLE_KWS)
  list(APPEND sources
    keyword-spotter.cc
  )
endif()

if(SHERPA_ONNX_ENABLE_AUDIO_TAGGING)
  list(APPEND sources
    audio-tagging.cc
  )
endif()

if(SHERPA_ONNX_ENABLE_PUNCTUATION)
  list(APPEND sources
    offline-punctuation.cc
    online-punctuation.cc
  )
endif()

if(SHERPA_ONNX_ENABLE_DENOISER)
  list(APPEND sources
    offline-speech-denoiser.cc
    online-speech-denoiser.cc
    speech-denoiser.cc
  )
endif()

if(SHERPA_ONNX_ENABLE_SPEAKER_ID)
  list(APPEND sources
    speaker-embedding-extractor.cc
    speaker-embedding-manager.cc
  )
endif()

if(SHERPA_ONNX_ENABLE_TTS)
  list(APPEND sources
    offline-tts.cc
  )
endif()

if(SHERPA_ONNX_ENABLE_SPEAKER_DIARIZATION)
  list(APPEND sources
    offline-speaker-diarization.cc
  )
endif()

add_library(sherpa-onnx-jni SHARED ${sources})

target_compile_definitions(sherpa-onnx-jni PRIVATE SHERPA_ONNX_BUILD_SHARED_LIBS=1)
target_compile_definitions(sherpa-onnx-jni PRIVATE SHERPA_ONNX_BUILD_MAIN_LIB=1)

if(ANDROID OR (UNIX AND NOT APPLE))
  set_target_properties(sherpa-onnx-jni PROPERTIES
    LINK_FLAGS "-Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/sherpa-onnx-symbols.lds"
  )
elseif(APPLE)
  set_target_properties(sherpa-onnx-jni PROPERTIES
    LINK_FLAGS "-Wl,-exported_symbols_list,${CMAKE_CURRENT_SOURCE_DIR}/sherpa-onnx-symbols.exp"
  )
endif()

target_link_libraries(sherpa-onnx-jni sherpa-onnx-core)
install(TARGETS sherpa-onnx-jni DESTINATION lib)
