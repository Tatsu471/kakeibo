# Changelog

All notable changes to this project will be documented in this file.

## [2026-11-11]
### Added
- **Netlify Hosting**: Added `netlify.toml` and `web/_redirects` for SPA routing and Netlify deployment.
- **Git Configuration**: Added `.netlify` to `.gitignore`.

## [2026-04-20]
### Fixed
- **Firebase Security Rules**: Fixed a "Permission Denied" error during entry saving by adding permissions for the `monthly_summaries` collection.
- **Project Configuration**: Added the `firestore` block to `firebase.json` to allow security rules to be deployed directly from the CLI.

### Security
- Reinforced the user-based access control by ensuring the `{document=**}` wildcard is correctly applied to all subcollections under `/users/{userId}/`.
