
# Onboarding Widget Flow

This document outlines the user flow through the various onboarding screens in the Luna Chat application.

## Flow Controller

The entire onboarding process is managed by the `OnboardingFlow` widget, located in `lib/screens/onboarding/onboarding_flow.dart`. This widget functions as a state machine, using an integer variable `_currentStep` to track the user's progress and display the appropriate screen.

## Screen Sequence

The flow uses 5 sequential steps (0-4):

0.  **`OnboardingWelcomeScreen` (`onboarding_welcome.dart`)**
    *   **Purpose:** The initial entry point for a new user.
    *   **Action:** The user taps the "Get Started" button.
    *   **Result:** The `_onWelcomeGetStarted` function in `OnboardingFlow` is called, advancing the flow to the next step.

1.  **`OnboardingInstructionManualCheckScreen` (`onboarding_instruction_manual_check.dart`)**
    *   **Purpose:** To determine if the user has already completed the physical hardware setup.
    *   **Paths:**
        *   **"Yes, it's already set up":** Triggers `_onManualCheckYes`, which skips the hardware setup guide and proceeds directly to scanning for the device (Step 3).
        *   **"No, I need help setting it up":** Triggers `_onManualCheckNo`, which proceeds to the hardware setup guide (Step 2).

2.  **`OnboardingHardwareSetupScreen` (`onboarding_hardware_setup.dart`)**
    *   **Purpose:** Provides step-by-step visual instructions for connecting the Luna device's power and network cables.
    *   **Process:** This is a 2-step guided setup within the same screen:
        *   **Step 1:** Power connection - User plugs power cable into wall, then into Luna device. Button shows "Next: Connect Device".
        *   **Step 2:** Network connection - User connects network cable from Luna to computer. Button shows "Next: Wait for Luna".
    *   **Result:** After completing both steps, triggers `_onHardwareSetupComplete`, which proceeds to the device scanning screen (Step 3).

3.  **`OnboardingScanningLunaScreen` (`onboarding_scanning_luna.dart`)**
    *   **Purpose:** To automatically detect the Luna device on the local network.
    *   **Behavior:** 
        *   Automatically scans for Luna device every 3 seconds
        *   After 30 seconds without finding device, shows troubleshoot options
        *   Displays device IP address when found
    *   **Paths:**
        *   **Device Found:** Triggers the `onDeviceFound` callback (`_onLunaScanned` in `OnboardingFlow`), which proceeds to the name input screen (Step 4).
        *   **Scan Failed/Timeout:** User can select "Need Help" (triggers `onScanFailed` callback → `_onManualCheckNo`) to return to setup instructions (Step 1), or "Keep Trying" to continue scanning.

4.  **`OnboardingNameInputScreen` (`onboarding_user_name.dart`)**
    *   **Purpose:** The final step, where the user provides their name for a personalized experience.
    *   **Behavior:** 
        *   Automatically focuses text input after screen animation
        *   Validates input and enables/disables "Get Started" button accordingly
        *   Saves name to SharedPreferences (local storage)
    *   **Action:** The user enters their name and taps "Get Started".
    *   **Result:** Triggers the `onNameSubmit` callback (`_onNameSubmitted` in `OnboardingFlow`). This function saves the user's name and then calls `_navigateToChat` to transition the user out of the onboarding flow and into the main `UserDashboardApp`.

## Technical Implementation Notes

* **Animation System:** All screens feature elaborate fade, slide, and typing animations with specific timing sequences
* **State Management:** Each screen manages button states, loading indicators, and input validation
* **Error Handling:** Includes timeout scenarios, scan failures, and save error handling
* **Local Storage:** User name is automatically saved to SharedPreferences for persistence

This entire flow is contained within the `lib/screens/onboarding/` directory, with `onboarding_flow.dart` acting as the central navigator and state machine.
