#!/usr/bin/env python3
"""
Mechanical steps of the Coursiv note pipeline: strip frontmatter, embed
remote images as base64, and make sure a '## Quiz' heading exists at the
end of the file. Quiz *content* is intentionally NOT generated here -- that
part needs the course text and the rules in quiz_course.md in front of an
LLM, so it's done by Claude after this script runs (see SKILL.md).

Usage:
    python3 process_note.py prep <note_path> [--scratch DIR]
    python3 process_note.py verify <note_path> --expected-images N

Design notes (learned the hard way on the first manual run of this task):
- Once images are embedded the note file can become hundreds of KB on a
  single line each. Never assume it is small. This script streams /
  line-processes the file instead of doing giant in-memory regex sweeps
  where avoidable, and callers (the SKILL) must append the quiz text with
  a plain file append, not by re-reading the whole file into a chat tool.
- Images are frequently served with a misleading extension (e.g. a file
  named *.jpg that is actually a PNG). Content type is sniffed from the
  downloaded bytes' magic number, never guessed from the URL.
- All downloads/encoding happen in a scratch directory that is deleted
  before this script exits, successfully or not.
"""
import argparse
import base64
import io
import re
import shutil
import sys
import tempfile
import urllib.request
from pathlib import Path

try:
    from PIL import Image
except ImportError:  # noqa: BLE001 - compression is best-effort, not a hard dependency
    Image = None

IMAGE_LINK_RE = re.compile(r'!\[([^\]]*)\]\((https?://[^)\s]+)\)')

MAGIC_SIGNATURES = [
    (b'\x89PNG\r\n\x1a\n', 'image/png'),
    (b'\xff\xd8\xff', 'image/jpeg'),
    (b'GIF87a', 'image/gif'),
    (b'GIF89a', 'image/gif'),
    (b'RIFF', 'image/webp'),  # followed by 'WEBP' at offset 8, checked below
    (b'BM', 'image/bmp'),
]

# Lesson screenshots embedded as raw PNG routinely blow a note past 5MB and
# stall Obsidian's editor. Downscale + re-encode as JPEG before embedding so
# a lesson with a dozen images stays well under 1.5MB. GIFs are left alone
# since re-encoding as JPEG would drop animation.
COMPRESS_MAX_WIDTH = 1200
COMPRESS_JPEG_QUALITY = 65


def sniff_mime(data: bytes) -> str:
    for sig, mime in MAGIC_SIGNATURES:
        if data.startswith(sig):
            if mime == 'image/webp' and data[8:12] != b'WEBP':
                continue
            return mime
    return 'application/octet-stream'


def compress_image(data: bytes, mime: str) -> tuple[bytes, str]:
    """Downscale + re-encode a lesson screenshot as JPEG to keep notes small.
    Returns (possibly-recompressed bytes, possibly-updated mime). Falls back
    to the original bytes untouched if PIL is unavailable, the image is a
    GIF (would lose animation), or decoding fails for any reason."""
    if Image is None or mime == 'image/gif':
        return data, mime
    try:
        img = Image.open(io.BytesIO(data))
        if img.mode in ('RGBA', 'P'):
            img = img.convert('RGB')
        w, h = img.size
        if w > COMPRESS_MAX_WIDTH:
            new_h = int(h * (COMPRESS_MAX_WIDTH / w))
            img = img.resize((COMPRESS_MAX_WIDTH, new_h), Image.LANCZOS)
        out = io.BytesIO()
        img.save(out, format='JPEG', quality=COMPRESS_JPEG_QUALITY, optimize=True)
        compressed = out.getvalue()
    except Exception:  # noqa: BLE001 - keep original bytes if anything goes wrong
        return data, mime
    if len(compressed) < len(data):
        return compressed, 'image/jpeg'
    return data, mime


def strip_frontmatter(text: str) -> str:
    if not text.startswith('---'):
        return text
    lines = text.split('\n')
    if lines[0].strip() != '---':
        return text
    for i in range(1, len(lines)):
        if lines[i].strip() == '---':
            rest = '\n'.join(lines[i + 1:])
            return rest.lstrip('\n')
    # unterminated frontmatter fence -- leave the file alone, something's off
    return text


