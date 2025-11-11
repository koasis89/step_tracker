# Blueprint: Pedometer App

## Overview

This document outlines the design and functionality of a Pedometer application built with Flutter. The app tracks user steps, distance, calories burned, and active time. It supports both real-time data from hardware sensors and a simulation mode for demonstration. A key feature is the smart timer, which automatically pauses when the user stops moving.

## Features

*   **Real-time Step Tracking (Live Mode):**
    *   Utilizes the `pedometer` package for live step count data from the device's sensor.
    *   Displays a real-time count of the user's steps.

*   **GPS-Enhanced Activity Tracking (Live Mode):**
    *   Integrates the `geolocator` package to monitor the user's GPS location.
    *   **Smart Timer:** The activity timer automatically pauses if no steps or significant location changes (movement) are detected for 5 seconds, ensuring accurate active time tracking.
    *   The timer resumes automatically as soon as movement is detected again.

*   **Key Health Metrics:**
    *   **Distance:** Calculates and displays the total distance covered in kilometers, estimated from the step count.
    *   **Calories Burned:** Shows an estimated number of calories burned (kcal) based on the step count.
    *   **Active Time:** A timer tracks and displays the total duration of the activity in HH:MM:SS format.

*   **Simulation Mode:**
    *   A feature for testing and demonstration without physical sensors.
    *   **Activation:** Users can toggle between Live and Simulation Mode. All metrics reset upon switching.
    *   **Manual Control:** "Start" and "Stop" buttons control the simulation and the timer accordingly.
    *   **Speed Adjustment:** A slider adjusts the simulation speed.

*   **UI and User Experience:**
    *   **Walking Animation:** A custom-painted animation provides a visual representation of walking.
    *   **Clear Display:** The UI prominently displays the step count, with distance, time, and calories shown below.
    *   **Permissions Handling:** The app gracefully requests necessary permissions for motion and location data.

## Implementation History

1.  **Core Pedometer Setup:**
    *   Added `pedometer` and built the basic UI for step counting.

2.  **Simulation Feature:**
    *   Implemented the complete simulation mode with manual controls and speed adjustment.

3.  **UI Refinement & Simplification:**
    *   Created `DetailedWalkingPainter` for a better walking animation.
    *   Refactored the project to a clean, single-screen architecture, removing previous unused features.

4.  **Health Metrics Expansion:**
    *   Added tracking and display for distance, calories, and active time.

5.  **Improved Timer Logic:**
    *   Modified the timer to activate only when activity (a step or simulation start) is first detected.

6.  **GPS-Based Auto-Pause (Live Mode):**
    *   Added the `geolocator` package and configured Android/iOS permissions.
    *   Implemented logic to subscribe to location updates.
    *   Created a `_handleMovement` function that resets a 5-second timer upon detecting a step or significant location change.
    *   If the 5-second timer completes without new movement, the main activity timer is paused, providing a highly accurate measure of active time.
