use crate::atoms;
use apache_avro::types::Record;
use apache_avro::Schema;
use rustler::{Error, Term};

pub trait RecordFieldAdder {
    fn add<'a>(&self, record: &mut Record, field: &str, value: Term<'a>)
        -> Result<Term<'a>, Error>;
}

impl RecordFieldAdder for Schema {
    fn add<'a>(
        &self,
        record: &mut Record,
        field: &str,
        value: Term<'a>,
    ) -> Result<Term<'a>, Error> {
        match self {
            Schema::Int => record.put::<i32>(field, value.decode()?),
            Schema::Long => record.put::<i64>(field, value.decode()?),
            Schema::Double => record.put::<f64>(field, value.decode()?),
            Schema::String => record.put::<String>(field, value.decode()?),
            _ => return Err(Error::Term(Box::new(atoms::wrong_type()))),
        }
        return Ok(value);
    }
}
