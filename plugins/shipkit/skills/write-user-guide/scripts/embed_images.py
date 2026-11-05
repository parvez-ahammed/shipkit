"""Write a copy of an HTML guide with every local <img> embedded, so the copy is one file to attach.

Usage: python embed_images.py <guide.html> <out.html>
The source keeps its relative image paths, so it stays small enough to edit. Images already embedded
or on http(s) are left alone. Exits non-zero when an image file is missing.
"""
import base64
import mimetypes
import pathlib
import re
import sys

if len(sys.argv) != 3:
    sys.exit("Usage: python embed_images.py <guide.html> <out.html>")
html, out = (pathlib.Path(p).resolve() for p in sys.argv[1:3])
if html == out:
    sys.exit("Write the copy to a different path: the source must keep its image paths.")
text = html.read_text(encoding="utf-8")
missing, embedded = [], 0


def inline(match):
    global embedded
    src = match.group(2)
    if src.startswith(("data:", "http://", "https://")):
        return match.group(0)
    path = (html.parent / src).resolve()
    if not path.is_file():
        missing.append(src)
        return match.group(0)
    mime = mimetypes.guess_type(path.name)[0] or "image/png"
    embedded += 1
    data = base64.b64encode(path.read_bytes()).decode("ascii")
    return f'{match.group(1)}data:{mime};base64,{data}{match.group(3)}'


text = re.sub(r'(<img\b[^>]*?\bsrc=")([^"]+)(")', inline, text)
if missing:
    sys.exit("Missing image files: " + ", ".join(missing))
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(text, encoding="utf-8", newline="\n")
print(f"{out}: embedded {embedded} image(s), {out.stat().st_size // 1024} KB")
