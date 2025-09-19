package main

import "base:runtime"
import "core:fmt"
import "core:os"
import npyload "npyodin"

default_context : runtime.Context

main :: proc() {

	// context.allocator = context.temp_allocator
	default_context = context

    file_name : string = os.args[1]
    defer delete(file_name)

    np_header, ndarray, ok := npyload.load_npy(file_name, allocator=default_context.allocator)
	if ok != nil do fmt.panicf("Wth")
    defer npyload.delete_ndarray(ndarray)
    defer npyload.delete_header(&np_header)

    fmt.printfln("file: %v", file_name)
    fmt.println("\tHeader")
    fmt.printfln("\t magic: %s", np_header.magic)
    fmt.printfln("\t ver. : %v", np_header.version)
    fmt.printfln("\t head_length : %v", np_header.header_length)
    fmt.printfln("\t descr : %v", np_header.descr)
    fmt.printfln("\t fortran_order : %v", np_header.fortran_order)
    fmt.printfln("\t shape : %v", np_header.shape)
    fmt.printfln("\t endianess : %v", np_header.endianess)
    fmt.println("\tData")
    fmt.printfln("\t data: %v", ndarray.data[:5])
    fmt.printfln("\t size: %v", ndarray.size)
    fmt.printfln("\t len : %v", ndarray.length)
    fmt.printfln("\t size of  : %v", size_of(ndarray))
    fmt.printfln("\t length of: %v", ndarray.length)

	return

}
