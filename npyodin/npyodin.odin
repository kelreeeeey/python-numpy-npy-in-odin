package nparray_decoder

import "core:os"
import "core:io"
import "core:bufio"
import "core:mem"

// TODO (Rey): Probably reorganize and change the naming
// convention for these unions and structs
ReadFileError :: union {
	OpenError,
	ReaderCreationError,
	ReaderReadByteError,
	mem.Allocator_Error,

	// Numpy Headers Error
	InvalidHeaderError,
	InvalidVersionError,
	InvalidHeaderLengthError,
	RecreateArrayError,
	ParseError,
}

OpenError :: struct {
	file_name: string,
	error: os.Errno,
}

ReaderCreationError :: struct {
	file_name: string,
	stream: io.Stream,
}

ReaderReadByteError :: struct {
	file_name: string,
	reader: bufio.Reader,
}

InvalidHeaderError :: struct {
	message: string,
}

InvalidVersionError :: struct {
	message: string,
	version: [2]u8,
}

InvalidHeaderLengthError :: struct {
	message: string,
	length: [2]u8,
}

ParseError :: enum {
	None,
	Invalid_Descriptor,
	Malformed_Header,
	Shape_Parse_Failed,
}

RecreateArrayError :: struct {
	message: string,
}
