# Virtual Location

Virtual Location is a macOS application that enables users to simulate GPS locations on connected iOS devices. Built with SwiftUI and SwiftData, it provides an intuitive interface for managing device connections, location simulation, and location history.

## Features

- **Device Management**: Automatically detects iOS devices connected via USB or wireless
- **Map Interface**: Interactive map with search and selection capabilities
- **Location Simulation**: Set custom GPS coordinates on iOS devices using pymobiledevice3
- **Location History**: Store and manage favorite and recent locations
- **Coordinate Input**: Support for both map selection and manual coordinate entry
- **Tunnel Connection**: Establishes secure connections to iOS devices for location spoofing

## Architecture

The application follows a modern SwiftUI architecture with the following key components:

- **VirtualLocationViewModel**: Central view model managing map state, location search, and location records
- **DeviceConnectionManager**: Handles device discovery, tunnel establishment, and location simulation commands
- **DeviceCommandRunner**: Executes pymobiledevice3 commands via Python subprocess
- **CLIResolver**: Manages Python environment resolution
- **LocationRecord**: SwiftData model for storing location history and favorites
- **Views**: SwiftUI-based user interface including sidebar navigation, map view, and inspector panel

## Dependencies

- **pymobiledevice3**: Python library for iOS device communication (included in project bundle)
- **MapKit**: Apple's mapping framework for location services
- **SwiftUI & SwiftData**: Apple's modern UI and data persistence frameworks

## Installation

1. Clone or download the repository
2. Open the project in Xcode
3. Build and run the application

The application bundles a Python virtual environment with pymobiledevice3, so no additional Python installation is required.

## Usage

1. Connect your iOS device to your Mac via USB
2. Launch the Virtual Location app
3. The app will automatically detect connected devices
4. Search for or manually select a location on the map
5. Click the "Send Location" button to set the virtual location on your device
6. Location records are saved automatically for future reference

## Security Notice

This application requires administrator privileges to establish device tunnels for location simulation. All device communication occurs locally between your Mac and connected iOS device.

## Troubleshooting

- If devices don't appear, ensure proper cable connection and device trust
- Some iOS versions may require additional device setup for location simulation
- Restart both devices if location simulation stops responding
- Check the Inspector panel for connection status and error messages

## Technical Details

The application leverages pymobiledevice3's DVT (Developer Tools) framework to communicate with iOS devices and simulate location changes. A secure tunnel is established using RSD (Remote Service Discovery) protocols, which requires elevated privileges via sudo.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

