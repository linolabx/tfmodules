#!/usr/bin/env python3
import base64
import json
import sys
from cryptography import x509
from cryptography.hazmat.primitives import hashes

certificate = json.load(sys.stdin)['certificate']

certificate = certificate.strip()

cert_x509 = ""
cert_base64 = ""

if not certificate.startswith("-----BEGIN CERTIFICATE-----"):
    cert_x509 = "-----BEGIN CERTIFICATE-----\n" + certificate + "\n-----END CERTIFICATE-----"
    cert_base64 = certificate
else:
    cert_x509 = certificate
    cert_base64 = certificate.replace("-----BEGIN CERTIFICATE-----\n", "").replace("\n-----END CERTIFICATE-----", "")

print("certificate:",certificate, file=sys.stderr)
print("cert_x509:",cert_x509, file=sys.stderr)
print("cert_base64:",cert_base64, file=sys.stderr)

cert = x509.load_pem_x509_certificate(cert_x509.encode("utf-8"))
fingerprint_sha1 = cert.fingerprint(hashes.SHA1())
fingerprint_sha256 = cert.fingerprint(hashes.SHA256())

def format_fingerprint(fingerprint):
    return ':'.join(fingerprint.hex().upper()[i:i+2] for i in range(0, len(fingerprint.hex()), 2))

print(json.dumps({
    "x509": cert_x509,
    "base64": cert_base64,
    "fingerprint_sha1_base64": base64.b64encode(fingerprint_sha1).decode('utf-8'),
    "fingerprint_sha1_hex": fingerprint_sha1.hex(),
    "fingerprint_sha1_formatted": format_fingerprint(fingerprint_sha1),
    "fingerprint_sha256_base64": base64.b64encode(fingerprint_sha256).decode('utf-8'),
    "fingerprint_sha256_hex": fingerprint_sha256.hex(),
    "fingerprint_sha256_formatted": format_fingerprint(fingerprint_sha256),
}))
