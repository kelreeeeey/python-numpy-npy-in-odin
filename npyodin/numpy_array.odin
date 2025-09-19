package nparray_decoder

import "base:runtime"
import "base:intrinsics"
import "core:fmt"
import "core:math"
import "core:os"
import "core:io"
import "core:bufio"
import "core:mem"
import "core:c"
import "core:strings"
import "core:slice"
import "core:strconv"
import "core:encoding/endian"


// from https://github.com/numpy/numpy/blob/main/numpy/lib/_format_impl.py
MAGIC_HEADER :: []u8{0x93, 'N', 'U', 'M', 'P', 'Y'}
MAGIG_LEN := len(MAGIC_HEADER)
NPY_BUFFER_READER_SIZE :: 1024

@(private = "file")
get_alignment :: proc(np_type_char: string) -> uint {
	alignment : uint
	switch np_type_char {
		// bool, ('?', dtype('bool'))
		// byte, ('b', dtype('int8'))
		// int8, ('b', dtype('int8'))
		case "i1" : alignment = 1
		// short, ('h', dtype('int16'))
		// int16, ('h', dtype('int16'))
		case "i2" : alignment = 2
		// intc, ('i', dtype('int32'))
		// int, ('l', dtype('int32'))
		// int32, ('l', dtype('int32'))
		case "i4" : alignment = 4
		// longlong, ('q', dtype('int64'))
		// int64, ('q', dtype('int64'))
		case "i8" : alignment = 8
		// uint8, ('B', dtype('uint8'))
		// ubyte, ('B', dtype('uint8'))
		case "u1" : alignment = 1
		// ushort, ('H', dtype('uint16'))
		case "u2" : alignment = 2
		// uintc, ('I', dtype('uint32'))
		case "u4" : alignment = 4
		// ulonglong, ('Q', dtype('uint64'))
		case "u8" : alignment = 8
		// half, ('e', dtype('float16'))
		// float16, ('e', dtype('float16'))
		case "f2" : alignment = 2
		// single, ('f', dtype('float32'))
		// float32, ('f', dtype('float32'))
		case "f4" : alignment = 4
		// double, ('d', dtype('float64'))
		// longdouble, ('g', dtype('float64'))
		// float64, ('d', dtype('float64'))
		case "f8" : alignment = 8
		// csingle, ('F', dtype('complex64'))
		// complex64, ('F', dtype('complex64'))
		case "c8" : alignment = 4
		// cdouble, ('D', dtype('complex127'))
		// clongdouble, ('G', dtype('complex128'))
		// complex128, ('D', dtype('complex128'))
		case "c16": alignment = 8
	}
	return alignment
}

// TypeAlignment := map[string]DType {
// 	"b1"  = DType{b8, 1}, // bool, ('?', dtype('bool'))
// 	"i1"  = DType{i8, 1}, // byte, ('b', dtype('int8')) // int8, ('b', dtype('int8')) // uint8, ('B', dtype('uint8'))
// 	"u1"  = DType{i8, 1}, // ubyte, ('B', dtype('uint8'))
// 	"i2"  = DType{i16, 2}, // short, ('h', dtype('int16')) // int16, ('h', dtype('int16'))
// 	"u2"  = DType{u16, 2}, // ushort, ('H', dtype('uint16'))
// 	"i4"  = DType{i32, 4}, // intc, ('i', dtype('int32')) // int, ('l', dtype('int32')) // int32, ('l', dtype('int32'))
// 	"u4"  = DType{u32, 4}, // uintc, ('I', dtype('uint32'))
// 	"i8"  = DType{i64, 8}, // longlong, ('q', dtype('int64')) // int64, ('q', dtype('int64'))
// 	"u8"  = DType{u16, 8}, // ulonglong, ('Q', dtype('uint64'))
// 	"f2"  = DType{f16, 2}, // half, ('e', dtype('float16')) // float16, ('e', dtype('float16'))
// 	"f4"  = DType{f32, 4}, // single, ('f', dtype('float32')) // float32, ('f', dtype('float32'))
// 	"f8"  = DType{f64, 8}, // double, ('d', dtype('float64')) // longdouble, ('g', dtype('float64')) // float64, ('d', dtype('float64'))
// 	"c8"  = DType{complex32, 4}, // csingle, ('F', dtype('complex64')) complex64, ('F', dtype('complex64'))
// 	"c16" = DType{complex64, 8}, // cdouble, ('D', dtype('complex128')) // clongdouble, ('G', dtype('complex128')) complex128, ('D', dtype('complex128'))}
// }
// DType :: struct($T: typeid) where intrinsics.type_is_numeric(T) || T == b8 {
// 	t  : T,
// 	allignment : uint8,
// }

