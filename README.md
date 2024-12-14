
# AIR App

A Flutter-based application designed to integrate with a humanoid robot named AIR. The app provides functionalities such as task management, health tracking, calendar scheduling, chat interactions, and system logs.

## Features

- **3D Robot Head Viewer**: Displays a 3D model of the AIR robot.
- **Dark/Light Mode Toggle**: Switch between dark and light themes.
- **Logs**: Tracks system and user interactions.
- **Chat**: Communicate with AIR using a chat interface.
- **Mute/Unmute**: Toggle the microphone.
- **Task Management**: Access and manage scheduled tasks and reminders.
- **Health Section**: Dedicated health tracking and recommendations.
- **Calendar**: View and manage scheduled events.
- **Profile Management**: View and edit user preferences.

## Screenshots

### Home Screen
![Simulator Screenshot](./Screenshots/Simulator%20Screenshot%20-%20iPhone%2015%20Pro.png)


## Installation

### Prerequisites

- Flutter SDK installed on your machine
- Android Studio or Visual Studio Code

### Steps

1. Clone this repository:
   ```bash
   git clone https://github.com/atif275/air-mobile-app.git
   ```
2. Navigate to the project directory:
   ```bash
   cd air-app
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Directory Structure

```
lib/
├── main.dart                # Main application file
├── settings_page.dart       # Settings page for configuration
├── logs.dart                # Logs display and management
├── chat_page.dart           # Chat interface for user-AIR interaction
├── logs_manager.dart        # Handles logging functionality
assets/
├── Air3.glb                 # 3D model of the AIR robot head
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## License

[Specify your app's license here, e.g., MIT License]

---
