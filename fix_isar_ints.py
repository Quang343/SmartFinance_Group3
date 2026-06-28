import os
import re
import glob

# Safe integer limit in JS
MAX_SAFE_INTEGER = 9007199254740991
MIN_SAFE_INTEGER = -9007199254740991

def replace_large_ints(match):
    num_str = match.group(1)
    num = int(num_str)
    if num > MAX_SAFE_INTEGER or num < MIN_SAFE_INTEGER:
        nearest = int(float(num))
        return match.group(0).replace(num_str, str(nearest))
    return match.group(0)

# We want to match `id: 1234567890123456789,` and other places where large integers might appear.
# Actually, let's just match any integer sequence that is 16 digits or more, 
# not preceded or followed by word characters or dots.
pattern = re.compile(r'(?<![\w\.])(-?\d{16,})(?![\w\.])')

target_dir = r"d:\Documments\Mobile code\Project_PRM\SmartFinance_Group3\lib\data\local\isar_models"
files = glob.glob(os.path.join(target_dir, "*.g.dart"))

for file_path in files:
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    new_content = pattern.sub(replace_large_ints, content)
    
    if new_content != content:
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"Fixed {os.path.basename(file_path)}")
    else:
        print(f"No changes in {os.path.basename(file_path)}")