ArrayTypes :: union {
	b8,
	u8,
	i8,
	i16,
	u16,
	i32,
	u32,
	i64,
	u64,
	f16,
	f32,
	f64,
	f16be,
	f16le,
	complex32,
	complex64,
}


NumpyHeader :: struct #packed {
	magic         : string,
	version       : [2]u8, // [major, minor]
	header_length : u16le,
	descr         : string,
	fortran_order : bool,
	shape         : []uint,
	endianess     : endian.Byte_Order,
}

NDArray :: struct {
	data      : []ArrayTypes,
	alignment : uint,
	shape     : []uint,
	size      : uint,
	length    : uint
}

// inspired by @AriaGhora, from https://github.com/ariaghora/anvil
// Compute total size of an tensor by multiplying dimensions in shape
shape_to_size :: #force_inline proc(shape: []uint) -> uint {
	return math.prod(shape)
}

delete_ndarray :: proc(nd: ^NDArray) {
	delete(nd.data)
	delete(nd.shape)
}

delete_header :: proc(h: ^NumpyHeader) {
	delete(h.magic)
	delete(h.shape)
	delete(h.descr)
}

// inspired by @AriaGhora, from https://github.com/ariaghora/anvil
array_alloc :: proc(
	$T: typeid,
	shape: []uint,
	alignment: uint,
	allocator := context.allocator,
	loc := #caller_location,
) -> (
	res: ^NDArray,
) where intrinsics.type_is_numeric(T) || T == b8 {

	res = new(NDArray, allocator)

	length : uint
	if len(shape) > 1 { length = shape_to_size(cast([]uint)shape) }
	else              { length = shape[0] }

	res.data = make([]ArrayTypes, length, allocator)
	res.shape = make([]uint, len(shape), allocator)
	res.length = length
	res.alignment = alignment
	res.size = alignment * length
	// initialize shape and strides
	copy(res.shape, shape)
	return res
}

