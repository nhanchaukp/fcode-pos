# Flutter Starter Kit with Appwrite

Kickstart your Flutter development with this ready-to-use starter project integrated
with [Appwrite](https://appwrite.io).

This guide will help you quickly set up, customize, and build your Flutter app.

---

## 🚀 Getting Started

### Clone the Project

Clone this repository to your local machine using Git or directly from `Android Studio`:

```bash
git clone https://github.com/appwrite/starter-for-flutter
```

Alternatively, open the repository URL in `Android Studio` to clone it directly.

---

## 🛠️ Development Guide

1. **Configure Appwrite**  
   Open `lib/config/environment.dart` and update the values with your Appwrite project credentials:
   ```dart
   class Environment {
      static const String appwriteEndpoint = '[appwriteEndpoint]';
      static const String appwriteProjectId = '[appwriteProjectId]';
      static const String appwriteProjectName = '[appwriteProjectName]';
   }
   ```

2. **Customize as Needed**  
   Modify the starter kit to suit your app's requirements. Adjust UI, features, or backend
   integrations as per your needs.

3. **Run the App**  
   Select a target device and run the app:
   ```bash
   # List available devices
   flutter devices
   
   # Run on a specific device (replace 'device-id' with actual device)
   flutter run -d device-id
   
   # Examples:
   flutter run -d chrome          # Web
   flutter run -d "iPhone 15"     # iOS Simulator
   flutter run -d emulator-5554   # Android Emulator
   flutter run -d macos           # macOS Desktop
   ```

   **Build for Web:**
   ```bash
   flutter build web
   ```

---

## 📦 Building for Production

Follow the official Flutter guide on deploying an app to
production : https://docs.flutter.dev/deployment

---

## 💡 Additional Notes

- This starter project is designed to streamline your Flutter development with Appwrite.
- Refer to the [Appwrite Documentation](https://appwrite.io/docs) for detailed integration guidance.