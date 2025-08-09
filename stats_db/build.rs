fn main() -> Result<(), Box<dyn std::error::Error>> {
    prost_build::compile_protos(
        &[
            "proto/command.proto",
            "proto/game_event.proto",
            "proto/game_object.proto",
            "proto/map_geometry.proto",
            "proto/update.proto",
        ],
        &["proto/"],
    )?;
    Ok(())
}
