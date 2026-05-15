import os
import re
import fnmatch

def should_ignore(path, ignore_patterns):
    for pattern in ignore_patterns:
        if fnmatch.fnmatch(path, pattern) or fnmatch.fnmatch(os.path.basename(path), pattern):
            return True
        if any(fnmatch.fnmatch(part, pattern.strip('/')) for part in path.split(os.sep)):
            return True
    return False

def clean_content(content, ext):
    # Basic comment removal based on extension
    if ext in ['.sh', '.py', '.yml', '.yaml', '.conf']:
        content = re.sub(r'(^|\s)#.*', '', content)
    elif ext in ['.js', '.css']:
        content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
        content = re.sub(r'//.*', '', content)
    elif ext in ['.html', '.xml']:
        content = re.sub(r'<!--.*?-->', '', content, flags=re.DOTALL)
    
    # Remove empty lines
    lines = [line for line in content.splitlines() if line.strip()]
    return "\n".join(lines)

def main():
    root_dir = "."
    output_file = "repomix-output.md"
    ignore_file = ".repomixignore"
    
    ignore_patterns = ['.git', 'repomix-output.md', '__pycache__', '*.iso', '*.png', '*.jpg', '*.pdf']
    if os.path.exists(ignore_file):
        with open(ignore_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    ignore_patterns.append(line)

    with open(output_file, 'w', encoding='utf-8') as out:
        out.write("# Repository Analysis: TFG-ASIRB\n\n")
        out.write("## Directory Structure\n```text\n")
        
        for root, dirs, files in os.walk(root_dir):
            # Prune ignored directories
            dirs[:] = [d for d in dirs if not should_ignore(os.path.join(root, d), ignore_patterns)]
            
            level = root.replace(root_dir, '').count(os.sep)
            indent = ' ' * 4 * level
            out.write(f"{indent}{os.path.basename(root)}/\n")
            sub_indent = ' ' * 4 * (level + 1)
            for f in files:
                if not should_ignore(os.path.join(root, f), ignore_patterns):
                    out.write(f"{sub_indent}{f}\n")
        
        out.write("```\n\n## File Contents\n\n")

        for root, dirs, files in os.walk(root_dir):
            dirs[:] = [d for d in dirs if not should_ignore(os.path.join(root, d), ignore_patterns)]
            for f in files:
                file_path = os.path.join(root, f)
                if should_ignore(file_path, ignore_patterns):
                    continue
                
                ext = os.path.splitext(f)[1].lower()
                # Skip binary-like files or very large ones
                if ext in ['.iso', '.png', '.jpg', '.pdf', '.exe', '.zip', '.tar', '.gz']:
                    continue
                
                try:
                    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f_in:
                        content = f_in.read()
                        cleaned = clean_content(content, ext)
                        
                        out.write(f"### File: {file_path}\n")
                        out.write(f"```{ext.strip('.') or 'text'}\n")
                        out.write(cleaned)
                        out.write("\n```\n\n")
                except Exception as e:
                    print(f"Error reading {file_path}: {e}")

if __name__ == "__main__":
    main()
