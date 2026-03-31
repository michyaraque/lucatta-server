find_package(Protobuf CONFIG QUIET)
if (NOT Protobuf_FOUND)
	find_package(Protobuf REQUIRED)
endif ()

add_library(appearances_proto ${CMAKE_CURRENT_SOURCE_DIR}/appearances.proto)
target_include_directories(appearances_proto PUBLIC ${CMAKE_CURRENT_BINARY_DIR})

if (TARGET protobuf::libprotobuf)
	target_link_libraries(appearances_proto PUBLIC protobuf::libprotobuf)
else ()
	target_include_directories(appearances_proto PUBLIC ${Protobuf_INCLUDE_DIRS})
	target_link_libraries(appearances_proto PUBLIC ${Protobuf_LIBRARIES})
endif ()

if (COMMAND protobuf_generate)
	protobuf_generate(
		TARGET appearances_proto
		LANGUAGE cpp
	)
else ()
	protobuf_generate_cpp(APPEARANCES_PROTO_SRCS APPEARANCES_PROTO_HDRS ${CMAKE_CURRENT_SOURCE_DIR}/appearances.proto)
	target_sources(appearances_proto PRIVATE ${APPEARANCES_PROTO_SRCS} ${APPEARANCES_PROTO_HDRS})
endif ()
