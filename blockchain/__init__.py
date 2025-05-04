"""
Tiny helper around web3.py to talk to the MyMarkRegistry contract.
Assumes a local Ganache node running at http://127.0.0.1:8545
"""

from __future__ import annotations
from pathlib import Path
from typing import Optional
import json

from web3 import Web3
from web3.exceptions import ContractLogicError
from eth_account import Account

# ── local‑chain defaults — change if you redeploy ────────────────────────
GANACHE_URL = "http://127.0.0.1:8545"
CHAIN_DEFAULT_ADDRESS = "0x8Ff8f74f5e232f0E102529ef14Fdc4ea5938A8b2"
DEFAULT_PRIVATE_KEY = (
    "0x1c044346705be2a7c983898a63f95a6129c0eeddb078127e40c40249b8935b67"
)

ABI_PATH = (
    Path(__file__).parent / "contracts" / "build" / "MyMarkRegistry.abi"
)

# ─────────────────────────────────────────────────────────────────────────


def _load_abi(path: Path) -> list[dict]:
    if not path.exists():
        raise FileNotFoundError(
            f"{path} not found – compile Solidity first (solc --abi ... -o build)"
        )
    with path.open() as f:
        return json.load(f)


def _b32(value: str) -> bytes:
    """Pack a UTF‑8 string into 32 bytes (truncate or keccak‑256)."""
    b = value.encode()
    return b[:32].ljust(32, b"\0") if len(b) <= 32 else Web3.keccak(b)


class BlockchainRegistry:
    """Light wrapper around a deployed MyMarkRegistry contract."""

    def __init__(
        self,
        contract_address: str = CHAIN_DEFAULT_ADDRESS,
        abi_path: str | Path = ABI_PATH,
        provider_url: str = GANACHE_URL,
        priv_key: str = DEFAULT_PRIVATE_KEY,
        connect: bool = True,  # NEW: allow skipping connection for dev/test
    ):
        if connect:
            self.web3 = Web3(Web3.HTTPProvider(provider_url))
            if not self.web3.is_connected():
                print(f"WARNING: Cannot reach node at {provider_url}. Blockchain features will be disabled.")
                self.web3 = None
                self.account = None
                self.contract = None
                self._enabled = False
                return
            self.account = Account.from_key(priv_key)
            self.contract = self.web3.eth.contract(
                address=self.web3.to_checksum_address(contract_address),
                abi=_load_abi(Path(abi_path)),
            )
            self._enabled = True
        else:
            self.web3 = None
            self.account = None
            self.contract = None
            self._enabled = False

    # ── write ────────────────────────────────────────────────────────────
    def register(self, image_id: str, fingerprint_hex: str) -> str:
        """
        Store fingerprint on‑chain (only once per image_id).
        Returns the tx hash. Raises ContractLogicError if already registered.
        """
        func = self.contract.functions.register(_b32(image_id), _b32(fingerprint_hex))
        tx_dict = func.build_transaction(
            {
                "from": self.account.address,
                "nonce": self.web3.eth.get_transaction_count(self.account.address),
                "gas": int(func.estimate_gas({"from": self.account.address}) * 1.10),
                "gasPrice": self.web3.to_wei("2", "gwei"),
                "chainId": self.web3.eth.chain_id,
            }
        )
        signed = self.account.sign_transaction(tx_dict)
        raw_tx = getattr(signed, "rawTransaction", signed.raw_transaction)  # v5|v6
        try:
            tx_hash = self.web3.eth.send_raw_transaction(raw_tx)
        except ContractLogicError as e:
            # Re‑raise with cleaner message for the caller
            raise RuntimeError(e.args[0]) from None

        self.web3.eth.wait_for_transaction_receipt(tx_hash)
        return tx_hash.hex()

    # ── read ─────────────────────────────────────────────────────────────
        # ─────────────────────────────── read ───────────────────────────────
    def get(self, image_id: str) -> Optional[str]:
        """
        Return fingerprint hex for image_id, or None if it hasn't been registered.
        """
        fp_bytes: bytes = self.contract.functions.fingerprints(_b32(image_id)).call()

        # mapping returns 32 zero bytes if the key isn't set
        if fp_bytes == b"\0" * 32:
            return None

        return fp_bytes.hex()

    # ── misc ─────────────────────────────────────────────────────────────
    @property
    def address(self) -> str:
        return self.contract.address


# Convenience singleton (importing modules can just use `registry`)
try:
    registry = BlockchainRegistry()
except Exception as e:
    print(f"BlockchainRegistry init failed: {e}")
    # Fallback: create a dummy registry with blockchain disabled
    registry = BlockchainRegistry(connect=False)