from rich import print
import argparse
import format_impl as format
from pathlib import Path
import contextlib
import os

parser = argparse.ArgumentParser()
parser.add_argument("--d", type=str, required=False, default="")
parser.add_argument("--dir", type=str, required=False, default="")
args = parser.parse_args()

def load_in(file: str) -> None:
    print(f"\nbegin file {file}\n")
    with contextlib.ExitStack() as stack:
        if hasattr(file, 'read'):
            fid = file
            own_fid = False
        else:
            fid = stack.enter_context(open(os.fspath(file), "rb"))
            own_fid = True

        format.pp("load in open contextlib: fid", type(fid))

        N = len(format.MAGIC_PREFIX)
        magic = fid.read(N)

        print(magic, format.MAGIC_PREFIX, own_fid)
        fid.seek(-min(N, len(magic)), 1)
        data = format.read_array(fid)
        format.pp(f"load in open contextlib: data  {type(data)}", data)

    with open(file, "rb") as f:
        format.pp("load in open: f", type(f))
        print(f)
        try:
            data = f.read()
            # print("can decode the data", data)
        except UnicodeDecodeError:
            pass
            # print("cannot decode: ", f)

    print(f"\nend file {file}\n")
    return None

def main() -> None:
    if args.d == "" and args.dir == "":
        load_in(file="./arrayf64_1.npy")
        load_in(file="./arrayf64_5.npy")
        load_in(file="./arrayb_5.npy")
        # load_in(file="./arrayf32_5.npy")
        load_in(file="./arrayuint8_5.npy")
        # load_in(file="./arrayint_5.npy")
        # load_in(file="./arrayf16_5.npy")
        # load_in(file="./arrayint16_5.npy")
        # load_in(file="./arrayint32_5.npy")
        # load_in(file="./arrayint64_5.npy")
        # load_in(file="./arrayf64_5x5.npy")
        # load_in(file="./arrayint_5x5.npy")
        # load_in(file="./arrayf64_5x5x5.npy")
        # load_in(file="./arrayf64_25x25x100.npy")

    elif args.d != "" and args.dir == "":
        load_in(file=args.d)

    elif args.d == "" and args.dir != "":
        dir = Path(args.dir)
        if not dir.exists():
            print("Dir is not exist")
            return None
        for file in dir.iterdir():
            load_in(file=file)

    return None

if __name__ == "__main__":
    main()

