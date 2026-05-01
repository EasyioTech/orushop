import sys
import json
from graphify.extract import collect_files, extract
from pathlib import Path

def run():
    detect_path = Path('graphify-out/.graphify_detect.json')
    if not detect_path.exists():
        print("Detection file not found")
        return
        
    try:
        content = detect_path.read_text(encoding='utf-16')
    except UnicodeError:
        content = detect_path.read_text(encoding='utf-8')
        
    detect = json.loads(content)
    code_files_raw = detect.get('files', {}).get('code', [])
    code_files = []
    for f in code_files_raw:
        path = Path(f)
        if path.is_dir():
            code_files.extend(collect_files(path))
        else:
            code_files.append(path)
            
    result = extract(code_files, cache_root=Path('.'))
    ast_path = Path('graphify-out/.graphify_ast.json')
    ast_path.write_text(json.dumps(result, indent=2))
    print(f'AST: {len(result["nodes"])} nodes, {len(result["edges"])} edges')

if __name__ == "__main__":
    run()