load_npy :: proc(
	file_name: string,
	bufreader_size: int = NPY_BUFFER_READER_SIZE,
	allocator:= context.allocator,
	loc := #caller_location,
) -> (
	NumpyHeader,
	^NDArray,
	ReadFileError
) {
	// create an handler
	npy_header: NumpyHeader
	error: ReadFileError
	handle, open_error := os.open(file_name, os.O_RDONLY)
	if open_error != os.ERROR_NONE do return npy_header, nil, OpenError{file_name, open_error}

	// create a stream
	stream := os.stream_from_handle(handle)

	// create a reader
	reader, ok := io.to_reader(stream)
	if !ok do return npy_header, nil, ReaderCreationError{file_name, stream}

	// define bufio_reader
	bufio_reader : bufio.Reader
	bufio.reader_init(&bufio_reader, reader, bufreader_size, allocator)
	bufio_reader.max_consecutive_empty_reads = 1

	magic : [6]u8
	// read magic magic
	read, rerr := io.read(reader, magic[:], &MAGIG_LEN)
	if rerr != nil || read != 6 do return npy_header, nil, InvalidHeaderError{"Invalid magic number"}
	if !slice.equal(magic[:], MAGIC_HEADER) do return npy_header, nil, InvalidHeaderError{"Invalid magic number"}

	clone_err : mem.Allocator_Error
	npy_header.magic, clone_err = strings.clone_from_bytes(magic[:])
	if clone_err != nil do return npy_header, nil, nil

	// read version
	version : [2]u8
	read, rerr = io.read(reader, version[:])
	if rerr != nil || read != 2 do return npy_header, nil, InvalidVersionError{"Invalid version", version}
	npy_header.version = version

	header_lenght : [2]u8
	// read header length
	read, rerr = io.read(reader, header_lenght[:])
	if rerr != nil || read != 2 do return npy_header, nil, InvalidHeaderLengthError{"Broken header length", header_lenght}
	npy_header.header_length = transmute(u16le)header_lenght

	// TODO (Rey): not sure about keeping this len_header thingy
	len_header := cast(int)transmute(u16le)header_lenght
	header_desc := make([]u8, len_header)
	read, rerr = io.read(reader, header_desc[:])
	if rerr != nil || read != len_header do return npy_header, nil, InvalidHeaderLengthError{"Broken header length", header_lenght}

	// parsed_header : Descriptor
	parr_err := parse_npy_header(&npy_header, string( header_desc ))
	if parr_err != nil do return npy_header, nil, parr_err

	type_char := npy_header.descr[1:]
	alignment := get_alignment(type_char)
	out : ^NDArray
	switch type_char {
	case "b1"  : out = array_alloc(b8, npy_header.shape, alignment, allocator, loc)
	case "u1"  : out = array_alloc(i8, npy_header.shape, alignment, allocator, loc)
	case "i1"  : out = array_alloc(i8, npy_header.shape, alignment, allocator, loc)
	case "i2"  : out = array_alloc(i16, npy_header.shape, alignment, allocator, loc)
	case "u2"  : out = array_alloc(u16, npy_header.shape, alignment, allocator, loc)
	case "u4"  : out = array_alloc(u32, npy_header.shape, alignment, allocator, loc)
	case "i4"  : out = array_alloc(i32, npy_header.shape, alignment, allocator, loc)
	case "u8"  : out = array_alloc(u16, npy_header.shape, alignment, allocator, loc)
	case "i8"  : out = array_alloc(i64, npy_header.shape, alignment, allocator, loc)
	case "f2"  : out = array_alloc(f16, npy_header.shape, alignment, allocator, loc)
	case "c8"  : out = array_alloc(complex32, npy_header.shape, alignment, allocator, loc)
	case "c16" : out = array_alloc(complex64, npy_header.shape, alignment, allocator, loc)
	case "f4"  : out = array_alloc(f32, npy_header.shape, alignment, allocator, loc)
	case "f8"  : out = array_alloc(f64, npy_header.shape, alignment, allocator, loc)
	}

	ok = recreate_array(
		&npy_header,
		&bufio_reader,
		out,
		allocator = allocator
	)
	if !ok do return npy_header, nil, RecreateArrayError{"Cannot parse data array, possible curropted data type is not supported yet"}
	return npy_header, out, nil
}

