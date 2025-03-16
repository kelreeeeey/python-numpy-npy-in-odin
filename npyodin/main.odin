package nparray_decoder

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:encoding/endian"

default_context : runtime.Context

example :: proc() {

    default_context = context

    file_name : string = os.args[1]
    np_header, ndarray, ok := decode_npfile(file_name, 1024, allocator = default_context.allocator)

    defer delete_ndarray(&ndarray)
    defer delete_header(&np_header)

    fmt.printfln("Header: \n\t%v", np_header)
    //fmt.printfln("\t magic: %v", np_header.magic)
    //fmt.printfln("\t version: %v", np_header.version)
    //fmt.printfln("\t header_length: %v", np_header.header_length)
    //fmt.println("\t header_desc:")
    //fmt.printfln("\t\t descr: %v", np_header.header.descr)
    //fmt.printfln("\t\t shape: %v", np_header.header.shape)
    //fmt.printfln("\t\t fortran_order: %v", np_header.header.fortran_order)
    //fmt.printfln("\t\t endianess: %v", np_header.header.endianess)

    fmt.printfln("Data: %v\n| size_of that thing: %v bytes\n| with lenght of: %v bits\n", ndarray, size_of(ndarray), ndarray.length)

}

main :: proc() {
    example()
}
