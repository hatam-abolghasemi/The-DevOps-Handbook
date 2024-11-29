import os
import base64
import hashlib
import argparse
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.fernet import Fernet

# Function to derive a key from a passphrase
def derive_key_from_passphrase(passphrase, salt=None):
    if salt is None:
        salt = os.urandom(16)
    
    kdf = PBKDF2HMAC(
        algorithm=hashlib.sha256(),
        length=32,
        salt=salt,
        iterations=100000,
        backend=default_backend()
    )
    key = base64.urlsafe_b64encode(kdf.derive(passphrase.encode()))
    return key, salt

# Encrypt a text file with a passphrase
def encrypt_file(input_path, output_path, passphrase):
    if not os.path.exists(input_path):
        print(f"Error: Input file '{input_path}' does not exist.")
        return
    
    key, salt = derive_key_from_passphrase(passphrase)
    fernet = Fernet(key)

    with open(input_path, 'rb') as file:
        original_data = file.read()

    encrypted_data = fernet.encrypt(original_data)

    with open(output_path, 'wb') as encrypted_file:
        encrypted_file.write(salt + encrypted_data)
    
    print(f"File '{input_path}' encrypted successfully to '{output_path}' with the provided passphrase.")

# Decrypt a text file with a passphrase
def decrypt_file(input_path, output_path, passphrase):
    if not os.path.exists(input_path):
        print(f"Error: Input file '{input_path}' does not exist.")
        return

    if not input_path.endswith(".encrypted"):
        print("Error: Input file for decryption must have a '.encrypted' extension.")
        return

    with open(input_path, 'rb') as encrypted_file:
        salt = encrypted_file.read(16)  # First 16 bytes are the salt
        encrypted_data = encrypted_file.read()

    key, _ = derive_key_from_passphrase(passphrase, salt)
    fernet = Fernet(key)

    try:
        decrypted_data = fernet.decrypt(encrypted_data)
        with open(output_path, 'wb') as decrypted_file:
            decrypted_file.write(decrypted_data)
        print(f"File '{input_path}' decrypted successfully to '{output_path}' with the provided passphrase.")
    except Exception as e:
        print("Decryption failed. Check if the passphrase is correct.")

# Custom Help Formatter to align help text
class AlignedHelpFormatter(argparse.HelpFormatter):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, max_help_position=35, **kwargs)

# Main function to handle command-line arguments
def main():
    parser = argparse.ArgumentParser(
        description="Encrypt or decrypt a file using a passphrase.",
        formatter_class=AlignedHelpFormatter
    )
    
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Subparser for the encrypt command
    encrypt_parser = subparsers.add_parser("encrypt", help="Encrypt a file", formatter_class=AlignedHelpFormatter)
    encrypt_parser.add_argument("--input", required=True, help="Path to input file")
    encrypt_parser.add_argument("--passphrase", required=True, help="Passphrase for encryption")
    encrypt_parser.add_argument("--output", required=True, help="Path for encrypted file")

    # Subparser for the decrypt command
    decrypt_parser = subparsers.add_parser("decrypt", help="Decrypt a file", formatter_class=AlignedHelpFormatter)
    decrypt_parser.add_argument("--input", required=True, help="Path to encrypted file (.encrypted)")
    decrypt_parser.add_argument("--passphrase", required=True, help="Passphrase for decryption")
    decrypt_parser.add_argument("--output", required=True, help="Path to save the decrypted file")

    args = parser.parse_args()

    if args.command == "encrypt":
        encrypt_file(args.input, args.output, args.passphrase)
    elif args.command == "decrypt":
        decrypt_file(args.input, args.output, args.passphrase)

if __name__ == "__main__":
    main()
