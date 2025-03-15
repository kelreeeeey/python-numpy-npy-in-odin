package nparray_decoder

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:encoding/endian"

default_context : runtime.Context

//main1 :: proc() {
//    default_context = context
//
//    file_name : string = os.args[1]
//    header, data, ok := decode_npfile(file_name, 1024, allocator = default_context.allocator)
//    defer delete(data)
//
//    fmt.println("Header:")
//    fmt.printfln("\t magic: %v", header.magic)
//    fmt.printfln("\t version: %v", header.version)
//    fmt.printfln("\t header_length: %v", header.header_length)
//    fmt.println("\t header_desc:")
//    fmt.printfln("\t\t descr: %v", header.header.descr)
//    fmt.printfln("\t\t shape: %v", header.header.shape)
//    fmt.printfln("\t\t fortran_order: %v", header.header.fortran_order)
//    fmt.printfln("\t\t endianess: %v", header.header.endianess)
//
//    if ok != nil {
//        fmt.printfln("Failed open %v with error %v", file_name, ok)
//    }
//    fmt.printfln("data (%v elements): %v\n", len(data), data)
//    //{
//    //    t := type_info_of( header.desc.descr )
//    //    converted_data, ok := reconstruct(data, type_of(t))
//    //    fmt.printfln("reconstructed data: %v", converted_data)
//    //}
//
//}

make_array :: proc($T:typeid) -> [dynamic]T {
    arr := make([dynamic]T, 0)
    return arr
}

example :: proc() {

    default_context = context

    file_name : string = os.args[1]
    np_header, data, ok := decode_npfile(file_name, 1024, allocator = default_context.allocator)
    defer delete(data)

    fmt.printfln("Header: %v", np_header)
    fmt.printfln("\t magic: %v", np_header.magic)
    fmt.printfln("\t version: %v", np_header.version)
    fmt.printfln("\t header_length: %v", np_header.header_length)
    fmt.println("\t header_desc:")
    fmt.printfln("\t\t descr: %v", np_header.header.descr)
    fmt.printfln("\t\t shape: %v", np_header.header.shape)
    fmt.printfln("\t\t fortran_order: %v", np_header.header.fortran_order)
    fmt.printfln("\t\t endianess: %v", np_header.header.endianess)

    fmt.printfln("Example bytes: %v\n| size_of that thing: %v bytes\n| with lenght of: %v bits\n", data, size_of(data), len(data))

    //ex_decodes := make([dynamic]f64, 0, default_context.allocator)
    //ex_decodes := np_header.header.data
    //fmt.printfln("\nDecodes bytes: %v\n| size of that thing: %v bytes\n| with length of: %v\n", ex_decodes, size_of(ex_decodes), len(ex_decodes))
    //defer delete(ex_decodes)
    //
    //n_data_from_shape : int = 1
    //for shp in np_header.header.shape {
    //    n_data_from_shape *= shp
    //}
    //
    //size := len(data)/n_data_from_shape
    //
    //t := &np_header.header.descr
    //fmt.printfln("\nsize of %v: %v\n", t^, size)
    //
    ////end_proc : {
    ////    switch 
    ////}
    //
    //for i:=0; i < len(data); i+= size {
    //    ex_decode, ok_decode := endian.get_i32(data[i:i+size], np_header.header.endianess)
    //    fmt.printfln("\tExample Decoded: %v\n\t| size of that thing: %v", ex_decode, size_of(ex_decode))
    //    append(&ex_decodes, ex_decode)
    //}
    //fmt.printfln("\nDecodes bytes: %v\n| size of that thing: %v bytes\n| with length of: %v\n", ex_decodes, size_of(ex_decodes), len(ex_decodes))
    //fmt.printfln("Header: %v", np_header.header)

}

main :: proc() {
    //main1()
    example()
}
