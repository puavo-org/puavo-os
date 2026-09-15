use std::hash::{DefaultHasher, Hash, Hasher};

/// Trait for computing a hash value directly
pub trait Hashed: Hash {
    fn hashed(&self) -> u64 {
        let mut hasher = DefaultHasher::new();
        self.hash(&mut hasher);
        hasher.finish()
    }
}

/// Blanket implementation for all types that implement `Hash`
impl<T: Hash> Hashed for T {}
