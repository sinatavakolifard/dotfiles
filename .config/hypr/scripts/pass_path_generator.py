from sys import argv

passwords = argv[1]

def refine_line(line):
    return line.replace("├──", "").replace("└──","").replace("│","").replace("[01;34m","").replace("[00m","").replace("[0m","").replace("\xa0\xa0", "").replace(" ","")

def find_paths(passwords):
    paths = []
    curr_path = []
    last_indent = 0
    for line in passwords.splitlines():
        indent = line.count("  ") + line.count("    ")
        for i in range(last_indent-indent):
            del curr_path[-1]
        last_indent = indent
        if "[01;34m" in line:
            curr_path.append(refine_line(line))
        elif "[00m" in line:
            curr_path.append(refine_line(line))
            paths.append("/".join(curr_path))
            del curr_path[-1]
    return paths

print("\n".join(find_paths(passwords)))