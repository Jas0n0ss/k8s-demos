#!/usr/bin/env python3
import os
import re

README = "README.md"
TOC_START = "<!-- DIRECTORY TOC START -->"
TOC_END = "<!-- DIRECTORY TOC END -->"
HDR_START = "<!-- DIRECTORY HEADERS START -->"
HDR_END = "<!-- DIRECTORY HEADERS END -->"

def github_anchor(name):
    anchor = name.lower()
    anchor = re.sub(r"[^\w\s-]", "", anchor)  # 移除特殊字符
    anchor = anchor.replace(" ", "-")
    return anchor

def walk_dir(base_path, prefix=""):
    toc = []
    headers = []
    for name in sorted(os.listdir(base_path)):
        full_path = os.path.join(base_path, name)
        if os.path.isdir(full_path) and not name.startswith('.') and name != 'scripts':
            anchor = github_anchor(name)
            toc.append(f"{prefix}- [{name}](#{anchor})")
            header_level = prefix.count("  ") + 2  # 根目录 ##, 子目录 ###, 依次增加
            headers.append(f"{'#'*header_level} {name}")
            sub_toc, sub_headers = walk_dir(full_path, prefix + "  ")
            toc += sub_toc
            headers += sub_headers
    return toc, headers

def main():
    toc_lines, header_lines = walk_dir(".")
    
    with open(README, "r", encoding="utf-8") as f:
        content = f.read()

    # 更新 TOC
    start_idx = content.find(TOC_START)
    end_idx = content.find(TOC_END)
    if start_idx != -1 and end_idx != -1:
        content = content[:start_idx+len(TOC_START)] + "\n" + \
                  "\n".join(toc_lines) + "\n" + \
                  content[end_idx:]

    # 更新 Headers
    start_idx = content.find(HDR_START)
    end_idx = content.find(HDR_END)
    if start_idx != -1 and end_idx != -1:
        content = content[:start_idx+len(HDR_START)] + "\n" + \
                  "\n".join(header_lines) + "\n" + \
                  content[end_idx:]

    with open(README, "w", encoding="utf-8") as f:
        f.write(content)

    print("README.md TOC and headers updated successfully!")

if __name__ == "__main__":
    main()
