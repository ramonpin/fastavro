use std::fmt;
use std::borrow::Cow;
use std::ops::Deref;
use rustler::{Decoder, Encoder};

#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct Bin(Vec<u8>);

impl Bin {
    pub fn new<T: Into<Vec<u8>>>(bin: T) -> Self {
        Self(bin.into())
    }

    pub fn to_string_lossy(&self) -> Cow<'_, str> {
        String::from_utf8_lossy(&self.0)
    }
}

impl fmt::Display for Bin {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.to_string_lossy())
    }
}

// By implementing `Deref` to `[u8]`, we can directly call methods defined
// in slice. (e.g. `to_vec(&self)`)
impl Deref for Bin {
    type Target = [u8];

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

// By implementing `From` for &str and &String, we can convert them
// into Bin.
impl From<&str> for Bin {
    fn from(s: &str) -> Self {
        Self::new(s.as_bytes())
    }
}

impl From<&String> for Bin {
    fn from(s: &String) -> Self {
        Self::new(s.as_bytes())
    }
}

impl<'a> Decoder<'a> for Bin {
    fn decode(term: rustler::Term<'a>) -> rustler::NifResult<Self> {
        Ok(Self(
            term.decode::<rustler::Binary<'a>>()?.as_slice().to_vec(),
        ))
    }
}

impl Encoder for Bin {
    fn encode<'a>(&self, env: rustler::Env<'a>) -> rustler::Term<'a> {
        use std::io::Write;

        let mut binary =
            rustler::OwnedBinary::new(self.0.len()).expect("binary term allocation fail");
        binary
            .as_mut_slice()
            .write_all(&self.0)
            .expect("memory copy of &[u8] failed");
        binary.release(env).to_term(env)
    }
}
