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
import "core:strconv"
import "core:encoding/endian"


// from https://github.com/numpy/numpy/blob/main/numpy/lib/_format_impl.py
MAGIC :: []u8{0x93, 'N', 'U', 'M', 'P', 'Y'}
MAGIG_LEN := len(MAGIC)
DELIM : byte = '\n'

Array_b8 :: []b8
Array_u8 :: []u8
Array_i8 :: []i8

Array_i16 :: []i16
Array_u16 :: []u16

Array_i32 :: []i32
Array_u32 :: []u32

Array_i64 :: []i64
Array_u64 :: []u64

Array_f16 :: []f16
Array_f32 :: []f32
Array_f64 :: []f64
Array_f16be :: []f16be
Array_f16le :: []f16le

Array_c8 :: []complex32
Array_c16 :: []complex64

ArrayTypes :: union {
    Array_b8,
    Array_u8,
    Array_i8,
    Array_i16,
    Array_u16,
    Array_i32,
    Array_u32,
    Array_i64,
    Array_u64,
    Array_f16,
    Array_f32,
    Array_f64,
    Array_f16be,
    Array_f16le,
    Array_c8,
    Array_c16,
}

NumpySaveVersion :: struct {
    maj: u8,
    min: u8
}

Descriptor :: struct {
    descr: string,
    fortran_order: bool,
    shape: []uint,
    endianess: endian.Byte_Order,
}

NumpyHeader :: struct #packed {
    magic: string,
    version: NumpySaveVersion,
    header_length: u16le,
    header: Descriptor,
}

NDArray :: struct {
    data : ArrayTypes,
    size : uint,
    length : uint
}

// Compute total size of an tensor by multiplying dimensions in shape
shape_to_size :: #force_inline proc(shape: []uint) -> uint {
	return math.prod(shape)
}


delete_ndarray :: proc(nd: ^NDArray) {
    switch arr in nd.data {
    case Array_b8:    delete(arr)
    case Array_u8:    delete(arr)
    case Array_i8:    delete(arr)
    case Array_i16:   delete(arr)
    case Array_u16:   delete(arr)
    case Array_i32:   delete(arr)
    case Array_u32:   delete(arr)
    case Array_i64:   delete(arr)
    case Array_u64:   delete(arr)
    case Array_f16:   delete(arr)
    case Array_f32:   delete(arr)
    case Array_f64:   delete(arr)
    case Array_f16be: delete(arr)
    case Array_f16le: delete(arr)
    case Array_c8: delete(arr)
    case Array_c16: delete(arr)
    }
}

delete_header :: proc(h: ^NumpyHeader) {
    delete (h.magic)
    delete (h.header.shape)
    delete (h.header.descr)
}

load_npy :: proc(
    file_name: string,
    bufreader_size: int = 1024,
	delimiter: byte = DELIM,
    allocator:= context.allocator) -> (

    npy_header: NumpyHeader,
    lines:  NDArray,
    error: ReadFileError ) {

    // create an handler
    handle, open_error := os.open(file_name, os.O_RDONLY)
    if open_error != os.ERROR_NONE do return npy_header, lines, OpenError{file_name, open_error}

    // create a stream
    stream := os.stream_from_handle(handle)

    // create a reader
    reader, ok := io.to_reader(stream)
    if !ok do return npy_header, lines, ReaderCreationError{file_name, stream}

    // define bufio_reader
    bufio_reader : bufio.Reader
    bufio.reader_init(&bufio_reader, reader, bufreader_size, allocator)
    bufio_reader.max_consecutive_empty_reads = 1

    magic : [6]u8
    { // read magic magic
        read, rerr := io.read(reader, magic[:], &MAGIG_LEN)
        if rerr != nil || read != 6 do return npy_header, lines, InvalidHeaderError{"Invalid magic number"}
    }

    clone_err : mem.Allocator_Error
    npy_header.magic, clone_err = strings.clone_from_bytes(magic[:])
    if clone_err != nil do return npy_header, lines, nil

    { // read version
        version : [2]u8
        read, rerr := io.read(reader, version[:])
        if rerr != nil || read != 2 do return npy_header, lines, InvalidVersionError{"Invalid version", version}
        npy_header.version.maj = version[0]
        npy_header.version.min = version[1]
    }

    header_lenght : [2]u8
    { // read header length
        read, rerr := io.read(reader, header_lenght[:])
        if rerr != nil || read != 2 do return npy_header, lines, InvalidHeaderLengthError{"Broken header length", header_lenght}
        npy_header.header_length = transmute(u16le)header_lenght
    }

    len_header := cast(int)transmute(u16le)header_lenght
    header_desc := make([]u8, len_header)
    read, rerr := io.read(reader, header_desc[:])
    if rerr != nil || read != len_header do return npy_header, lines, nil

    parsed_header : Descriptor
    parr_err := parse_npy_header(&parsed_header, string( header_desc ))
    npy_header.header = parsed_header

    _lines := recreate_array(
		&npy_header,
		&bufio_reader,
		&lines,
		delimiter = delimiter,
		allocator = allocator
	)
    if _lines == nil do return npy_header, lines, nil
    lines.data = _lines
    return npy_header, lines, nil
	if !ok do return npy_header, nil, RecreateArrayError{"Cannot parse data array, possible curropted data type is not supported yet"}
}