def ensure_quiz_heading(text: str) -> str:
    if re.search(r'^##\s+Quiz\s*$', text, flags=re.MULTILINE):
        return text
    if not text.endswith('\n'):
        text += '\n'
    return text + '\n## Quiz\n'


def embed_images(text: str, scratch: Path) -> tuple[str, int, list[str]]:
    """Download every remote image link, replace it with a base64 data URI.
    Returns (new_text, count_embedded, failed_urls)."""
    scratch.mkdir(parents=True, exist_ok=True)
    seen = {}
    failed = []

    def replace(match: re.Match) -> str:
        alt, url = match.group(1), match.group(2)
        if url in seen:
            return f'![{alt}]({seen[url]})'
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = resp.read()
        except Exception as exc:  # noqa: BLE001 - report and keep the original link
            failed.append(f'{url} ({exc})')
            return match.group(0)
        mime = sniff_mime(data)
        data, mime = compress_image(data, mime)
        b64 = base64.b64encode(data).decode('ascii')
        data_uri = f'data:{mime};base64,{b64}'
        seen[url] = data_uri
        return f'![{alt}]({data_uri})'

    new_text = IMAGE_LINK_RE.sub(replace, text)
    return new_text, len(seen), failed


def cmd_prep(args: argparse.Namespace) -> None:
    note_path = Path(args.note_path)
    if not note_path.exists():
        sys.exit(f'ERROR: note not found: {note_path}')

    original = note_path.read_text(encoding='utf-8')
    had_frontmatter = original.startswith('---')

    text = strip_frontmatter(original)

    scratch = Path(args.scratch) if args.scratch else Path(tempfile.mkdtemp(prefix='coursiv_'))
    own_scratch = not args.scratch
    try:
        text, embedded, failed = embed_images(text, scratch)
    finally:
        if own_scratch:
            shutil.rmtree(scratch, ignore_errors=True)

    text = ensure_quiz_heading(text)

    note_path.write_text(text, encoding='utf-8')

    print(f'frontmatter_removed={had_frontmatter}')
    print(f'images_embedded={embedded}')
    print(f'images_failed={len(failed)}')
    for f in failed:
        print(f'  FAILED: {f}')
    print('quiz_heading_ready=True')


def cmd_verify(args: argparse.Namespace) -> None:
    note_path = Path(args.note_path)
    text = note_path.read_text(encoding='utf-8')

    ok = True

    if text.lstrip().startswith('---'):
        print('FAIL: frontmatter still present')
        ok = False
    else:
        print('OK: no frontmatter')

    remote_links = len(re.findall(r'!\[[^\]]*\]\(https?://', text))
    if remote_links:
        print(f'FAIL: {remote_links} remote image link(s) remain')
        ok = False
    else:
        print('OK: no remote image links')

    embedded = len(re.findall(r'!\[[^\]]*\]\(data:image/', text))
    print(f'INFO: {embedded} base64-embedded image(s) found')
    if args.expected_images is not None and embedded != args.expected_images:
        print(f'FAIL: expected {args.expected_images} embedded image(s), found {embedded}')
        ok = False

    quiz_blocks = len(re.findall(r'^```quiz\s*$', text, flags=re.MULTILINE))
    if quiz_blocks == 0:
        print('FAIL: no ```quiz blocks found')
        ok = False
    else:
        print(f'OK: {quiz_blocks} quiz block(s) found')

    if not ok:
        sys.exit(1)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)

    p_prep = sub.add_parser('prep', help='strip frontmatter, embed images, ensure Quiz heading')
    p_prep.add_argument('note_path')
    p_prep.add_argument('--scratch', help='scratch dir for downloads (auto-created & removed if omitted)')
    p_prep.set_defaults(func=cmd_prep)

    p_verify = sub.add_parser('verify', help='sanity-check a processed note')
    p_verify.add_argument('note_path')
    p_verify.add_argument('--expected-images', type=int, default=None)
    p_verify.set_defaults(func=cmd_verify)

    args = parser.parse_args()
    args.func(args)


if __name__ == '__main__':
    main()
