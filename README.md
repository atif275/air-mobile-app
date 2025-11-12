
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

<div style="display: flex; justify-content: space-around; flex-wrap: wrap; gap: 10px;">
  <img src="./Screenshots/Simulator%20ScreenshotSettings%20-%20iPhone%2015%20Pro.PNG" alt="Settings Screen" width="150" style="margin: 0 5px;"/>
  <img src="./Screenshots/SimulatorChatPage%20-%20iPhone%2015%20Pro.PNG" alt="Chat Page Screen" width="150" style="margin: 0 5px;"/>
  <img src="./Screenshots/SimulatorEmail-integration-%20iPhone%2015%20Pro.PNG" alt="Email Integration Screen" width="150" style="margin: 0 5px;"/>
  <img src="./Screenshots/SimulatorHomePage-head1%20-%20iPhone%2015%20Pro.PNG" alt="HomePage Head1 Screen" width="150" style="margin: 0 5px;"/>
  <img src="./Screenshots/SimulatorHomePage-head2%20-%20iPhone%2015%20Pro.PNG" alt="HomePage Head2 Screen" width="150" style="margin: 0 5px;"/>
  <img src="./Screenshots/SimulatorLogin%20-%20iPhone%2015%20Pro.PNG" alt="Login Screen" width="150" style="margin: 0 5px;"/>
  <img src="./Screenshots/SimulatorLogs-%20iPhone%2015%20Pro.png" alt="Logs Screen" width="150" style="margin: 0 5px;"/>
  <img src="./Screenshots/SimulatorPC-integration-%20iPhone%2015%20Pro.PNG" alt="PC Integration Screen" width="150" style="margin: 0 5px;"/>
  <img src="./Screenshots/SimulatorSignup%20-%20iPhone%2015%20Pro.PNG" alt="Signup Screen" width="150" style="margin: 0 5px;"/>
  <img src="./Screenshots/SimulatorTask-management-%20iPhone%2015%20Pro.PNG" alt="Task Management Screen" width="150" style="margin: 0 5px;"/>
  <img src="./Screenshots/SimulatorWhatsapp-integration-%20iPhone%2015%20Pro.PNG" alt="Whatsapp Integration Screen" width="150" style="margin: 0 5px;"/>
</div>


## Installation

### Prerequisites

- Flutter SDK installed on your machine
- Xcode for iOS development

### Steps

1. Clone this repository:
   ```bash
   git clone https://github.com/atif275/air-mobile-app.git
   ```
2. Navigate to the project directory:
   ```bash
   cd air_mobile_app
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app on a connected device or simulator:
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

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

open -a Simulator

flutter devices
flutter clean  
flutter pub get

flutter build ios --release

   flutter run -d 03DFA4C3-956C-4AD9-B9AF-7C920C684CCC
   
flutter install --release