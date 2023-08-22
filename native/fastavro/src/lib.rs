mod binary;
mod record;

use apache_avro::schema::RecordField;
use apache_avro::types::{Record, Value};
use apache_avro::{from_avro_datum, to_avro_datum, Schema};
use binary::Bin;
use record::RecordFieldAdder;
use rustler::types::binary::Binary;
use rustler::{Atom, Encoder, Env, Error, ResourceArc, Term};
use std::collections::HashMap;

// LineFeed ascii code
const ASCII_LF: u8 = 10;

// type Success<T> = (Atom, T);
type SuccessResource<T> = (Atom, ResourceArc<T>);
type ResultResource<T> = Result<SuccessResource<T>, Error>;

mod atoms {
    rustler::atoms! {
        ok,
        all_data_not_read,
        bad_avro_schema,
        field_not_found,
        incompatible_avro_schema,
        not_a_record,
        wrong_type,
    }
}

pub struct SchemaResource {
    pub schema: Schema,
}

pub struct MsgResource {
    pub msg: Value,
}

fn load(env: Env, _: Term) -> bool {
    rustler::resource!(SchemaResource, env);
    rustler::resource!(MsgResource, env);
    true
}

fn error_result<T>(error: Atom) -> Result<(Atom, T), Error> {
    Err(Error::Term(Box::new(error)))
}

fn ok_result<T>(value: T) -> Result<(Atom, T), Error> {
    Ok((atoms::ok(), value))
}

#[rustler::nif]
pub fn read_schema<'a>(schema_str: &str) -> ResultResource<SchemaResource> {
    let parsed = Schema::parse_str(schema_str);

    match parsed {
        Ok(schema) => {
            let schm = schema.clone();
            let resource = ResourceArc::new(SchemaResource { schema: schm });

            return ok_result(resource);
        }

        Err(_) => return error_result(atoms::bad_avro_schema()),
    }
}

fn schema_map(schema: &Schema) -> HashMap<String, &Schema> {
    let fields = match schema {
        Schema::Record { fields, .. } => fields,
        _ => panic!("Only avro records supported"),
    };

    let mut map_fields: HashMap<String, &Schema> = HashMap::new();
    for RecordField { name, schema, .. } in fields {
        map_fields.insert(name.to_string(), schema);
    }

    return map_fields;
}

#[rustler::nif]
pub fn schema_fields(schema_resource: ResourceArc<SchemaResource>) -> HashMap<String, String> {
    let fields = match &schema_resource.schema {
        Schema::Record { fields, .. } => fields,
        _ => panic!("Only avro records supported"),
    };

    let mut map_fields: HashMap<String, String> = HashMap::new();
    for RecordField { name, schema, .. } in fields {
        map_fields.insert((*name).to_string(), format!("{:?}", *schema));
    }

    return map_fields;
}

#[rustler::nif]
pub fn create_msg<'a>(
    map: HashMap<String, Term>,
    schema_resource: ResourceArc<SchemaResource>,
) -> ResultResource<MsgResource> {
    let mut record = Record::new(&schema_resource.schema).unwrap();
    let fields = schema_map(&schema_resource.schema);

    for (k, v) in map {
        match fields[&k] {
            Schema::Int => record.put::<i64>(&k, v.decode().unwrap()),
            Schema::Long => record.put::<i64>(&k, v.decode().unwrap()),
            Schema::Double => record.put::<f64>(&k, v.decode().unwrap()),
            Schema::String => record.put::<String>(&k, v.decode().unwrap()),
            _ => return error_result(atoms::wrong_type()),
        }
    }

    let msg_resource = ResourceArc::new(MsgResource { msg: record.into() });

    return ok_result(msg_resource);
}

fn convert_to_hashmap<'a>(env: Env<'a>, val: &Vec<(String, Value)>) -> HashMap<String, Term<'a>> {
    let mut res: HashMap<String, Term> = HashMap::new();
    for (k, v) in val {
        res.insert(k.to_string(), get_value_term(env, v));
    }

    return res;
}

#[rustler::nif]
pub fn to_map<'a>(
    env: Env<'a>,
    msg_resource: ResourceArc<MsgResource>,
) -> HashMap<String, Term<'a>> {
    let fields = match &msg_resource.msg {
        Value::Record(fields) => fields,
        _ => panic!("Only avro records supported."),
    };

    return convert_to_hashmap(env, fields);
}

fn get_value_term<'a>(env: Env<'a>, value: &Value) -> Term<'a> {
    match value {
        Value::Long(num) => num.encode(env),
        Value::Int(num) => num.encode(env),
        Value::Double(num) => num.encode(env),
        Value::String(string) => string.encode(env),
        _ => atoms::wrong_type().encode(env),
    }
}

