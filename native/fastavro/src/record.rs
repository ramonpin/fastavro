use crate::atoms;
use apache_avro::{
    types::{Record, Value},
    Schema, Duration, Months, Days, Millis
};
use rustler::{Error, Term};
use std::collections::HashMap;

fn term_to_value<'a>(term: Term<'a>, schema: &Schema) -> Result<Value, Error> {
    match schema {
        Schema::Null => {
            let _: () = term.decode()?;
            Ok(Value::Null)
        }
        Schema::Boolean => term.decode().map(Value::Boolean),
        Schema::Int => term.decode().map(Value::Int),
        Schema::Long => term.decode().map(Value::Long),
        Schema::Float => term.decode().map(Value::Float),
        Schema::Double => term.decode().map(Value::Double),
        Schema::Bytes => term.decode().map(Value::Bytes),
        Schema::String => term.decode().map(Value::String),
        Schema::Array(inner_schema) => {
            let terms: Vec<Term> = term.decode()?;
            let values: Result<Vec<Value>, _> = terms
                .into_iter()
                .map(|t| term_to_value(t, &inner_schema.items))
                .collect();
            Ok(Value::Array(values?))
        }
        Schema::Map(inner_schema) => {
            let map: HashMap<String, Term> = term.decode()?;
            let mut values = HashMap::new();
            for (k, v) in map {
                values.insert(k, term_to_value(v, &inner_schema.types)?);
            }
            Ok(Value::Map(values))
        }
        Schema::Union(union_schema) => {
            if term.decode::<()>().is_ok() {
                // Find the null schema in the union and return a Union with the correct index.
                for (i, variant_schema) in union_schema.variants().iter().enumerate() {
                    if let Schema::Null = variant_schema {
                        return Ok(Value::Union(i as u32, Box::new(Value::Null)));
                    }
                }
            }

            // This is a simplified implementation that tries to decode the term into each of the types in the union.
            for (i, variant_schema) in union_schema.variants().iter().enumerate() {
                if let Ok(value) = term_to_value(term, variant_schema) {
                    return Ok(Value::Union(i as u32, Box::new(value)));
                }
            }
            Err(Error::Term(Box::new(atoms::wrong_type())))
        }
        Schema::Record(record_schema) => {
            let map: HashMap<String, Term> = term.decode()?;
            let mut record = Record::new(schema).unwrap();
            for field in &record_schema.fields {
                if let Some(term) = map.get(&field.name) {
                    let value = term_to_value(*term, &field.schema)?;
                    record.put(&field.name, value);
                } else if field.default.is_some() {
                    // Default value is handled by `to_avro_datum`
                } else {
                    return Err(Error::Term(Box::new(atoms::field_not_found())));
                }
            }
            Ok(record.into())
        }
        Schema::Enum { .. } => Ok(Value::String(term.decode()?)),
        Schema::Fixed(fixed_schema) => Ok(Value::Fixed(fixed_schema.size, term.decode()?)),
        Schema::Decimal { .. } => {
            let bytes: Vec<u8> = term.decode()?;
            Ok(Value::String(format!("{:?}", bytes)))
        }
        Schema::Uuid => Ok(Value::Uuid(term.decode::<String>()?.parse().unwrap())),
        Schema::Date => Ok(Value::Date(term.decode()?)),
        Schema::TimeMillis => Ok(Value::TimeMillis(term.decode()?)),
        Schema::TimeMicros => Ok(Value::TimeMicros(term.decode()?)),
        Schema::TimestampMillis => Ok(Value::TimestampMillis(term.decode()?)),
        Schema::TimestampMicros => Ok(Value::TimestampMicros(term.decode()?)),
        Schema::TimestampNanos => Ok(Value::TimestampNanos(term.decode()?)),
        Schema::LocalTimestampMillis => Ok(Value::LocalTimestampMillis(term.decode()?)),
        Schema::LocalTimestampMicros => Ok(Value::LocalTimestampMicros(term.decode()?)),
        Schema::LocalTimestampNanos => Ok(Value::LocalTimestampNanos(term.decode()?)),
        Schema::Duration { .. } => {
            let map: HashMap<String, u32> = term.decode()?;
            let months = Months::new(map.get("months").map_or(0, |v| *v));
            let days = Days::new(map.get("days").map_or(0, |v| *v));
            let millis = Millis::new(map.get("millis").map_or(0, |v| *v));
            Ok(Value::Duration(Duration::new(
                months, days, millis,
            )))
        }
        Schema::BigDecimal => Ok(Value::BigDecimal(term.decode::<String>()?.parse().unwrap())),
        Schema::Ref { .. } => Err(Error::Term(Box::new(atoms::wrong_type()))),
    }
}

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
        let avro_value = term_to_value(value, self)?;
        record.put(field, avro_value);
        Ok(value)
    }
}
