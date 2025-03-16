package main

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:encoding/endian"
import npyload "npyodin"

default_context : runtime.Context

main :: proc() {

    default_context = context

    file_name : string = os.args[1]
    defer delete(file_name)

    np_header, ndarray, ok := npyload.load_npy(file_name, 1024, allocator = default_context.allocator)

    defer npyload.delete_ndarray(&ndarray)
    defer npyload.delete_header(&np_header)

    fmt.printfln("file: %v", file_name)
    fmt.printfln("Header: \n| %v", np_header)

    fmt.printfln("Data: %v\n| size_of that thing: %v bytes\n| with lenght of: %v bits\n", ndarray, size_of(ndarray), ndarray.length)

}
