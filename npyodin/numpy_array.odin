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

decode_npfile :: proc(
    file_name: string,
    bufreader_size: int,
    allocator:= context.allocator) -> (

    header: NumpyHeader,
    lines:  []byte,
    error: ReadFileError ) {

    fmt.printfln("indise decoder | trying to read %v", file_name)

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
        return header, nil, nil
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

    prod_shape : int = 1
    for i in 0..<len(header.header.shape) {
        prod_shape *= header.header.shape[i]
    }

    _lines := make([dynamic][]byte, 0, 0, allocator)

    data, read_bytes_err := bufio.reader_read_bytes(&bufio_reader, ' ')
    n_elem := len(data)

    n_data_from_shape : int = 1
    for shp in header.header.shape {
        n_data_from_shape *= shp
    }

    size := len(data)/n_data_from_shape
    fmt.printfln("number of elements in data: %v, with sizeof: %v", n_elem, size)

    append(&_lines, data)
    //fmt.printfln("data: %v len: %v", data, len(data))
    //for i := 0; i <len(data)-4; i += 4 {
    //    casted_data, cast_err := endian.get_u32(data[i:i+4], header.header.endianess)
    //    append(&_lines, casted_data)
    //}
    //casted_data, cast_err := endian.get_u32(data[4:9], header.header.endianess)
    //fmt.printfln("casted data: %v", casted_data)

    return header, _lines[0], nil
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
            descr, clone_err := strings.clone(descr_str[1:])
            h.descr = descr

            //if clone_err == mem.Allocator_Error.None {
            //    return .None
            //}

            //switch descr_str[1:] {
            //    case "u1": h.descr = u8
            //    case "i1": h.descr = i8
            //    case "b1": h.descr = b8
            //    case:      return .Invalid_Descriptor
            //}

        case strings.has_prefix(descr_str, "<") :
            // Existing endian-sensitive types
            h.endianess = endian.Byte_Order.Little
            descr, clone_err := strings.clone(descr_str[1:])
            h.descr = descr

            //if clone_err == mem.Allocator_Error.None {
            //    return .None
            //}

            //switch descr_str[1:] {
            //    case "f8": h.descr = f64le
            //    case "f4": h.descr = f32le
            //    case "i8": h.descr = i64le
            //    case "i4": h.descr = i32le
            //    case "i2": h.descr = i16le
            //    // Add more as needed
            //    case: return .Invalid_Descriptor
            //}

        case strings.has_prefix(descr_str, ">") :
            // Existing endian-sensitive types
            h.endianess = endian.Byte_Order.Big
            descr, clone_err := strings.clone(descr_str[1:])
            h.descr = descr

            //if clone_err == mem.Allocator_Error.None {
            //    return .None
            //}

            //switch descr_str[1:] {
            //    case "f8": h.descr = f64be
            //    case "u4": h.descr = u32be
            //    // Add more as needed
            //    case: return .Invalid_Descriptor
            //}

        case: // Handle non-byte-ordered types
            h.endianess = endian.PLATFORM_BYTE_ORDER
            descr, clone_err := strings.clone(descr_str[1:])
            h.descr = descr

            //if clone_err == mem.Allocator_Error.None {
            //    return .None
            //}

            //switch descr_str {
            //    case "u8": h.descr = u64
            //    case "i8": h.descr = i64
            //    // Add other architecture-neutral types
            //    case: return .Invalid_Descriptor
            //}
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
