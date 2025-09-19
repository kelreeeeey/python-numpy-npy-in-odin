import numpy as np
from itertools import repeat
import os

def make_integer_arrays() -> None:

    b_5     = np.array([1, 0, 1, 0, 1]).astype(np.bool_)
    np.save("./test_data/ints/b_5.npy", b_5)
    b_5x5     = np.array(list(repeat(b_5, 5)))
    np.save("./test_data/ints/b_5x5.npy", b_5x5)

    print(f"{ b_5= }")
    print(f"{ b_5x5= }")

    byte_5     = np.array([1, 0, 1, 0, 1]).astype(np.byte)
    np.save("./test_data/ints/byte_5.npy", byte_5)
    byte_5x5     = np.array(list(repeat(byte_5, 5)))
    np.save("./test_data/ints/byte_5x5.npy", byte_5x5)

    print(f"{ byte_5= }")
    print(f"{ byte_5x5= }")

    ubyte_5     = np.array([1, 0, 1, 0, 1]).astype(np.ubyte)
    np.save("./test_data/ints/ubyte_5.npy", ubyte_5)
    ubyte_5x5     = np.array(list(repeat(ubyte_5, 5)))
    np.save("./test_data/ints/ubyte_5x5.npy", ubyte_5x5)

    print(f"{ ubyte_5= }")
    print(f"{ ubyte_5x5= }")

    short_5     = np.array([1, 0, 1, 0, 1]).astype(np.short)
    np.save("./test_data/ints/short_5.npy", short_5)
    short_5x5     = np.array(list(repeat(short_5, 5)))
    np.save("./test_data/ints/short_5x5.npy", short_5x5)

    ushort_5     = np.array([1, 0, 1, 0, 1]).astype(np.ushort)
    np.save("./test_data/ints/ushort_5.npy", ushort_5)
    ushort_5x5     = np.array(list(repeat(ushort_5, 5)))
    np.save("./test_data/ints/ushort_5x5.npy", ushort_5x5)

    intc_5 = np.arange(1, 6, 1).astype(np.intc)
    np.save("./test_data/ints/intc_5.npy", intc_5)
    intc_5x5     = np.array(list(intc_5 + x for x in range(5)))
    np.save("./test_data/ints/intc_5x5.npy", intc_5x5)

    uintc_5 = np.arange(1, 6, 1).astype(np.uintc)
    np.save("./test_data/ints/uintc_5.npy", uintc_5)
    uintc_5x5     = np.array(list(uintc_5 + x for x in range(5)))
    np.save("./test_data/ints/uintc_5x5.npy", uintc_5x5)

    int__5 = np.arange(1, 6, 1).astype(np.int_)
    np.save("./test_data/ints/int__5.npy", int__5)
    int__5x5     = np.array(list(int__5 + x for x in range(5)))
    np.save("./test_data/ints/int__5x5.npy", int__5x5)

    longlong_5 = np.arange(1, 6, 1).astype(np.longlong)
    np.save("./test_data/ints/longlong_5.npy", longlong_5)
    longlong_5x5     = np.array(list(longlong_5 + x for x in range(5)))
    np.save("./test_data/ints/longlong_5x5.npy", longlong_5x5)

    ulonglong_5 = np.arange(1, 6, 1).astype(np.ulonglong)
    np.save("./test_data/ints/ulonglong_5.npy", ulonglong_5)
    ulonglong_5x5     = np.array(list(ulonglong_5 + x for x in range(5)))
    np.save("./test_data/ints/ulonglong_5x5.npy", ulonglong_5x5)

    int8_5 = np.arange(1, 6, 1).astype(np.int8)
    np.save("./test_data/ints/int8_5.npy", int8_5)
    int8_5x5     = np.array(list(int8_5 + x for x in range(5)))
    np.save("./test_data/ints/int8_5x5.npy", int8_5x5)

    uint8_5 = np.arange(1, 6, 1).astype(np.uint8)
    np.save("./test_data/ints/uint8_5.npy", uint8_5)
    uint8_5x5     = np.array(list(uint8_5 + x for x in range(5)))
    np.save("./test_data/ints/uint8_5x5.npy", uint8_5x5)

    print(f"{ uint8_5= }")
    print(f"{ uint8_5x5= }")

    int16 = np.arange(1, 6, 1).astype(np.int16)
    np.save("./test_data/ints/int16_5.npy", int16)
    int16_5x5     = np.array(list(int16 + x for x in range(5)))
    np.save("./test_data/ints/int16_5x5.npy", int16_5x5)

    int32 = np.arange(1, 6, 1).astype(np.int32)
    np.save("./test_data/ints/int32_5.npy", int32)
    int32_5x5     = np.array(list(int32 + x for x in range(5)))
    np.save("./test_data/ints/int32_5x5.npy", int32_5x5)

    int64 = np.arange(1, 6, 1).astype(np.int64)
    np.save("./test_data/ints/int64_5.npy", int64)
    int64_5x5     = np.array(list(int64 + x for x in range(5)))
    np.save("./test_data/ints/int64_5x5.npy", int64_5x5)

    return None

