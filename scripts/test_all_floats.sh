#! usr/bin/ bash

test_2d_arrays() {
  # the complex numbers are not very intuitive for me, yet
  ./builds/python-numpy-npy-in-odin.exe ./test_data/floats/cdouble_5x5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/floats/clongdouble_5x5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/floats/csingle_5x5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/floats/double_5x5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/floats/float16_5x5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/floats/float32_5x5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/floats/float64_5x5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/floats/half_5x5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/floats/longdouble_5x5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/floats/single_5x5.npy
}

test_1d_arrays() {
  # the complex numbers are not very intuitive for me, yet
  ./builds/python-numpy-npy-in-odin.exe ./test_data/floats/cdouble_5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/floats/clongdouble_5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/floats/csingle_5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/floats/double_5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/floats/float16_5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/floats/float32_5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/floats/float64_5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/floats/half_5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/floats/longdouble_5.npy
  ./builds/python-numpy-npy-in-odin.exe ./test_data/floats/single_5.npy
}

test_2d_arrays
test_1d_arrays
