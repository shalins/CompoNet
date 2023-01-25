use wasm_bindgen::prelude::*;

// These are JavaScript functions that we can call from RUST.

#[wasm_bindgen]
extern {
    pub fn alert(s: &str);
}

// These are RUST functions that we can call from JavaScript.

#[wasm_bindgen]
pub fn greet(name: &str) {
    alert(&format!("Hello, {}!", name));
}

