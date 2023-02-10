use std::io::Result;

fn main() -> Result<()> {
    println!("cargo:rerun-if-changed=src/proto/");
    prost_build::Config::new()
        .type_attribute(".", "#[derive(serde::Serialize, serde::Deserialize)]")
        .field_attribute(
            "type",
            "#[serde(deserialize_with = \"crate::componet::col_type_from_str\")]",
        )
        .field_attribute(
            "affix",
            "#[serde(deserialize_with = \"crate::componet::affix_from_str\")]",
        )
        .compile_protos(
            &[
                "src/proto/componet.proto",
                "src/proto/componet.metadata.proto",
                "src/proto/componet.graph.proto",
            ],
            &["src/proto/"],
        )
        .expect("Failed to compile protos");
    Ok(())
}