@(private = "file")
recreate_array :: proc(
    np_header: ^NumpyHeader,
    reader: ^bufio.Reader,
    ndarray : ^NDArray,
	delimiter: byte = DELIM,
    allocator := context.allocator ) -> ArrayTypes {

    data, read_bytes_err := bufio.reader_read_bytes(reader, cast(u8)delimiter, allocator)
    defer delete(data)
    n_elem := cast(uint)len(data)

	raw_length := np_header.header.shape
	if len(raw_length) > 1 {
		length := shape_to_size(cast([]uint)raw_length)
		ndarray.length = length
	} else {
		length := raw_length[0]
		ndarray.length = length
	}
	ndarray.size = cast(uint)len(data)/ndarray.length

	i := uint(0)
	count := uint(0)
    switch np_header.header.descr[1:] {

	case "b1" :
		_lines := make([]b8, ndarray.length, allocator)
		for ; i <n_elem; i += 1 {
			_lines[count] = cast(b8)data[i]
			count += 1
		}
		return _lines

	case "u1" :
		_lines := make([]i8, ndarray.length, allocator)
		for ; i <n_elem; i += 1 {
			_lines[count] = cast(i8)data[i]
			count += 1
		}
		return _lines

	case "i1" :
		_lines := make([]i8, ndarray.length, allocator)
		for ; i < n_elem; i += 1 {
			_lines[count] = cast(i8)data[i]
			count += 1
		}
		return _lines

	case "i2" :
		_lines := make([]i16, ndarray.length, allocator)
		for ; i < n_elem; i += ndarray.size {
			casted_data, cast_ok := endian.get_i16(data[i:i+ndarray.size], np_header.header.endianess)
			_lines[count] = cast(i16)casted_data
			count += 1
		}
		return _lines

	case "u2" :
		_lines := make([]u16, ndarray.length, allocator)
		for ; i < n_elem; i += ndarray.size {
			casted_data, cast_ok := endian.get_u16(data[i:i+ndarray.size], np_header.header.endianess)
			_lines[count] = cast(u16)casted_data
			count += 1
		}
		return _lines

	case "u4" :
		_lines := make([]u32, ndarray.length, allocator)
		for ; i < n_elem; i += ndarray.size {
			casted_data, cast_ok := endian.get_u32(data[i:i+ndarray.size], np_header.header.endianess)
			_lines[count] = cast(u32)casted_data
			count += 1
		}
		return _lines

	case "i4" :
		_lines := make([]i32, ndarray.length, allocator)
		for ; i < n_elem; i += ndarray.size {
			casted_data, cast_ok := endian.get_i32(data[i:i+ndarray.size], np_header.header.endianess)
			_lines[count] = cast(i32)casted_data
			count += 1
		}
		return _lines

	case "u8" :
		_lines := make([]u16, ndarray.length, allocator)
		for ; i < n_elem; i += ndarray.size {
			casted_data, cast_ok := endian.get_u16(data[i:i+ndarray.size], np_header.header.endianess)
			_lines[count] = cast(u16)casted_data
			count += 1
		}
		return _lines

	case "i8" :
		_lines := make([]i64, ndarray.length, allocator)
		for ; i < n_elem; i += ndarray.size {
			casted_data, cast_ok := endian.get_i64(data[i:i+ndarray.size], np_header.header.endianess)
			_lines[count] = cast(i64)casted_data
			count += 1
		}
		return _lines

	case "f2" :
		_lines := make([]f16, ndarray.length, allocator)
		for ; i < n_elem; i += ndarray.size {
			casted_data, cast_ok := endian.get_f16(data[i:i+ndarray.size], np_header.header.endianess)
			_lines[count] = cast(f16)casted_data
			count += 1
		}
		return _lines

	case "c8" :
		_lines := make([]complex32, ndarray.length, allocator)
		for ; i < n_elem; i += ndarray.size {
			casted_data, cast_ok := endian.get_f32(data[i:i+ndarray.size], np_header.header.endianess)
			_lines[count] = cast(complex32)casted_data
			count += 1
		}
		return _lines

	case "c16" :
		_lines := make([]complex64, ndarray.length, allocator)
		for ; i < n_elem-uint(ndarray.size/2); i += ndarray.size {
			casted_data, cast_ok := endian.get_f64(data[i:i+ndarray.size], np_header.header.endianess)
			_lines[count] = cast(complex64)casted_data
			count += 1
		}
		return _lines

	case "f4" :
		_lines := make([]f32, ndarray.length, allocator)
		for ; i < n_elem; i += ndarray.size {
			casted_data, cast_ok := endian.get_f32(data[i:i+ndarray.size], np_header.header.endianess)
			_lines[count] = cast(f32)casted_data
			count += 1
		}
		return _lines

	case "f8" :
		_lines := make([]f64, ndarray.length, allocator)
		for ; i < n_elem; i += ndarray.size {
			casted_data, cast_ok := endian.get_f64(data[i:i+ndarray.size], np_header.header.endianess)
			_lines[count] = cast(f64)casted_data
			count += 1
		}
		return _lines
    }
    return nil
}

@(private = "file")
parse_npy_header :: proc(
	h: ^Descriptor,
	header: string,
	allocator := context.allocator
) -> (err: ParseError) {

    // h.shape = make([]uint, 2, allocator)
    // h.shape : []uint

    // Clean up header string
    clean_header := strings.trim_space(header)

    is_alloc : bool
    // Replace single quotes
    clean_header, is_alloc = strings.replace(clean_header, "'", "\"", -1)
    clean_header, is_alloc = strings.replace(clean_header, "(", "[", -1)
    clean_header, is_alloc = strings.replace(clean_header, ")", "]", -1)

    // Enhanced descriptor parsing
    if descr_start := strings.index(clean_header, "\"descr\":"); descr_start != -1 {

        descr_start += 8
        descr_end := strings.index_byte(clean_header[descr_start:], ',')
        if descr_end == -1 do return .Malformed_Header

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

        if shape_end == -1 do return .Shape_Parse_Failed

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
            if !ok do return .Shape_Parse_Failed
            h.shape[count] = cast(uint)value
			count += 1
        }
		h.shape = h.shape[:count]

    }

    return .None
}
