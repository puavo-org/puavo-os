//! The key pair made for one request. The recovery key comes back
//! encrypted to its public half, so only this device can read it.

use log::debug;
use rsa::pkcs8::{DecodePrivateKey, EncodePrivateKey, EncodePublicKey};
use rsa::rand_core::OsRng;
use rsa::{Oaep, RsaPrivateKey};
use sha2::Sha256;
use zeroize::Zeroizing;

const KEY_BITS: usize = 3072;

/// A key pair whose private half is wiped from memory when it is dropped.
pub struct ReturnKey(RsaPrivateKey);

impl ReturnKey {
    pub fn new() -> Result<Self, rsa::Error> {
        debug!("making a return key");
        RsaPrivateKey::new(&mut OsRng, KEY_BITS).map(ReturnKey)
    }

    /// A key pair saved as DER PKCS#8.
    pub fn from_pkcs8_der(der: &[u8]) -> Result<Self, rsa::Error> {
        RsaPrivateKey::from_pkcs8_der(der)
            .map(ReturnKey)
            .map_err(|_| rsa::Error::Internal)
    }

    /// The key pair as DER PKCS#8, to continue after the device was off.
    pub fn to_pkcs8_der(&self) -> Result<Zeroizing<Vec<u8>>, rsa::Error> {
        let document =
            self.0.to_pkcs8_der().map_err(|_| rsa::Error::Internal)?;
        Ok(Zeroizing::new(document.as_bytes().to_vec()))
    }

    /// The public half as DER SubjectPublicKeyInfo.
    pub fn public_der(&self) -> Result<Vec<u8>, rsa::Error> {
        let document = self
            .0
            .to_public_key()
            .to_public_key_der()
            .map_err(|_| rsa::Error::Internal)?;
        Ok(document.into_vec())
    }

    /// Decrypts what was encrypted to the public half with RSA OAEP and
    /// SHA 256.
    pub fn decrypt(
        &self,
        ciphertext: &[u8],
    ) -> Result<Zeroizing<Vec<u8>>, rsa::Error> {
        self.0.decrypt(Oaep::new::<Sha256>(), ciphertext).map(Zeroizing::new)
    }
}
