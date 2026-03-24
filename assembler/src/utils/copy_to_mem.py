import os 

def load_string_to_file(file_string, file_path):
    with open(file_path, "w") as f:
        f.write(file_string)

def load_file_to_string(file_path):
    with open (file_path, "r") as f:
        file_string = f.read() 

    return file_string

def copy_v_to_mem(version):
    """
    Takes a version and copies it to the 
    actual mem files for the vivado project
    """

    # Ideally you want to validate the version 
    # But since this is an internal tool I'm going
    # to skip that. Make sure your version is vn.n format

    # Also, VERY IMPORTANT 
    # RUN FROM /assembler DIRECTORY 
    # DO NOT ATTEMPT OTHERWISE
    # DO SO ONLY IN THIS PROJECT 

    path_to_output_dir = f"output/final_demo/v{version}"

    # Get the strings 

    ram_string = load_file_to_string(f"{path_to_output_dir}/final_demo_RAM_Demo.txt")
    rom_string = load_file_to_string(f"{path_to_output_dir}/final_demo_ROM_Demo.txt")

    path_to_actual_ram_mem = "../program/Complete_RAM_Demo.mem"
    path_to_actual_rom_mem = "../program/Complete_ROM_Demo.mem"

    load_string_to_file(ram_string, path_to_actual_ram_mem)
    load_string_to_file(rom_string, path_to_actual_rom_mem)