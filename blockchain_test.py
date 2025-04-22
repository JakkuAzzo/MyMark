from blockchain import registry

print("Contract @", registry.address)

# Try a fresh id every run:
image_id = "demo_image_01"

try:
    tx = registry.register(image_id, "deadbeef" * 8)
    print("Tx:", tx)
except RuntimeError as err:         # already registered
    print("Register skipped:", err)

print("Stored fp:", registry.get(image_id))