@(private = "file")
recreate_array :: proc(
	np_header: ^NumpyHeader,
	reader: ^bufio.Reader,
	ndarray : ^NDArray,
	allocator := context.allocator,
	loc := #caller_location,
) -> bool {

	count     := uint(0)
	i         := uint(0)
	n_elem    := ndarray.size
	alignment := ndarray.alignment
	endianess := np_header.endianess

	read_bytes_err      : io.Error
	raw_data            : u8   // if alignment == 1
	raw_bytes_pos       : int  // if alignment > 1

	// make array
	raw_bytes_container := make([]u8, n_elem, allocator=allocator, loc=loc)
	// defer delete(raw_bytes_container)
	raw_bytes_pos, read_bytes_err = bufio.reader_read(reader, raw_bytes_container[:])

    switch np_header.descr[1:] {
	case "b1" :
		#no_bounds_check for ; i < n_elem; i += alignment {
			ndarray.data[count] = cast(b8)raw_bytes_container[i]
			count += 1
		}
		return true

	case "u1" :
		#no_bounds_check for ; i < n_elem; i += alignment {
			ndarray.data[count] = cast(i8)raw_bytes_container[i]
			count += 1
		}
		return true

	case "i1" :
		#no_bounds_check for ; i < n_elem; i += alignment {
			ndarray.data[count] = cast(i8)raw_bytes_container[i]
			count += 1
		}
		return true

	case "i2" :
		casted_data : i16
		cast_ok : bool = true
		#no_bounds_check for ; i < n_elem; i += alignment {
			casted_data, cast_ok = endian.get_i16(raw_bytes_container[i:i+alignment], endianess)
			if !cast_ok do break
			ndarray.data[count] = cast(i16)casted_data
			count += 1
		}
		return cast_ok

	case "u2" :
		casted_data : u16
		cast_ok : bool = true
		#no_bounds_check for ; i < n_elem; i += alignment {
			casted_data, cast_ok = endian.get_u16(raw_bytes_container[i:i+alignment], endianess)
			if !cast_ok do break
			ndarray.data[count] = cast(i16)casted_data
			count += 1
		}
		return cast_ok

	case "u4" :
		casted_data : u32
		cast_ok : bool = true
		#no_bounds_check for ; i < n_elem; i += alignment {
			casted_data, cast_ok = endian.get_u32(raw_bytes_container[i:i+alignment], endianess)
			if !cast_ok do break
			ndarray.data[count] = casted_data
			count += 1
		}
		return cast_ok

	case "i4" :
		casted_data : i32
		cast_ok : bool = true
		#no_bounds_check for ; i < n_elem; i += alignment {
			casted_data, cast_ok := endian.get_i32(raw_bytes_container[i:i+alignment], endianess)
			if !cast_ok do break
			ndarray.data[count] = casted_data
			count += 1
		}
		return cast_ok

	case "u8" :
		casted_data : u16
		cast_ok : bool = true
		#no_bounds_check for ; i < n_elem; i += alignment {
			casted_data, cast_ok = endian.get_u16(raw_bytes_container[i:i+alignment], endianess)
			if !cast_ok do break
			ndarray.data[count] = casted_data
			count += 1
		}
		return cast_ok

	case "i8" :
		casted_data : i64
		cast_ok : bool = true
		#no_bounds_check for ; i < n_elem; i += alignment {
			casted_data, cast_ok := endian.get_i64(raw_bytes_container[i:i+alignment], endianess)
			if !cast_ok do break
			ndarray.data[count] = casted_data
			count += 1
		}
		return cast_ok

	case "f2" :
		casted_data : f16
		cast_ok : bool = true
		#no_bounds_check for ; i < n_elem; i += alignment {
			casted_data, cast_ok := endian.get_f16(raw_bytes_container[i:i+alignment], endianess)
			if !cast_ok do break
			ndarray.data[count] = casted_data
			count += 1
		}
		return cast_ok

	case "c8" :
		casted_data : f32
		cast_ok : bool = true
		#no_bounds_check for ; i < n_elem; i += alignment {
			casted_data, cast_ok := endian.get_f32(raw_bytes_container[i:i+alignment], endianess)
			if !cast_ok do break
			ndarray.data[count] = cast(complex32)casted_data
			count += 1
		}
		return cast_ok

	case "c16" :
		casted_data : f64
		cast_ok : bool = true
		#no_bounds_check for ; i < n_elem-uint(alignment/2); i += ndarray.alignment {
			casted_data, cast_ok := endian.get_f64(raw_bytes_container[i:i+alignment], endianess)
			if !cast_ok do break
			ndarray.data[count] = cast(complex64)casted_data
			count += 1
		}
		return cast_ok

	case "f4" :
		casted_data : f32
		cast_ok : bool = true
		#no_bounds_check for ; i < n_elem; i += alignment {
			casted_data, cast_ok := endian.get_f32(raw_bytes_container[i:i+alignment], endianess)
			if !cast_ok do break
			ndarray.data[count] = cast(f32)casted_data
			count += 1
		}
		return cast_ok

	case "f8" :
		casted_data : f64
		cast_ok : bool = true
		#no_bounds_check for ; i < n_elem; i += alignment {
			casted_data, cast_ok := endian.get_f64(raw_bytes_container[i:i+alignment], endianess)
			if !cast_ok do break
			ndarray.data[count] = cast(f64)casted_data
			count += 1

		// #no_bounds_check for ; i < n_elem; i += uint(4)*alignment {
			// ii := uint(0)
			// #unroll for ii in 1 ..< 5 {
			// 	casted_data, cast_ok := endian.get_f64(
			// 		raw_bytes_container[i+(alignment * uint(ii-1)):i+(alignment * uint(ii))],
			// 		endianess)
			// 	if !cast_ok do break
			// 	ndarray.data[count] = cast(f64)casted_data
			// 	count += 1
			// }

		}
		return cast_ok
    }
    return false
}