#[rustler::nif]
fn decode_avro_datum(
    avro_data: Term,
    schema_resource: ResourceArc<SchemaResource>,
) -> ResultResource<MsgResource> {
    let schema = &schema_resource.schema;
    let mut bytes = Binary::from_iolist(avro_data).unwrap().as_slice();

    let datum = from_avro_datum(schema, &mut bytes, Some(schema));

    // Skip error when remaining bytes is just a LineFeed
    if !(bytes.is_empty() || bytes == [ASCII_LF]) {
        return error_result(atoms::all_data_not_read());
    }

    match datum {
        Ok(value) => {
            let avro_msg = ResourceArc::new(MsgResource { msg: value });
            return ok_result(avro_msg);
        }

        Err(_) => error_result(atoms::incompatible_avro_schema()),
    }
}

#[rustler::nif]
fn encode_avro_datum<'a>(
    avro_map: HashMap<String, Term>,
    schema_resource: ResourceArc<SchemaResource>,
) -> Result<(Atom, Bin), Error> {
    let schema = &schema_resource.schema;
    let mut record = Record::new(schema).unwrap();
    let fields = schema_map(schema);

    for (k, v) in avro_map {
        if fields.contains_key(&k) {
            match (*fields[&k]).add(&mut record, &k, v) {
                Ok(_) => (),
                Err(_error) => return error_result(atoms::incompatible_avro_schema()),
            }
        } else {
            return error_result(atoms::field_not_found());
        }
    }

    let encoded_avro_result = to_avro_datum(schema, record);
    match encoded_avro_result {
        Ok(encoded_avro) => return ok_result(Bin::new(encoded_avro)),
        Err(_) => return error_result(atoms::incompatible_avro_schema()),
    }
}

#[rustler::nif]
fn get_avro_value<'a>(
    env: Env<'a>,
    msg_resource: ResourceArc<MsgResource>,
    name: String,
) -> Result<(Atom, Term<'a>), Error> {
    let msg = &msg_resource.msg;

    match msg {
        Value::Record(fields) => {
            for (field_name, value) in fields {
                if field_name.to_string() == name {
                    return ok_result(get_value_term(env, value));
                }
            }
            return error_result(atoms::field_not_found());
        }

        _ => return error_result(atoms::not_a_record()),
    }
}

#[rustler::nif]
fn get_raw_value<'a>(
    env: Env<'a>,
    avro_data: Term,
    schema_resource: ResourceArc<SchemaResource>,
    name: String,
) -> Result<(Atom, Term<'a>), Error> {
    let schema = &schema_resource.schema;
    let mut bytes = avro_data.decode::<Binary>().unwrap().as_slice();
    let datum = from_avro_datum(schema, &mut bytes, Some(schema));

    // Skip error when remaining bytes is just a LineFeed
    if !(bytes.is_empty() || bytes == [ASCII_LF]) {
        return error_result(atoms::all_data_not_read());
    }

    match datum {
        Ok(value) => match value {
            Value::Record(fields) => {
                for (field_name, value) in fields {
                    if field_name.to_string() == name {
                        return ok_result(get_value_term(env, &value));
                    }
                }
                return error_result(atoms::field_not_found());
            }

            _ => return error_result(atoms::not_a_record()),
        },

        Err(_) => {
            return error_result(atoms::incompatible_avro_schema());
        }
    }
}

#[rustler::nif]
fn get_raw_values<'a>(
    env: Env<'a>,
    avro_data: Term,
    schema_resource: ResourceArc<SchemaResource>,
    names: Vec<String>,
) -> Result<(Atom, HashMap<String, Term<'a>>), Error> {
    let schema = &schema_resource.schema;
    let mut bytes = avro_data.decode::<Binary>().unwrap().as_slice();

    let value = from_avro_datum(schema, &mut bytes, None).unwrap();
    let mut values: HashMap<String, Term> = HashMap::new();

    match value {
        Value::Record(fields) => {
            for (field_name, value) in fields {
                if names.contains(&field_name) {
                    values.insert(field_name, get_value_term(env, &value));
                }
            }

            let mut found_fields: Vec<String> = Vec::new();
            found_fields.extend(values.clone().into_keys());
            for field_name in names {
                if !found_fields.contains(&field_name) {
                    return error_result(atoms::field_not_found());
                }
            }

            return ok_result(values);
        }

        _ => error_result(atoms::not_a_record()),
    }
}

// Declare Nifs to export
rustler::init!(
    "Elixir.FastAvro",
    [
        create_msg,
        decode_avro_datum,
        encode_avro_datum,
        get_avro_value,
        get_raw_value,
        get_raw_values,
        read_schema,
        schema_fields,
        to_map,
    ],
    load = load
);
