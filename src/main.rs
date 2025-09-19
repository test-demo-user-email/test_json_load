use serde::{Deserialize, Serialize};
use yew::prelude::*;
use serde_json::from_str;

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct User {
    pub id: u32,
    pub name: String,
    pub email: String,
    pub age: u8,
    pub is_active: bool,
    pub hobbies: Vec<String>,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct Metadata {
    pub total_users: u32,
    pub last_updated: String,
    pub version: String,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct AppData {
    pub users: Vec<User>,
    pub metadata: Metadata,
}

// Load JSON at compile time - this will be bundled into your WASM
const JSON_DATA: &str = include_str!("../static/data.json");

#[function_component(App)]
fn app() -> Html {
    let data = use_state(|| {
        match from_str::<AppData>(JSON_DATA) {
            Ok(data) => {
                web_sys::console::log_1(&"JSON parsed successfully".into());
                Some(data)
            },
            Err(e) => {
                web_sys::console::error_1(&format!("JSON parse error: {} at line {} column {}", e, e.line(), e.column()).into());
                web_sys::console::log_1(&format!("JSON content: {JSON_DATA}").into());
                None
            }
        }
    });

    match &*data {
        Some(app_data) => html! {
            <div class="container">
                <h1>{"User Data from JSON"}</h1>
                <div class="metadata">
                    <h2>{"Metadata"}</h2>
                    <p>{"Total users: "}{app_data.metadata.total_users}</p>
                    <p>{"Last updated: "}{&app_data.metadata.last_updated}</p>
                    <p>{"Version: "}{&app_data.metadata.version}</p>
                </div>
                <h2>{"Users"}</h2>
                {for app_data.users.iter().map(|user| {
                    html! {
                        <div class="user-card" key={user.id}>
                            <div class="user-name">{&user.name}</div>
                            <div class="user-email">{&user.email}</div>
                            <div>{"Age: "}{user.age}</div>
                            <div>{"Status: "}{if user.is_active { "Active" } else { "Inactive" }}</div>
                            <div>{"Hobbies: "}{user.hobbies.join(", ")}</div>
                        </div>
                    }
                })}
            </div>
        },
        None => html! {
            <div class="error">
                <h2>{"Failed to load data"}</h2>
                <p>{"Check that data.json exists in static/ folder and is valid JSON"}</p>
            </div>
        },
    }
}

fn main() {
    yew::Renderer::<App>::new().render();
}