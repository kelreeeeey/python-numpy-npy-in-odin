"""Print data types from NumPy"""
# coding: utf-8 -*-
#
# Created at: Fri 2025-09-19 22:34:11+0700
#
# File: scripts\print_all_np_dtypes.py
# Author: Kelrey
# Email: taufiq.kelrey1@gmail.com
# Github: kelreeeey

try:
    import numpy as np
    has_numpy = True
except ModuleNotFoundError as _:
    has_numpy = False

try:
    from rich import print

    has_rich = True
except ModuleNotFoundError as _:
    has_rich = False

attrs = ["alignment", "char", "descr", "base"]
types = (
    "bool",
    "byte",
    "ubyte",
    "short",
    "ushort",
    "intc",
    "uintc",
    "int",
    "longlong",
    "ulonglong",
    "int8",
    "uint8",
    "int16",
    "int32",
    "int64",
    "half",
    "float16",
    "single",
    "double",
    "longdouble",
    "csingle",
    "cdouble",
    "clongdouble",
    "float32",
    "float64",
    "complex",
)


def main() -> int:
    dtypes = {b: [getattr(np.dtype(b), x) for x in attrs] for b in types}
    if not has_rich:
        for t, a in dtypes.items():
            print(t, a)
    else:
        print(dtypes)
    return 0


if __name__ == "__main__":
    if has_numpy:
        main()
    else:
        print("You don't have numpy")
