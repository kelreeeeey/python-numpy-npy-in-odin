#! usr/bin/ bash

test_2d_arrays() {
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/b_5x5x5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/byte_5x5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/int8_5x5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/intc_5x5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/int__5x5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/int16_5x5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/int32_5x5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/int64_5x5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/longlong_5x5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/short_5x5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/ubyte_5x5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/uint8_5x5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/uintc_5x5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/ulonglong_5x5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/ushort_5x5.npy
}

test_1d_arrays() {
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/int8_5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/intc_5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/int__5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/int16_5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/int32_5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/int64_5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/longlong_5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/short_5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/ubyte_5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/uintc_5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/ulonglong_5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/ushort_5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/b_5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/byte_5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/ints/uint8_5.npy
}

test_2d_arrays
test_1d_arrays
