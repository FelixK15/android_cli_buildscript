# Android buildscripts

These are a collection of buildscripts to be able to compile and create applications for Android without having to install the complete Android Studio with all its dependencies.

The build script will do some preliminary checks to check if your machine is ready to build Android applications.
If the checks finds that something is missing, it'll try to download and install the required dependencies (JDK, Android SDK, etc)

This will currently only work on Linux but a Win32 backend is definitely planned in the future.
