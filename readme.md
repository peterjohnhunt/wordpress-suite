# Wordpress Suite

**Wordpress Suite** is an ever expanding suite of wordpress tools, accessible right from atom's interface!

---

## Features

* [General](#general-features)
* [Debug Watcher](#debug-watcher)
* [WP CLI](#wp-cli)

### General Features

#### Add Project Root
If you're working in a specific theme or plugin, this shortcut adds the main wordpress root folder to the sidebar

---

### Debug Watcher
Using atoms built in file watching, each Wordpress site added to the TreeView will automatically be watched by atom

#### Notifications
Notifications will automatically pop up for any changes in the debug log.

![Debug Log Notification](https://raw.githubusercontent.com/peterjohnhunt/wordpress-suite/master/assets/notification.gif "Debug Log Notification")

#### Open/Clear Debug Log
When a notification pops up you have the option to open or clear the debug log with just a push of a button! Clearing it will also hide all notifications currently related to that project.

![Debug Log Open / Clear](https://raw.githubusercontent.com/peterjohnhunt/wordpress-suite/master/assets/open_clear.gif "Debug Log Open / Clear")

#### Pause and Resume Watching
suppress or resume any notifications of changes to the debug log on the current Wordpress project

#### Show and Clear recent notifications
show all the most recent notifications that were closed since the last time the debug log was cleared or clear the debug log, and remove any notifications related to the current Wordpress project

---

### WP CLI
If wp-cli is installed locally, additional context menu items will be available to manage and manipulate your Wordpress projects

#### Export Database
This will automatically generate a "db" folder in the root of the Wordpress project, it will then export the database to that db folder naming it "latest-db.sql" pulling from the credentials set in wp-config.php

---

### Context Menu
When right clicking a wordpress project in the sidebar, you'll have a "Wordpress" dropdown which has lots of useful features including:

#### Menu Items
* Add Project Root
* Show Notifications
* Clear Notifications
* Open Debug Log
* Pause Watching
* Resume Watching
* Export Database

![Context Menu](https://raw.githubusercontent.com/peterjohnhunt/wordpress-suite/master/assets/context.gif "Context Menu")