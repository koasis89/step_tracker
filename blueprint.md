# Blueprint: Pedometer App

## Overview

This document outlines the design and functionality of a Pedometer application built with Flutter. The app tracks user steps, distance, calories burned, and active time. It supports both real-time data from hardware sensors and a simulation mode for demonstration.

## Features

*   **Real-time Step Tracking (Live Mode):**
    *   Utilizes the `pedometer` package for live step count data from the device's sensor.
    *   Displays a real-time count of the user's steps.

*   **Key Health Metrics:**
    *   **Distance:** Calculates and displays the total distance covered in kilometers, estimated from the step count.
    *   **Calories Burned:** Shows an estimated number of calories burned (kcal) based on the step count.
    *   **Active Time:** A timer tracks and displays the total duration of the activity in HH:MM:SS format. The timer starts only when the first step is detected (in Live Mode) or when the simulation is started.

*   **Simulation Mode:**
    *   A feature for testing and demonstration without a physical sensor.
    *   **Activation:** Users can toggle between Live and Simulation Mode via a switch in the app bar. All metrics reset when switching modes.
    *   **Manual Control:** Provides "Start" and "Stop" buttons to control the simulation. The timer starts and pauses accordingly.
    *   **Speed Adjustment:** A slider allows adjusting the simulation speed, which dictates the rate of step increase.

*   **UI and User Experience:**
    *   **Walking Animation:** A custom-painted animation visually represents walking, active when steps are counted.
    *   **Clear Display:** The current step count is the main focus, with distance, time, and calories displayed clearly below it.
    *   **Simple Interface:** A single, focused screen makes the app intuitive and easy to use.

## Implementation History

1.  **Core Pedometer Setup:**
    *   Added the `pedometer` package.
    *   Built the basic UI to display the step count.

2.  **Simulation Feature:**
    *   Implemented the UI for simulation mode (toggle switch, start/stop buttons, speed slider).
    *   Created the logic to animate a walking figure and increment steps based on simulation settings.

3.  **UI Refinement & Simplification:**
    *   Created `DetailedWalkingPainter` for a more appealing walking animation.
    *   Refactored the project to focus solely on pedometer functionality, removing Firebase authentication, data persistence, and tab-based navigation.
    *   Reorganized the code into a clean, single-screen architecture in `lib/screens/main_screen.dart`.

4.  **Health Metrics Expansion:**
    *   Added state variables and logic to track and calculate distance (km), calories (kcal), and elapsed active time.
    *   Implemented a `Timer` to track session duration.
    *   Updated the UI to display the new metrics (distance, time, calories) with corresponding icons in a clean, organized row.
    *   Ensured all metrics reset correctly when switching between live and simulation modes.

5.  **Improved Timer Logic:**
    *   Modified the timer to activate only when activity is detected (first step in Live Mode, or 'Start' pressed in Simulation Mode).
    *   The timer now pauses when the simulation is stopped, providing a more accurate measure of active time.
