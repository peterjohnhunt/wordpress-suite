![Wordpress Suite](https://raw.githubusercontent.com/peterjohnhunt/wordpress-suite/master/assets/logo.png "Wordpress Suite")

## Summary
**Wordpress Suite** is an ever expanding suite of Wordpress tools, accessible right from atom's interface!
* [Installation](#installation)
* [Features](#features)
	* [General](#general-features)
	* [Debug Watcher](#debug-watcher)
	* [WP CLI](#wp-cli)
	* [Context Menu](#context-menu)
* [Settings](#settings)
	* [Enable / Disable Notification Types](#enable-disable-notification-types)
* [Release Notes](#release-notes)
* [Issues / Additions](#issues-additions)

---

## Installation
Atom Package: https://atom.io/packages/wordpress-suite

```bash
apm install wordpress-suite
```
Or Preferences ➔ Install ➔ Search for `wordpress-suite`

## Features

### General Features

#### Add Project Root
If you're working in a specific theme or plugin, this shortcut adds the main Wordpress root folder to the sidebar.

---

### Debug Watcher
Using atoms built in file watching, each Wordpress site added to the TreeView will automatically be watched by atom.

#### Notifications
Notifications will automatically pop up for any changes in the debug log.

![Debug Log | Notification](https://raw.githubusercontent.com/peterjohnhunt/wordpress-suite/master/assets/notification.gif "Debug Log Notification")

#### Open/Clear Debug Log
When a notification pops up you have the option to open or clear the debug log with just a push of a button! Clearing it will also hide all notifications currently related to that project.

![Debug Log | Open / Clear](https://raw.githubusercontent.com/peterjohnhunt/wordpress-suite/master/assets/open_clear.gif "Debug Log Open / Clear")

#### Pause and Resume Watching
suppress or resume any notifications of changes to the debug log on the current Wordpress project.

![Debug Log | Pause / Resume ](https://raw.githubusercontent.com/peterjohnhunt/wordpress-suite/master/assets/pause_resume.gif "Debug Log | Pause / Resume")

#### Show and Clear recent notifications
show all the most recent notifications that were closed since the last time the debug log was cleared or clear the debug log, and remove any notifications related to the current Wordpress project.

#### Mute Notifications
If there is a reoccurring notification that you would like to mute, when it pops up, click the mute button in the bottom right to no longer see messages with this exact text.

![Debug Log | Mute Notification](https://raw.githubusercontent.com/peterjohnhunt/wordpress-suite/master/assets/mute.gif "Debug Log | Mute Notification")

#### Clear Muted Notifications
Under the context menu, you can clear all muted notifications.

#### Stack Trace Links
In the event that Wordpress prints an error and references where the error occurred, the path to the file will automatically be converted into a quick link to open the file in the editor directly to the specified line.

![Debug Log | File Link](https://raw.githubusercontent.com/peterjohnhunt/wordpress-suite/master/assets/file_link.gif "Debug Log File Link")

---

### WP CLI
If WP-CLI is installed locally, additional context menu items will be available to manage and manipulate your Wordpress projects.

#### Site Name
Automatically retrieve the site name stored in the Wordpress database and use it in notification titles.

#### Path Config
Automatically retrieve the Wordpress path from the local wp-cli.yml if it exists.

#### Export Database
This will automatically generate a "db" folder in the root of the Wordpress project, it will then export the database to that db folder naming it "latest-db.sql" pulling from the credentials set in `wp-config.php`.

#### Import Database
This will automatically export a backup of the database and then import "latest-db.sql" pulling from the credentials set in `wp-config.php`.

---

### Context Menu
When right clicking a Wordpress project in the sidebar, you'll have a "Wordpress" dropdown which has lots of useful features including:

#### Menu Items
* Add Project Root
* Show Notifications
* Clear Notifications
* Open Debug Log
* Clear Ignored
* Pause Watching
* Resume Watching
* Export Database
* Import Database

![Context Menu](https://raw.githubusercontent.com/peterjohnhunt/wordpress-suite/master/assets/context.gif "Context Menu")

---

## Settings

### Enable / Disable Notification Types
Notification types can be enabled and disabled via the package settings

![Settings | Notification ](https://raw.githubusercontent.com/peterjohnhunt/wordpress-suite/master/assets/notification_settings.gif "Notification Settings")

---

## Release Notes
For release notes and version history, view the [change log](https://github.com/peterjohnhunt/wordpress-suite/blob/master/changelog.md#change-log).

---

## Issues / Additions
For any issues, additions or bugs, feel free to [open an issue](https://github.com/peterjohnhunt/wordpress-suite/issues/new) and include stack trace if applicable!

---