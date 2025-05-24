use chrono::Local;

fn main() {
    let now = Local::now();
    let iso_string = now.format("%Y-%m-%dT%H:%M:%S%.6f%z").to_string();
    println!("{}", iso_string);
}
