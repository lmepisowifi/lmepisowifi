# Changelog

All notable changes to the lmepisowifi modded web interface.
This file is shown verbatim in Admin > System > Software Update.

## v1.0.0
- Dynamic `/admin` redirect on the captive portal to the www2 admin UI (no hardcoded IP).
- Auto-detected br0 upstream gateway (no hardcoded 192.168.18.1).
- GitHub-based OTA updates: manual check/apply, 6-hour scheduled check,
  optional automatic install, SHA-256 verification, and automatic rollback.
