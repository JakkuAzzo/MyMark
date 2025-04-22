"""
Lightweight matching utilities for MyMark.
Currently uses perceptual‑hash Hamming distance; ready for CLIP upgrade later.
"""

from __future__ import annotations
from pathlib import Path
from typing import Dict, List, Tuple
import imagehash
from PIL import Image

HAMMING_THRESHOLD = 10  # tweak for sensitivity (0 = exact)

# In‑memory index  {image_id: hash_hex}
_fingerprint_db: Dict[str, str] = {}


# ---------------------------------------------------------------------------#
# 1.  Index maintenance helpers
# ---------------------------------------------------------------------------#
def add_fingerprint(image_id: str, phash_hex: str) -> None:
    _fingerprint_db[image_id] = phash_hex


def remove_fingerprint(image_id: str) -> None:
    _fingerprint_db.pop(image_id, None)


def all_fingerprints() -> Dict[str, str]:
    return _fingerprint_db.copy()


# ---------------------------------------------------------------------------#
# 2.  Matching
# ---------------------------------------------------------------------------#
def _phash(img_path: Path) -> imagehash.ImageHash:
    from watermarking import phash as compute_phash
    return imagehash.hex_to_hash(compute_phash(img_path))


def find_matches(img_path: str | Path,
                 threshold: int = HAMMING_THRESHOLD) -> List[Tuple[str, int]]:
    """
    Compare `img_path` against every stored fingerprint.
    Returns a list of (image_id, distance) sorted from closest to farthest.
    """
    query_hash = _phash(Path(img_path))
    results = []
    for image_id, fp_hex in _fingerprint_db.items():
        dist = query_hash - imagehash.hex_to_hash(fp_hex)
        if dist <= threshold:
            results.append((image_id, dist))
    return sorted(results, key=lambda t: t[1])