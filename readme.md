![WordPress Suite](https://raw.githubusercontent.com/peterjohnhunt/WordPress-suite/master/assets/logo.png "WordPress Suite")

## Summary
**WordPress Suite** is an ever expanding suite of WordPress tools, accessible right from atom's interface!
* [Installation](#installation)
* [Features](#features)
	* [General](#general-features)
	* [Debug Watcher](#debug-watcher)
	* [WP CLI](#wp-cli)
	* [Smart Context Menu](#smart-context-menu)
* [Settings](#settings)
	* [WP CLI](#wp-cli-setup-settings)
* [Release Notes](#release-notes)
* [Issues / Additions](#issues-additions)

---

## Installation
Atom Package: https://atom.io/packages/WordPress-suite

```bash
apm install WordPress-suite
```
Or Preferences ➔ Install ➔ Search for `WordPress-suite`

## Features

### General Features

#### Add Project Root
If you're working in a specific theme or plugin, this shortcut adds the main WordPress root folder to the sidebar.

---

### Debug Watcher
Using atoms built in file watching, each WordPress site added to the TreeView will automatically be watched by atom.

#### Notifications
Notifications will automatically pop up for any changes in the debug log.

![Debug Log | Notification](https://raw.githubusercontent.com/peterjohnhunt/WordPress-suite/master/assets/notification.gif "Debug Log Notification")

#### Open/Clear Debug Log
When a notification pops up you have the option to open or clear the debug log with just a push of a button! Clearing it will also hide all notifications currently related to that project.

![Debug Log | Open / Clear](https://raw.githubusercontent.com/peterjohnhunt/WordPress-suite/master/assets/open_clear.gif "Debug Log Open / Clear")

#### Pause and Resume Watching
suppress or resume any notifications of changes to the debug log on the current WordPress project.

![Debug Log | Pause / Resume ](https://raw.githubusercontent.com/peterjohnhunt/WordPress-suite/master/assets/pause_resume.gif "Debug Log | Pause / Resume")

#### Show and Clear recent notifications
show all the most recent notifications that were closed since the last time the debug log was cleared or clear the debug log, and remove any notifications related to the current WordPress project.

#### Mute / Unmute Notifications
If there is a reoccurring notification that you would like to mute, when it pops up, click the mute button in the bottom right to no longer see messages with this exact text.

![Debug Log | Mute Notification](https://raw.githubusercontent.com/peterjohnhunt/WordPress-suite/master/assets/mute.gif "Debug Log | Mute Notification")

#### Show and Clear Muted Notifications
show or clear all the notifications that have been muted within the project

#### Stack Trace Links
In the event that WordPress prints an error and references where the error occurred, the path to the file will automatically be converted into a quick link to open the file in the editor directly to the specified line.

---

### WP CLI
If WP-CLI is installed locally, additional context menu items will be available to manage and manipulate your WordPress projects.
- wp-cli.yml configuration files
- WordPress Setup (Database / Config / Install / Update)
- Site Info (Post Types / Taxonomies / User Roles)
- Clear Caches (Object / Permalinks / Transients)
- Optimizations (Regenerate Thumbnails / Database / Checksums / Repair Database)
- Import Files as Media
- Plugin Administration (Activation / Deactivation / Info / Delete / Add Folder)
- Theme Administration (Activation / Info / Delete / Add Folder)
- WP-CLI Update Prompting

---

### Smart Context Menu
When right clicking a WordPress project in the sidebar, you'll have a "WordPress Suite" dropdown which has lots of useful features including:

#### Menu Items
* Add Root
* Open Log
* Clear Log
* Update WordPress
* Export Database
* Import Database
* Import As Media
* Refresh
* Setup
	* Full Setup
	* Download WordPress
	* Create Config
	* Install WordPress
* Notifications
	* Show Recent
	* Clear Recent
	* Show Muted
	* Clear Muted
	* Enable
	* Disable
* Debug Log
	* Pause Watching
	* Resume Watching
* Utilities
	* Clear Everything
	* Reset Permalinks
	* Clear Rewrite Rules
	* Clear Cache
	* Clear Transients
	* Verify Checksums
	* Optimize Database
	* Repair Database
	* Regenerate Thumbnails
* Info
	* Post Types
	* Taxonomies
	* Roles
	* Site Details
* Plugins
	* Activate
	* Deactivate
	* Update
	* Delete
	* Info
* Themes
	* Activate
	* Update
	* Delete
	* Info
* Users
	* Delete
	* Info

---

## Settings

### WP-CLI Setup Settings
Site Setup Defaults Including:
* Database Username
* Database Password
* Database Host
* New Site URL
* New Site Username
* New Site Password
* New Site Email
* Database Export Filename

---

## Release Notes
For release notes and version history, view the [change log](https://github.com/peterjohnhunt/WordPress-suite/blob/master/changelog.md#change-log).

---

## Issues / Additions
For any issues, additions or bugs, feel free to [open an issue](https://github.com/peterjohnhunt/WordPress-suite/issues/new) and include stack trace if applicable!

## TODO
* View Site (Open Link)
* Delete Media File on Import

---