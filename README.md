# MyMark

MyMark is a decentralized, personalized fingerprinting and detection tool designed to protect digital media against unauthorized use. It leverages invisible watermarking, perceptual hashing, and blockchain to allow everybody to mark their images, find all usage of their image / documents and prove ownership in a tamper-resistant, trustless environment.

## Project Aims & Need

**Aims:**
- **Decentralized Ownership & Detection:** Enable image creators to securely embed a unique, imperceptible fingerprint into their media and register it on a blockchain, ensuring immutable proof of ownership.
- **Robust Watermarking & Hashing:** Combine strong watermarking with perceptual hashing (and explore AI-based methods) to detect unauthorized use even after common transformations.
- **User-Friendly Protection:** Develop an end-to-end system that is accessible to individual creators, without relying on centralized digital rights management systems.

**Need:**
According to the project proposal in MYMARK.txt, billions of images are shared online daily and most are misused without proper licensing. Traditional solutions (visible watermarks, centralized content monitoring) are insufficient for individual creators. MyMark addresses the urgent need to:
- Prevent revenue loss and privacy violations.
- Offer a decentralized alternative to prove and enforce intellectual property rights.
- Empower creators by providing a tool that is both robust against adversaries and transparent in its security guarantees.

## Recent Changes

- **TLS & Certificate Generation:**
  - Updated `openssl.cnf` and `run_dev.sh` to generate self-signed certificates with proper key usage (`digitalSignature, keyEncipherment`) and Subject Alternative Names (SAN) for multiple active IPs.
  - Modified Vite config (`frontend/vite.config.js`) to enforce TLSv1.2, include ALPNProtocols (`http/1.1`), and disable client certificate requirements.

- **Testing Enhancements:**
  - Introduced a minimal HTTPS server in `test_https.js` for TLS handshake testing.
  - Added `verify_tls.sh` to check the TLS handshake; current issues include handshake errors with no negotiated cipher.

- **Frontend Migration & UI Updates:**
  - Migrated React components to Vue.js, with updated components for Dashboard, Auth, Upload, Matches, and Stats that follow a “Cubist” style.

- **Blockchain & Detection Modules:**
  - Integrated a lightweight blockchain registry using web3.py to securely store image fingerprints.
  - Enhanced watermark embedding and perceptual hashing functionality.

- **Database & Infrastructure:**
  - Improved database initialization scripts (`generate_db.py`, `init_mongo.sh`) and updated Electron UI setup (`setup_mymark_ui.sh`) for cross-platform accessibility.

## Current Problems

- **TLS Handshake Failures:**
  - Running `sh verify_tls.sh` still produces errors such as:
    - `ssl3_read_bytes:ssl/tls alert handshake failure`
    - **No peer certificate available** and **Cipher is (NONE)**
    - Browser error: `ERR_SSL_VERSION_OR_CIPHER_MISMATCH`
  - Despite corrected certificate parameters, no cipher is negotiated during TLS handshakes.

- **Environmental & Configuration Challenges:**
  - Possible incompatibility between Node.js/TLS defaults and our current TLS settings.
  - Potential interference from network firewalls, antivirus software, or proxy configurations.

## Next Steps

1. **TLS Troubleshooting:**
   - Test the minimal HTTPS server (`test_https.js`) using `openssl s_client -connect 10.186.95.105:5173 -tls1_2` to verify if ALPN's HTTP/1.1 advertisement resolves the handshake issue.
   - Verify Node.js and OpenSSL versions (`node -v` and `node -p process.versions.openssl`) to ensure compatibility.

2. **Environmental Verification:**
   - Disable or reconfigure any local firewalls/antivirus and test on a different network to rule out external interference.
   - Look into additional TLS options or removal of certain settings to revert to Node’s defaults.

3. **Enhanced Logging & Analysis:**
   - Enable detailed TLS handshake logging on the Node/Vite side.
   - Use network monitoring tools (e.g., Wireshark) to capture handshake details for further analysis.

4. **Module & UI Refinements:**
   - Continue integrating and refining blockchain, watermarking, and detection modules.
   - Enhance the user interface and ensure smooth operation across both web and Electron environments.

## Getting Started

1. **Installation:**
   - Install Python dependencies: `pip install -r requirements.txt`
   - In the `frontend` directory, install Node.js dependencies: `npm install`
   - Initialize databases by running `python generate_db.py` and `./init_mongo.sh`
   - Ensure your local blockchain node (Ganache) is running and your contract is deployed.

2. **Running the Application:**
   - Run the combined backend and frontend using: `bash run_dev.sh`
   - Access the app via network addresses (e.g., `https://10.186.95.105:5173/`)

3. **Usage:**
   - Register, log in, and upload your images to get them watermarked and registered.
   - Use the dashboard to check stats, view matches, or trigger scans for unauthorized use.

## Contribution & Future Work

Future work will focus on:
- Resolving persistent TLS handshake issues and refining security configurations.
- Enhancing the AI-based detection capabilities (e.g., integrating CLIP or FaceNet more deeply).
- Expanding blockchain functionalities for robust ownership registration.
- Improving cross-platform UI components and user experience.

Contributions, suggestions, and bug reports are welcome. Please refer to the troubleshooting sections in our documentation for detailed guidance on the current TLS issues and other technical challenges.
