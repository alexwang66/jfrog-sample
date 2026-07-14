//! samplecode — JFrog Artifactory Cargo demo crate (WEEX POC).
pub fn greet(name: &str) -> String { format!("Hello, {name}! Served via JFrog Artifactory.") }

#[cfg(test)]
mod tests {
    use super::*;
    #[test] fn it_greets() { assert!(greet("WEEX").contains("WEEX")); }
}
