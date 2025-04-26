#!/bin/bash
openssl s_client -connect 10.186.95.105:5173 -tls1_2
# Examine the negotiated protocol and cipher suite in the output.
