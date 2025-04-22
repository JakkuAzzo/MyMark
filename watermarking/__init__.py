"""
Simple invisible‑watermark & perceptual‑hash helpers for MyMark
⚠️  NOT bullet‑proof against a hostile adversary – good enough for MVP demo.
"""

from pathlib import Path
import hashlib
import random
import cv2
import numpy as np
from PIL import Image
import imagehash

# ---------------------------------------------------------------------------#
# 1.  Perceptual hash wrapper
# ---------------------------------------------------------------------------#
def phash(img_path: Path) -> str:
    """Return hexadecimal 64‑bit perceptual hash for an image file."""
    return str(imagehash.phash(Image.open(img_path)))


# ---------------------------------------------------------------------------#
# 2.  Invisible watermark ‑ LSB on blue channel (quick & dirty)
# ---------------------------------------------------------------------------#
def _owner_key(owner_id: str) -> bytes:
    """Derive a deterministic 256‑bit key from the owner's ID/email."""
    return hashlib.sha256(owner_id.encode("utf‑8")).digest()


def embed_watermark(src: str | Path,
                    dst: str | Path,
                    owner_id: str,
                    density: float = 0.02) -> str:
    """
    Embed a pseudo‑random watermark keyed by `owner_id` into the LSB of the
    blue channel. Returns the same 256‑bit hex string written.
    """
    src, dst = Path(src), Path(dst)
    img = cv2.imread(str(src))
    if img is None:
        raise RuntimeError(f"Cannot read image: {src}")

    h, w = img.shape[:2]
    n_pixels = int(h * w * density)
    rng = random.Random(_owner_key(owner_id))       # deterministic RNG
    coords = rng.sample(range(h * w), n_pixels)

    # The watermark bits are the sha256 of (image_phash + owner_id)
    bits_hex = hashlib.sha256((phash(src) + owner_id).encode()).hexdigest()
    bits = bin(int(bits_hex, 16))[2:].zfill(256)

    # Write each bit into the LSB of selected pixels’ blue channel
    idx = 0
    for coord in coords:
        if idx >= len(bits):
            break
        y, x = divmod(coord, w)
        img[y, x, 0] = (img[y, x, 0] & ~1) | int(bits[idx])
        idx += 1

    cv2.imwrite(str(dst), img, [int(cv2.IMWRITE_JPEG_QUALITY), 90])
    return bits_hex  # fingerprint we’ll also store on‑chain


def extract_watermark(img_path: str | Path,
                      owner_id: str,
                      density: float = 0.02) -> str:
    """
    Extract 256‑bit hex watermark using the same pixel positions.
    Returns the hex string; caller can compare to expected.
    """
    img_path = Path(img_path)
    img = cv2.imread(str(img_path))
    if img is None:
        raise RuntimeError(f"Cannot read image: {img_path}")

    h, w = img.shape[:2]
    n_pixels = int(h * w * density)
    rng = random.Random(_owner_key(owner_id))
    coords = rng.sample(range(h * w), n_pixels)

    bits = []
    for coord in coords[:256]:      # read first 256 bits
        y, x = divmod(coord, w)
        bits.append(str(img[y, x, 0] & 1))
    return hex(int("".join(bits), 2))[2:].zfill(64)