"""Extract the SRS text properly.

The earlier attempt decoded one font with a fixed +29 offset and silently
produced garbage for every other font, which is why words like "Prescription"
appeared zero times. This builds a real CID -> Unicode map per font from the
/ToUnicode CMaps (which live inside compressed object streams), tracks which
font each text run selects, and decodes accordingly.
"""
import io
import re
import sys
import zlib

PDF = r"C:/projects/Tobun and Tobun/pholders/frontend-ui/pholders/Pholders SRS-20260422 (1).pdf"
OUT = r"C:/Users/mjmoj/AppData/Local/Temp/claude/c--projects-Tobun-and-Tobun-pholders-website-pholders-app/bfb17bc0-8e3e-4f0e-a36e-d6a26b78807c/scratchpad/srs.txt"

data = open(PDF, 'rb').read()


def inflate_all():
    """Every inflatable stream in the file, with the dict that precedes it."""
    out = []
    for m in re.finditer(rb'stream\r?\n', data):
        start = m.end()
        end = data.find(b'endstream', start)
        if end == -1:
            continue
        header = data[max(0, m.start() - 600):m.start()]
        try:
            out.append((header, zlib.decompress(data[start:end])))
        except Exception:
            continue
    return out


streams = inflate_all()
print('inflated streams:', len(streams))

# --- gather every object body, including those inside object streams ------
objects = {}

for header, body in streams:
    if b'/ObjStm' not in header:
        continue
    n = int(re.search(rb'/N\s+(\d+)', header).group(1))
    first = int(re.search(rb'/First\s+(\d+)', header).group(1))
    pairs = body[:first].split()
    for i in range(n):
        num = int(pairs[2 * i])
        off = int(pairs[2 * i + 1])
        nxt = int(pairs[2 * i + 3]) + first if 2 * i + 3 < len(pairs) else len(body)
        objects[num] = body[first + off:nxt]

# Uncompressed objects too.
for m in re.finditer(rb'(\d+)\s+0\s+obj(.*?)endobj', data, re.S):
    objects.setdefault(int(m.group(1)), m.group(2))

print('objects found:', len(objects))


def parse_cmap(text):
    """CID -> unicode, from a ToUnicode CMap."""
    mapping = {}
    for block in re.findall(rb'beginbfchar(.*?)endbfchar', text, re.S):
        for src, dst in re.findall(rb'<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>', block):
            try:
                mapping[int(src, 16)] = ''.join(
                    chr(int(dst[i:i + 4], 16)) for i in range(0, len(dst), 4))
            except Exception:
                pass
    for block in re.findall(rb'beginbfrange(.*?)endbfrange', text, re.S):
        for lo, hi, dst in re.findall(
                rb'<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>', block):
            lo_i, hi_i, dst_i = int(lo, 16), int(hi, 16), int(dst, 16)
            for k in range(lo_i, min(hi_i, lo_i + 65535) + 1):
                mapping[k] = chr(dst_i + (k - lo_i))
    return mapping


# --- font name -> cmap ----------------------------------------------------
# A font object names its ToUnicode by object number.
cmaps_by_obj = {}
for header, body in streams:
    m = re.search(rb'/ToUnicode', header)
    if m or b'beginbfchar' in body or b'beginbfrange' in body:
        if b'beginbfchar' in body or b'beginbfrange' in body:
            num = re.search(rb'(\d+)\s+0\s+obj', header[-200:] if header else b'')
            cmaps_by_obj[len(cmaps_by_obj)] = parse_cmap(body)

# Match /Fx -> ToUnicode object -> cmap, via each page's /Font resource dict.
font_to_cmap = {}
tounicode_objs = {}
for num, body in objects.items():
    m = re.search(rb'/ToUnicode\s+(\d+)\s+0\s+R', body)
    if m:
        base = re.search(rb'/BaseFont\s*/([#\w+-]+)', body)
        tounicode_objs[num] = (int(m.group(1)), base.group(1) if base else b'?')

# The CMap object bodies are themselves streams; find them by object number.
obj_stream_body = {}
for m in re.finditer(rb'(\d+)\s+0\s+obj(.*?)stream\r?\n', data, re.S):
    num = int(m.group(1))
    start = m.end()
    end = data.find(b'endstream', start)
    if end != -1:
        try:
            obj_stream_body[num] = zlib.decompress(data[start:end])
        except Exception:
            pass

for font_obj, (uni_obj, base) in tounicode_objs.items():
    body = obj_stream_body.get(uni_obj)
    if body:
        font_to_cmap[font_obj] = parse_cmap(body)

print('fonts with a usable ToUnicode map:', len(font_to_cmap))
if not font_to_cmap:
    print('no CMaps recovered — cannot decode reliably')
    sys.exit(2)

# Map the /Fx names used in content streams to those font objects, per page.
name_to_cmap = {}
for num, body in objects.items():
    for name, ref in re.findall(rb'/(F\d+)\s+(\d+)\s+0\s+R', body):
        if int(ref) in font_to_cmap:
            name_to_cmap.setdefault(name.decode(), font_to_cmap[int(ref)])

print('font names resolved:', len(name_to_cmap), sorted(name_to_cmap)[:12])

# --- decode the content streams ------------------------------------------
pieces = []
for header, body in streams:
    if b'TJ' not in body and b'Tj' not in body:
        continue
    current = None
    for tok in re.finditer(rb'/(F\d+)\s+[\d.]+\s+Tf|<([0-9A-Fa-f]+)>|\bTJ\b|\bET\b', body):
        if tok.group(1):
            current = name_to_cmap.get(tok.group(1).decode())
        elif tok.group(2):
            hexs = tok.group(2).decode()
            if len(hexs) % 4:
                continue
            for i in range(0, len(hexs), 4):
                cid = int(hexs[i:i + 4], 16)
                if current is not None:
                    pieces.append(current.get(cid, ''))
                else:
                    ch = cid + 29
                    pieces.append(chr(ch) if 32 <= ch < 0x2500 else '')
    pieces.append('\n')

text = re.sub(r'[ \t]{2,}', ' ', ''.join(pieces))
io.open(OUT, 'w', encoding='utf-8').write(text)
print('wrote', len(text), 'chars to srs.txt')
