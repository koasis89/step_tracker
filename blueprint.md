# Blueprint: Pedometer App

## Overview

This document outlines the design and functionality of a Pedometer application built with Flutter. The app focuses on one core feature: tracking user steps. It supports both real-time step counting using the device's hardware sensors and a simulation mode for testing and demonstration purposes.

## Features

*   **Real-time Step Tracking (Live Mode):**
    *   Utilizes the `pedometer` package to receive step count data from the device's hardware step sensor in real-time.
    *   Provides a live count of the user's steps.

*   **Simulation Mode:**
    *   A feature designed for testing the app's functionality without relying on a physical sensor.
    *   **Activation:** Users can toggle between Live Mode and Simulation Mode at any time using a switch in the app bar.
    *   **Manual Control:** Provides "Start" and "Stop" buttons to manually control the simulation.
    *   **Speed Adjustment:** A slider allows the user to adjust the simulation speed (from 1 to 10), which dictates the rate of step increase.

*   **UI and User Experience:**
    *   **Walking Animation:** A custom-painted animation provides a visual representation of walking, which is active when steps are being counted (in both live and simulation modes).
    *   **Clear Display:** The current step count is displayed prominently on the screen.
    *   **Simple Interface:** The application has a single, focused screen, making it intuitive and easy to use.

## Implementation History

1.  **Core Pedometer Setup:**
    *   Added the `pedometer` package to the project.
    *   Built the basic UI to display the step count received from the sensor.

2.  **Simulation Feature:**
    *   Implemented the UI for simulation mode, including the toggle switch, start/stop buttons, and speed slider.
    *   Created the logic to animate a walking figure and increment the step count based on the simulation speed and state.

3.  **UI Refinement & Simplification:**
    *   A custom painter (`DetailedWalkingPainter`) was created for a more visually appealing walking animation.
    *   The project was refactored to focus solely on the pedometer functionality. All previous features related to user authentication, data persistence with Firebase, and tab-based navigation were removed to simplify the codebase and enhance maintainability.
    *   The code structure was reorganized into a clean architecture with a single main screen (`lib/screens/main_screen.dart`) containing all the necessary logic.
