package nparray_decoder

import "base:runtime"
import "base:intrinsics"
import "core:fmt"
import "core:os"
import "core:io"
import "core:bufio"
import "core:mem"
import "core:c"
import "core:strings"
import "core:strconv"
import "core:encoding/endian"

ReadFileError :: union {
    OpenError,
    ReaderCreationError,
    ReaderReadByteError,
    mem.Allocator_Error,

    // Numpy Headers Error
    InvalidHeaderError,
    InvalidVersionError,
    InvalidHeaderLengthError,
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
}

NumpySaveVersion :: struct {
    maj: u8,
    min: u8
}

Descriptor :: struct {
    descr: string,
    fortran_order: bool,
    shape: [dynamic]int,
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
    size : int,
    length : u64
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
    }
}

delete_header :: proc(h: ^NumpyHeader) {
    delete (h.magic)
    delete (h.header.shape)
    delete (h.header.descr)
}

load_npy :: proc(
    file_name: string,
    bufreader_size: int,
    allocator:= context.allocator) -> (

    header: NumpyHeader,
    lines:  NDArray,
    error: ReadFileError ) {

    //fmt.printfln("indise decoder | trying to read %v", file_name)
    //
    // create an handler
    handle, open_error := os.open(file_name, os.O_RDONLY)
    if open_error != os.ERROR_NONE {
        fmt.printfln("Failed to open %v with err: %v", file_name, open_error)
        return header, lines, OpenError{file_name, open_error}
    }

    // create a stream
    stream := os.stream_from_handle(handle)

    // create a reader
    reader, ok := io.to_reader(stream)
    if !ok {
        fmt.printfln("Failed make reader of %v with err: %v", file_name, open_error)
        return header, lines, ReaderCreationError{file_name, stream}
    }

    // define bufio_reader
    bufio_reader : bufio.Reader
    bufio.reader_init(&bufio_reader, reader, bufreader_size, allocator)
    bufio_reader.max_consecutive_empty_reads = 1

    total_size := bufio.reader_size(&bufio_reader)
    remaining_size := bufio.reader_size(&bufio_reader)

    magic : [6]u8
    { // read magic magic
        read, rerr := io.read(reader, magic[:], &MAGIG_LEN)
        if rerr != nil || read != 6 {
            return header, lines, InvalidHeaderError{"Invalid magic number"}
        }
        remaining_size -= len(magic)
    }

    clone_err : mem.Allocator_Error
    header.magic, clone_err = strings.clone_from_bytes(magic[:])
    if clone_err != nil {
        return header, lines, nil
    }

    { // read version
        version : [2]u8
        read, rerr := io.read(reader, version[:])
        if rerr != nil || read != 2 {
            return header, lines, InvalidVersionError{"Invalid version", version}
        }
        header.version.maj = version[0]
        header.version.min = version[1]
        remaining_size -= len(version)
    }

    header_lenght : [2]u8
    { // read header length
        read, rerr := io.read(reader, header_lenght[:])
        if rerr != nil || read != 2 {
            return header, lines, InvalidHeaderLengthError{"Broken header length", header_lenght}
        }
        header.header_length = transmute(u16le)header_lenght
        remaining_size -= 2
    }

    len_header := cast(int)transmute(u16le)header_lenght

    header_desc := make([]u8, len_header)

    read, rerr := io.read(reader, header_desc[:])

    if rerr != nil || read != len_header {
        return header, lines, nil
    }

    parsed_header : Descriptor
    parr_err := parse_npy_header(&parsed_header, string( header_desc ))
    remaining_size -= len_header

    header.header = parsed_header

    _lines := recreate_array(&header, &bufio_reader, &lines, allocator = allocator)
    if _lines == nil {
        fmt.printfln("Out of recreate array: %v", _lines)
        return header, lines, nil
    }

    lines.data = _lines

    return header, lines, nil
}

