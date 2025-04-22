from pathlib import Path
from watermarking import embed_watermark, phash
from detection import add_fingerprint, find_matches
from blockchain import BlockchainRegistry

owner = "alice@example.com"
original = Path("alice.jpg")
watermarked = Path("out/alice_wm.jpg")
fingerprint_hex = embed_watermark(original, watermarked, owner)
print("Watermark hex:", fingerprint_hex)

# register phash in local detection index
image_id = original.stem
add_fingerprint(image_id, phash(original))

# detect
matches = find_matches(watermarked)
print("Detection result:", matches)   # should list (image_id, distance)

# on‑chain proof
bc = BlockchainRegistry(
    contract_address="0xYourContractAddr",
    abi_path="blockchain/contracts/MyMarkRegistry.abi"
)
tx_hash = bc.register(image_id, fingerprint_hex)
print("Tx:", tx_hash, "stored on chain.")
assert bc.get(image_id) == fingerprint_hex