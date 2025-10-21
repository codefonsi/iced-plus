use iced::widget::{button, column, text, text_input, Column};
use key_paths_derive::KeyPaths;

#[derive(Default, KeyPaths)]
struct AppState {
    user: User,
    form: Form,
    counter: i32,
}

#[derive(Default, KeyPaths)]
struct User {
    name: String,
    email: String,
}

#[derive(Default, KeyPaths)]
struct Form {
    email: String,
    password: String,
    notes: String,
}

#[derive(Debug, Clone)]
pub enum Message {
    NameChanged(String),
    EmailChanged(String),
    PasswordChanged(String),
    NotesChanged(String),
    Increment,
    Decrement,
}

impl AppState {
    pub fn view(&self) -> Column<Message> {
        column![
            text("KeyPath Test Example").size(30),
            text(""),
            
            text("User Information:"),
            text_input("Name", &self.user.name)
                .on_input(Message::NameChanged)
                // TODO: When keypath feature is implemented:
                // .id(id_kp!(app_state::user::name()))
                .padding(10),
            
            text_input("Email", &self.user.email)
                .on_input(Message::EmailChanged)
                // TODO: When keypath feature is implemented:
                // .id(id_kp!(app_state::user::email()))
                .padding(10),
            
            text(""),
            text("Form:"),
            text_input("Form Email", &self.form.email)
                .on_input(Message::EmailChanged)
                // TODO: When keypath feature is implemented:
                // .id(id_kp!(app_state::form::email()))
                .padding(10),
            
            text_input("Password", &self.form.password)
                .on_input(Message::PasswordChanged)
                .password()
                // TODO: When keypath feature is implemented:
                // .id(id_kp!(app_state::form::password()))
                .padding(10),
            
            text_input("Notes", &self.form.notes)
                .on_input(Message::NotesChanged)
                // TODO: When keypath feature is implemented:
                // .id(id_kp!(app_state::form::notes()))
                .padding(10),
            
            text(""),
            text(format!("Counter: {}", self.counter)).size(20),
            
            column![
                button("+").on_press(Message::Increment),
                button("-").on_press(Message::Decrement),
            ]
            .spacing(5),
        ]
        .padding(20)
        .spacing(10)
    }

    pub fn update(&mut self, message: Message) {
        match message {
            Message::NameChanged(name) => {
                self.user.name = name;
            }
            Message::EmailChanged(email) => {
                self.user.email = email.clone();
                self.form.email = email;
            }
            Message::PasswordChanged(password) => {
                self.form.password = password;
            }
            Message::NotesChanged(notes) => {
                self.form.notes = notes;
            }
            Message::Increment => {
                self.counter += 1;
            }
            Message::Decrement => {
                self.counter -= 1;
            }
        }
    }
}

fn main() -> iced::Result {
    println!("Starting KeyPath Test Example...");
    println!("This example demonstrates the structure for KeyPath integration.");
    println!("Once the keypath feature is implemented in iced-core, uncomment the .id() calls.");
    
    iced::run("KeyPath Test - Iced", AppState::update, AppState::view)
}