recreate_array :: proc(
    header: ^NumpyHeader,
    reader: ^bufio.Reader,
    ndarray : ^NDArray,
    allocator := context.allocator ) -> ArrayTypes {

    data, read_bytes_err := bufio.reader_read_bytes(reader, '\n', allocator)
    defer delete(data)
    n_elem := len(data)

    switch header.header.descr[1:] {

        case "b1" :

            n_data_from_shape : int = 1
            for shp in header.header.shape {
                n_data_from_shape *= shp
            }
            size := len(data)/n_data_from_shape
            //fmt.printfln("len(data): %v | n_data_from_shape: %v", len(data), n_data_from_shape)
            ndarray.length = cast(u64)n_data_from_shape
            ndarray.size = size

            _lines := make([dynamic]b8)
            for i := 0; i <n_elem; i += 1 { append(&_lines, cast(b8)data[i])}
            return _lines[:]

        case "u1" :

            n_data_from_shape : int = 1
            for shp in header.header.shape {
                n_data_from_shape *= shp
            }
            size := len(data)/n_data_from_shape
            //fmt.printfln("len(data): %v | n_data_from_shape: %v", len(data), n_data_from_shape)
            ndarray.length = cast(u64)n_data_from_shape
            ndarray.size = size

            _lines := make([dynamic]i8)
            for i := 0; i <n_elem; i += 1 { append(&_lines, cast(i8)data[i])}
            return _lines[:]

        case "i1" :

            n_data_from_shape : int = 1
            for shp in header.header.shape {
                n_data_from_shape *= shp
            }
            size := len(data)/n_data_from_shape
            //fmt.printfln("len(data): %v | n_data_from_shape: %v", len(data), n_data_from_shape)
            ndarray.length = cast(u64)n_data_from_shape
            ndarray.size = size

            _lines := make([dynamic]i8)
            for i := 0; i <n_elem; i += 1 { append(&_lines, cast(i8)data[i])}
            return _lines[:]

        case "i2" :

            n_data_from_shape : int = 1
            for shp in header.header.shape {
                n_data_from_shape *= shp
            }
            size := len(data)/n_data_from_shape
            //fmt.printfln("len(data): %v | n_data_from_shape: %v", len(data), n_data_from_shape)
            ndarray.length = cast(u64)n_data_from_shape
            ndarray.size = size

            _lines := make([dynamic]i16)
            for i := 0; i <n_elem; i += size {
                casted_data, cast_ok := endian.get_i16(data[i:i+size], header.header.endianess)
                append(&_lines, cast(i16)casted_data)
            }
            return _lines[:]

        case "u2" :

            n_data_from_shape : int = 1
            for shp in header.header.shape {
                n_data_from_shape *= shp
            }
            size := len(data)/n_data_from_shape
            //fmt.printfln("len(data): %v | n_data_from_shape: %v", len(data), n_data_from_shape)
            ndarray.length = cast(u64)n_data_from_shape
            ndarray.size = size

            _lines := make([dynamic]u16)
            for i := 0; i <n_elem; i += size {
                casted_data, cast_ok := endian.get_u16(data[i:i+size], header.header.endianess)
                append(&_lines, cast(u16)casted_data)
            }
            return _lines[:]

        case "u4" :

            n_data_from_shape : int = 1
            for shp in header.header.shape {
                n_data_from_shape *= shp
            }
            size := len(data)/n_data_from_shape
            //fmt.printfln("len(data): %v | n_data_from_shape: %v", len(data), n_data_from_shape)
            ndarray.length = cast(u64)n_data_from_shape
            ndarray.size = size

            _lines := make([dynamic]u32)
            for i := 0; i <n_elem; i += size {
                casted_data, cast_ok := endian.get_u32(data[i:i+size], header.header.endianess)
                append(&_lines, casted_data)
            }
            return _lines[:]

        case "i4" :

            n_data_from_shape : int = 1
            for shp in header.header.shape {
                n_data_from_shape *= shp
            }
            size := len(data)/n_data_from_shape
            //fmt.printfln("len(data): %v | n_data_from_shape: %v", len(data), n_data_from_shape)
            ndarray.length = cast(u64)n_data_from_shape
            ndarray.size = size

            _lines := make([dynamic]i32)
            for i := 0; i <n_elem; i += size {
                casted_data, cast_ok := endian.get_i32(data[i:i+size], header.header.endianess)
                append(&_lines, casted_data)
            }
            return _lines[:]

        case "u8" :

            n_data_from_shape : int = 1
            for shp in header.header.shape {
                n_data_from_shape *= shp
            }
            size := len(data)/n_data_from_shape
            //fmt.printfln("len(data): %v | n_data_from_shape: %v", len(data), n_data_from_shape)
            ndarray.length = cast(u64)n_data_from_shape
            ndarray.size = size

            _lines := make([dynamic]u16)
            for i := 0; i <n_elem; i += size {
                casted_data, cast_ok := endian.get_u16(data[i:i+size], header.header.endianess)
                append(&_lines, casted_data)
            }
            return _lines[:]

        case "i8" :

            n_data_from_shape : int = 1
            for shp in header.header.shape {
                n_data_from_shape *= shp
            }
            size := len(data)/n_data_from_shape
            //fmt.printfln("len(data): %v | n_data_from_shape: %v", len(data), n_data_from_shape)
            ndarray.length = cast(u64)n_data_from_shape
            ndarray.size = size

            _lines := make([dynamic]i64)
            for i := 0; i <n_elem; i += size {
                casted_data, cast_ok := endian.get_i64(data[i:i+size], header.header.endianess)
                append(&_lines, casted_data)
            }
            return _lines[:]

        case "f2" :

            n_data_from_shape : int = 1
            for shp in header.header.shape {
                n_data_from_shape *= shp
            }
            size := len(data)/n_data_from_shape
            //fmt.printfln("len(data): %v | n_data_from_shape: %v", len(data), n_data_from_shape)
            ndarray.length = cast(u64)n_data_from_shape
            ndarray.size = size

            _lines := make([dynamic]f16)
            for i := 0; i <n_elem; i += size {
                casted_data, cast_ok := endian.get_f16(data[i:i+size], header.header.endianess)
                append(&_lines, casted_data)
            }
            return _lines[:]

        case "c8" :

            n_data_from_shape : int = 1
            for shp in header.header.shape {
                n_data_from_shape *= shp
            }
            size := len(data)/n_data_from_shape
            //fmt.printfln("len(data): %v | n_data_from_shape: %v", len(data), n_data_from_shape)
            ndarray.length = cast(u64)n_data_from_shape
            ndarray.size = size

            _lines := make([dynamic]f32)
            for i := 0; i <n_elem; i += size {
                casted_data, cast_ok := endian.get_f32(data[i:i+size], header.header.endianess)
                append(&_lines, cast(f32)casted_data)
            }
            return _lines[:]

        case "c16" :

            n_data_from_shape : int = 1
            for shp in header.header.shape {
                n_data_from_shape *= shp
            }

            size := 16
            ndarray.length = cast(u64)n_data_from_shape
            ndarray.size = size

            count_elems := 0
            //fmt.printfln("size: %v, length: %v", size, n_data_from_shape)
            if header.header.endianess == .Little {
                _lines := make([dynamic]f64)
                i : int
                for i := 0; i <n_elem-(size/2); i += size {
                    casted_data, cast_ok := endian.get_f64(data[i:i+size], header.header.endianess)
                    //fmt.printfln(
                    //    "count: %v,%v | data: %v | c16: %v",
                    //    count_elems, i,
                    //    intrinsics.unaligned_load( (^u64)(raw_data(data[i:i+size]))),
                    //    casted_data, )
                    count_elems += 1
                    append(&_lines, cast(f64)casted_data)
                }
                return _lines[:]
            } else {
                _lines := make([dynamic]f64)
                i : int
                for i := 0; i <n_elem-(size/2); i += size {
                    casted_data, cast_ok := endian.get_f64(data[i:i+size], header.header.endianess)
                    //fmt.printfln(
                    //    "count: %v,%v | data: %v | c16: %v",
                    //    count_elems, i,
                    //    data[i:i+size],
                    //    casted_data, )
                    count_elems += 1
                    append(&_lines, cast(f64)casted_data)
                }
                return _lines[:]
            }

        case "f4" :

            n_data_from_shape : int = 1
            for shp in header.header.shape {
                n_data_from_shape *= shp
            }
            size := len(data)/n_data_from_shape
            //fmt.printfln("len(data): %v | n_data_from_shape: %v", len(data), n_data_from_shape)
            //ndarray.length = cast(u64)n_data_from_shape
            ndarray.size = size

            _lines := make([dynamic]f32)
            for i := 0; i <n_elem; i += size {
                casted_data, cast_ok := endian.get_f32(data[i:i+size], header.header.endianess)
                append(&_lines, casted_data)
            }
            return _lines[:]

        case "f8" :

            n_data_from_shape : int = 1
            for shp in header.header.shape {
                n_data_from_shape *= shp
            }
            size := len(data)/n_data_from_shape
            //fmt.printfln("len(data): %v | n_data_from_shape: %v", len(data), n_data_from_shape)
            ndarray.length = cast(u64)n_data_from_shape
            ndarray.size = size

            _lines := make([dynamic]f64)
            for i := 0; i <n_elem; i += size {
                casted_data, cast_ok := endian.get_f64(data[i:i+size], header.header.endianess)
                append(&_lines, casted_data)
            }
            return _lines[:]


    }

    return nil
}

parse_npy_header :: proc(
    h: ^Descriptor,
    header: string, allocator := context.allocator) -> (err: ParseError) {

    h.shape = make([dynamic]int, 0, 2, allocator)

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

        if shape_end == -1 {

            return .Shape_Parse_Failed

        }

        shape_str := clean_header[shape_start:shape_start+shape_end]
        shape_str = strings.trim_space(shape_str)
        shape_str = strings.trim(shape_str, "[]")

        // Split and parse integers
        parts := strings.split(shape_str, ",", allocator)
        defer delete(parts)

        for part in parts {
            trimmed := strings.trim_space(part)
            if trimmed == "" { continue }
            value, ok := strconv.parse_int(trimmed)
            if !ok {
                return .Shape_Parse_Failed
            }
            append(&h.shape, value)
        }

    }

    return .None
}
