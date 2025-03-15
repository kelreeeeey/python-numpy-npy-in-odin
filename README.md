# python-numpy-npy-in-odin

[Python]( https://www.python.org/ )-[ Numpy ](https://github.com/numpy/numpy) `.npy` file reader in [ Odin ](https://odin-lang.org/)

> this repo currently is under development using [ python 3.10 ](https://www.python.org/downloads/release/python-31016/) and [ numpy version 1.26.4 ](https://numpy.org/devdocs/release/1.26.4-notes.html)

## Motivations

* I've been coding EXHAUSTIVELY in python, and 've been using numpy since day-1.

* i ain't trying to combine python and odin in a complicated things.

* leave the lovely filthy snake alone.

* leave the almighty odin alone.

* being able to utilized the output from those 2 languages would be great, right?, esp large data, like `.npy` files.

* as far as my ability to surfing and searching through the internet, i haven't found single person doing this kinda thing

* inspired by Bill, G.. He wrote about [ "Reverse Engineering Alembic" ](https://www.gingerbill.org/article/2022/07/11/reverse-engineering-alembic/)
which where He tried to reading [ Alembic ](.http://www.alembic.io/) interchange file format for his works and his team in [ JangaFX ](https://jangafx.com/) and try to read it in [ Odin ](https://odin-lang.org/)

lastly, i want to thank to numpy teams, Bill, G. and Rickard Andersson.
i've been watching Rickard's vidoes about Odin in his YouTube to figure out things
to be able to do some parts of this repo. i definitley would recommend you to
check Rickard's vidoes here: [Rick's YouTube](https://www.youtube.com/@mccGoNZooo)

i specifically watched these playlists:

1. [The Odin programming language with Rickard](https://youtube.com/playlist?list=PLEQTpgQ9eFCGlQa2z0j_TQTGggHOIF8Z1&si=nxXgXCB5N0-F0s7D)
2. [Odin in Practice](https://youtube.com/playlist?list=PLEQTpgQ9eFCEg0CTd0KkiqgUpP5V0JM4-&si=oZJoIuzr9s7GXVWu)

## My plans and what done so far

### research, duh!?

1. how numpy save 'em files in disk
2. how numpy load 'em .npy files to memory

those 2 coherently relates to file descriptor a.k.a header, and the array itself.

### reverse the thing

1. open and read the bytes
2. reconstruct the file header. File header contains informations of
what and how we can recreate the array
3. reconstruct the array

### plans

1. i'll focus on integers and floats first
2. i'll do some basic 1D arrays and 2D arrays.
3. after the reconstructions, it'll be nice to save it back as `.npy` file too!.

## TL;DR, 

### Numpy (v1.26.4) DataTypes

source: [Numpy Data Types](https://numpy.org/doc/1.26/user/basics.types.html)
#### Bool, Byte, and Integer

| Numpy Type | `npy` File Header |
| -------------- | --------------- |
| byte | `\|i1` |
| b | `\|b1` |
| int16 | `<i2` |
| int32 | `<i4` |
| int64 | `<i8` |
| int8 | `\|i1` |
| intc | `<i4` |
| int_ | `<i4` |
| longlong | `<i8` |
| short | `<i2` |
| ubyte | `\|u1` |
| uint8 | `\|u1` |
| uintc | `<u4` |
| ulonglong | `<u8` |
| ushort | `<u2` |

#### Floats

| Numpy Type | `npy` File Header |
| -------------- | --------------- |
| cdouble | `<c16` |
| clongdouble | `<c16` |
| csingle | `<c8` |
| double | `<f8` |
| float16 | `<f2` |
| float32 | `<f4` |
| float64 | `<f8` |
| half | `<f2` |
| longdouble | `<f8` |
| single | `<f4` |

