package crypto

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"io"

	"golang.org/x/crypto/pbkdf2"
)

const (
	keySize   = 32 // AES-256
	saltSize  = 32
	iterations = 100000
)

// DeriveKey derives an encryption key from a password using PBKDF2
func DeriveKey(password string, salt []byte) []byte {
	return pbkdf2.Key([]byte(password), salt, iterations, keySize, sha256.New)
}

// GenerateSalt generates a random salt
func GenerateSalt() ([]byte, error) {
	salt := make([]byte, saltSize)
	if _, err := rand.Read(salt); err != nil {
		return nil, err
	}
	return salt, nil
}

// Encrypt encrypts plaintext using AES-256-GCM
func Encrypt(plaintext string, key []byte) (ciphertext string, iv string, err error) {
	block, err := aes.NewCipher(key)
	if err != nil {
		return "", "", err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", "", err
	}

	nonce := make([]byte, gcm.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return "", "", err
	}

	ciphertextBytes := gcm.Seal(nil, nonce, []byte(plaintext), nil)
	
	return base64.StdEncoding.EncodeToString(ciphertextBytes),
		base64.StdEncoding.EncodeToString(nonce),
		nil
}

// Decrypt decrypts ciphertext using AES-256-GCM
func Decrypt(ciphertext string, iv string, key []byte) (string, error) {
	ciphertextBytes, err := base64.StdEncoding.DecodeString(ciphertext)
	if err != nil {
		return "", err
	}

	nonceBytes, err := base64.StdEncoding.DecodeString(iv)
	if err != nil {
		return "", err
	}

	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	if len(nonceBytes) != gcm.NonceSize() {
		return "", errors.New("invalid nonce size")
	}

	plaintext, err := gcm.Open(nil, nonceBytes, ciphertextBytes, nil)
	if err != nil {
		return "", err
	}

	return string(plaintext), nil
}
