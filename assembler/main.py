from src.edslfiles.final import asm
from src.utils.copy_to_mem import copy_v_to_mem
import sys 

def parse_args():
    args = sys.argv
    idx = args.index("-v")
    version = args[idx + 1]

    idx = args.index("-c")
    copy = args[idx + 1]

    if copy in ["True", "true", 't', "T", "1"]:
        copy = 1;

    return version, copy 

def main():
    version, copy = parse_args() 
    asm.create_file(version)

    if copy:
        copy_v_to_mem(version=version)
        print("\nCopied to actual mem files")

if __name__ == "__main__":
    main()