@(private = "file")
parse_npy_header :: proc(
	h: ^NumpyHeader,
	header: string,
	allocator := context.allocator
) -> (err: ParseError) {

	// Clean up header string
	clean_header := strings.trim_space(header)
	is_alloc : bool
	// Replace single quotes
	clean_header, is_alloc = strings.replace(clean_header, "'", "\"", -1)
	clean_header, is_alloc = strings.replace(clean_header, "(", "[", -1)
	clean_header, is_alloc = strings.replace(clean_header, ")", "]", -1)

	// Enhanced descriptor parsing
	if descr_start := strings.index(clean_header, "\"descr\":"); descr_start != -1 {
		descr_start += 8 // exactly the length of ` "descr": `
		descr_end := strings.index_byte(clean_header[descr_start:], ',')
		if descr_end == -1 do return .NPY_Malformed_Header
		descr_str := strings.trim(clean_header[descr_start:descr_start+descr_end], " \"")
		// Handle native/byte-order-agnostic types
		switch {
		case strings.has_prefix(descr_str, "|"):
			h.endianess = endian.PLATFORM_BYTE_ORDER
			descr, clone_err := strings.clone(descr_str[:])
			h.descr = descr
		case strings.has_prefix(descr_str, "<") :
			// Existing endian-sensitive types
			h.endianess = endian.Byte_Order.Little
			descr, clone_err := strings.clone(descr_str[:])
			h.descr = descr
		case strings.has_prefix(descr_str, ">") :
			// Existing endian-sensitive types
			h.endianess = endian.Byte_Order.Big
			descr, clone_err := strings.clone(descr_str[:])
			h.descr = descr
		case: // Handle non-byte-ordered types
			h.endianess = endian.PLATFORM_BYTE_ORDER
			descr, clone_err := strings.clone(descr_str[:])
			h.descr = descr
		}
	}

	// Parse fortran_order
	if fo_start := strings.index(clean_header, "\"fortran_order\":"); fo_start != -1 {
		fo_start += 16  // Skip `"fortran_order": `
		fo_str := clean_header[fo_start:]
		h.fortran_order = strings.has_prefix(fo_str, "True")
	}

	// Parse shape tuple
	if shape_start := strings.index(clean_header, "\"shape\":"); shape_start != -1 {

		shape_start += 8  // Skip `"shape": `
		shape_end := strings.index_byte(clean_header[shape_start:], ']')

		if shape_end == -1 do return .NPY_Shape_Parse_Failed

		shape_str := clean_header[shape_start:shape_start+shape_end]
		shape_str = strings.trim_space(shape_str)
		shape_str = strings.trim(shape_str, "[]")

		// Split and parse integers
		parts := strings.split(shape_str, ",", allocator)
		defer delete(parts)
		h.shape = make([]uint, len(parts), allocator)

		count := uint(0)
		for part in parts {
			trimmed := strings.trim_space(part)
			if trimmed == "" { continue }
			value, ok := strconv.parse_int(trimmed)
			if !ok do return .NPY_Shape_Parse_Failed
			h.shape[count] = cast(uint)value
			count += 1
        }
		h.shape = h.shape[:count]
    }
    return nil
}