def make_floats_arrays() -> None:

    half = np.arange(1, 6, 1).astype(np.half)
    np.save("./test_data/floats/half_5.npy", half)
    half_5x5     = np.array(list(half + x for x in range(5)))
    np.save("./test_data/floats/half_5x5.npy", half_5x5)

    float16 = np.arange(1, 6, 1).astype(np.float16)
    np.save("./test_data/floats/float16_5.npy", float16)
    float16_5x5     = np.array(list(float16 + x for x in range(5)))
    np.save("./test_data/floats/float16_5x5.npy", float16_5x5)

    single = np.arange(1, 6, 1).astype(np.single)
    np.save("./test_data/floats/single_5.npy", single)
    single_5x5     = np.array(list(single + x for x in range(5)))
    np.save("./test_data/floats/single_5x5.npy", single_5x5)

    double = np.arange(1, 6, 1).astype(np.double)
    np.save("./test_data/floats/double_5.npy", double)
    double_5x5     = np.array(list(double + x for x in range(5)))
    np.save("./test_data/floats/double_5x5.npy", double_5x5)

    longdouble = np.arange(1, 6, 1).astype(np.longdouble)
    np.save("./test_data/floats/longdouble_5.npy", longdouble)
    longdouble_5x5     = np.array(list(longdouble + x for x in range(5)))
    np.save("./test_data/floats/longdouble_5x5.npy", longdouble_5x5)

    csingle = np.arange(1, 6, 1).astype(np.csingle)
    np.save("./test_data/floats/csingle_5.npy", csingle)
    csingle_5x5     = np.array(list(csingle + x for x in range(5)))
    np.save("./test_data/floats/csingle_5x5.npy", csingle_5x5)

    cdouble = np.arange(1, 6, 1).astype(np.cdouble)
    np.save("./test_data/floats/cdouble_5.npy", cdouble)
    cdouble_5x5     = np.array(list(cdouble + x for x in range(5)))
    np.save("./test_data/floats/cdouble_5x5.npy", cdouble_5x5)

    clongdouble = np.arange(1, 6, 1).astype(np.clongdouble)
    np.save("./test_data/floats/clongdouble_5.npy", clongdouble)
    clongdouble_5x5     = np.array(list(clongdouble + x for x in range(5)))
    np.save("./test_data/floats/clongdouble_5x5.npy", clongdouble_5x5)

    float32 = np.arange(1, 6, 1).astype(np.float32)
    np.save("./test_data/floats/float32_5.npy", float32)

    float32_5x5     = np.array(list(float32 + x for x in range(5)))
    np.save("./test_data/floats/float32_5x5.npy", float32_5x5)

    float64 = np.arange(1, 6, 1).astype(np.float64)
    np.save("./test_data/floats/float64_5.npy", float64)

    float64_5x5     = np.array(list(float64 + x for x in range(5)))
    np.save("./test_data/floats/float64_5x5.npy", float64_5x5)

    complex128 = np.arange(1, 6, 1).astype(np.complex128)
    np.save("./test_data/floats/complex128_5.npy", complex128)

    complex128_5x5 = np.array(list(complex128 + x for x in range(5)))
    np.save("./test_data/floats/complex128_5x5.npy", complex128_5x5)

    return None

def main() -> None:
    if not os.path.exists("./test_data/"):
        os.makedirs("./test_data", exist_ok=True)

    for d in ( "./test_data/ints/", "./test_data/floats/"):
        if not os.path.exists(d):
            os.makedirs(d, exist_ok=True)

    make_integer_arrays()
    make_floats_arrays()

if __name__ == "__main__":
    main()
