# Workspace Rules

## Version Control
- **Commit After Every Change**: Whenever you make code or configuration changes in this repository, always stage and commit them to git with a clear, descriptive commit message before finishing the task.

## Build Workflow
- **Do Not Build Release APKs**: Never trigger or execute release APK builds (e.g., `flutter build apk`, `flutter build apk --release`) yourself. The user will build release APKs manually when needed. You may verify code using analyzers (`flutter analyze --no-pub`) and tests (`flutter test --no-pub`).
