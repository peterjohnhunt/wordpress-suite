{CompositeDisposable, Disposable} = require 'atom'

module.exports = class Actions

	constructor: (logger) ->
		@logger = logger
		@log = @logger "actions"

		@subscriptions = new CompositeDisposable

		@subscriptions.add atom.commands.add ".project-root",
			"wordpress-suite:site:addRoot": -> atom.wordpressSuite.getSelectedSite().addRoot()
			"wordpress-suite:site:notifications:show-recent": -> atom.wordpressSuite.getSelectedSite().notifications.show()
			"wordpress-suite:site:notifications:clear-recent": -> atom.wordpressSuite.getSelectedSite().notifications.clear()
			"wordpress-suite:site:notifications:show-muted": -> atom.wordpressSuite.getSelectedSite().notifications.showMuted()
			"wordpress-suite:site:notifications:clear-muted": -> atom.wordpressSuite.getSelectedSite().notifications.clearMuted()
			"wordpress-suite:site:notifications:disable": -> atom.wordpressSuite.getSelectedSite().notifications.disable()
			"wordpress-suite:site:notifications:enable": -> atom.wordpressSuite.getSelectedSite().notifications.enable()
			"wordpress-suite:site:log-file:open": -> atom.wordpressSuite.getSelectedSite().logFile.open()
			"wordpress-suite:site:log-file:clear": -> atom.wordpressSuite.getSelectedSite().logFile.clear()
			"wordpress-suite:site:log-file:pause-watching": -> atom.wordpressSuite.getSelectedSite().logFile.pauseWatching()
			"wordpress-suite:site:log-file:resume-watching": -> atom.wordpressSuite.getSelectedSite().logFile.resumeWatching()
			"wordpress-suite:site:wp-cli:full-setup": -> atom.wordpressSuite.getSelectedSite().wpcli.full_setup()
			"wordpress-suite:site:wp-cli:download-wordpress": -> atom.wordpressSuite.getSelectedSite().wpcli.download_wordpress()
			"wordpress-suite:site:wp-cli:create-database": -> atom.wordpressSuite.getSelectedSite().wpcli.create_database()
			"wordpress-suite:site:wp-cli:create-config": -> atom.wordpressSuite.getSelectedSite().wpcli.create_config()
			"wordpress-suite:site:wp-cli:install-wordpress": -> atom.wordpressSuite.getSelectedSite().wpcli.install_wordpress()
			"wordpress-suite:site:wp-cli:clear-everything": -> atom.wordpressSuite.getSelectedSite().wpcli.clear_everything()
			"wordpress-suite:site:wp-cli:reset-permalinks": -> atom.wordpressSuite.getSelectedSite().wpcli.reset_permalinks()
			"wordpress-suite:site:wp-cli:clear-rewrite-rules": -> atom.wordpressSuite.getSelectedSite().wpcli.clear_rewrite_rules()
			"wordpress-suite:site:wp-cli:clear-cache": -> atom.wordpressSuite.getSelectedSite().wpcli.clear_cache()
			"wordpress-suite:site:wp-cli:clear-transients": -> atom.wordpressSuite.getSelectedSite().wpcli.clear_transients()
			"wordpress-suite:site:wp-cli:verify-checksums": -> atom.wordpressSuite.getSelectedSite().wpcli.verify_checksums()
			"wordpress-suite:site:wp-cli:update-wordpress": -> atom.wordpressSuite.getSelectedSite().wpcli.update_wordpress()
			"wordpress-suite:site:wp-cli:export-database": -> atom.wordpressSuite.getSelectedSite().wpcli.export_database()
			"wordpress-suite:site:wp-cli:import-database": -> atom.wordpressSuite.getSelectedSite().wpcli.import_database()
			"wordpress-suite:site:wp-cli:optimize-database": -> atom.wordpressSuite.getSelectedSite().wpcli.optimize_database()
			"wordpress-suite:site:wp-cli:repair-database": -> atom.wordpressSuite.getSelectedSite().wpcli.repair_database()
			"wordpress-suite:site:wp-cli:regenerate-thumbnails": -> atom.wordpressSuite.getSelectedSite().wpcli.regenerate_thumbnails()
			"wordpress-suite:site:wp-cli:import-media": ->
				site = atom.wordpressSuite.getSelectedSite()
				mediaPath = site.getSelectedFile().getPath()
				site.wpcli.import_media(mediaPath)
			"wordpress-suite:site:refresh": -> atom.wordpressSuite.getSelectedSite().refresh()
			# "wordpress-suite:site:open": -> atom.wordpressSuite.getSelectedSite().open()

		@subscriptions.add atom.contextMenu.add {
			".project-root": [{ label: 'Wordpress Suite', submenu: [
				{ label: 'Add Root', command: "wordpress-suite:site:addRoot", shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.hasRoot() isnt true }
				{ label: 'Open Log', command: "wordpress-suite:site:log-file:open", shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.hasLogFile() }
				{ label: 'Clear Log', command: "wordpress-suite:site:log-file:clear", shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.logFileHasMessages() }
				{ type: 'separator' }
				{ label: 'Update Wordpress', command: "wordpress-suite:site:wp-cli:update-wordpress", shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.hasWPCLI('update') }
				{ type: 'separator' }
				{ label: 'Export Database', command: "wordpress-suite:site:wp-cli:export-database", shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.hasWPCLI('database') }
				{ label: 'Import Database', command: "wordpress-suite:site:wp-cli:import-database", shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.hasWPCLI('database') }
				{ type: 'separator' }
				{ label: 'Import As Media', command: "wordpress-suite:site:wp-cli:import-media", shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.hasWPCLI('installed') }
				{ type: 'separator' }
				{ label: 'Refresh', command: "wordpress-suite:site:refresh" }
				# { label: 'Open', command: "wordpress-suite:site:open" }
				{ type: 'separator' }
				{ label: 'Setup', submenu: [
					{ label: 'Full Setup', command: "wordpress-suite:site:wp-cli:full-setup", shouldDisplay: ->
						site = atom.wordpressSuite.getSelectedSite()
						return site?.hasWPCLI('initialized') and not site?.hasWPCLI('core') and not site?.hasWPCLI('installed')
					}
					{ type: 'separator' }
					{ label: 'Download Wordpress', command: "wordpress-suite:site:wp-cli:download-wordpress", shouldDisplay: ->
						site = atom.wordpressSuite.getSelectedSite()
						return site?.hasWPCLI('initialized') and not site?.hasWPCLI('core')
					}
					{ label: 'Create Config', command: "wordpress-suite:site:wp-cli:create-config", shouldDisplay: ->
						site = atom.wordpressSuite.getSelectedSite()
						return site?.hasWPCLI('core') and not site?.hasWPCLI('config')
					}
					{ label: 'Create Database', command: "wordpress-suite:site:wp-cli:create-database", shouldDisplay: ->
						site = atom.wordpressSuite.getSelectedSite()
						return site?.hasWPCLI('config') and not site?.hasWPCLI('database')
					}
					{ label: 'Install Wordpress', command: "wordpress-suite:site:wp-cli:install-wordpress", shouldDisplay: ->
						site = atom.wordpressSuite.getSelectedSite()
						return site?.hasWPCLI('database') and not site?.hasWPCLI('installed')
					}
				], shouldDisplay: ->
					site = atom.wordpressSuite.getSelectedSite()
					return site?.hasWPCLI('ready') and not site?.hasWPCLI('installed')
				}
				{ label: 'Notifications', submenu: [
					{ label: 'Show Recent', command: "wordpress-suite:site:notifications:show-recent", shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.hasNotifications() }
					{ label: 'Clear Recent', command: "wordpress-suite:site:notifications:clear-recent", shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.hasNotifications() }
					{ type: 'separator' }
					{ label: 'Show Muted', command: "wordpress-suite:site:notifications:show-muted", shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.hasMutedNotifications() }
					{ label: 'Clear Muted', command: "wordpress-suite:site:notifications:clear-muted", shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.hasMutedNotifications() }
					{ type: 'separator' }
					{ label: 'Disable', command: "wordpress-suite:site:notifications:disable", shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.notificationsIsEnabled() }
					{ label: 'Enable', command: "wordpress-suite:site:notifications:enable", shouldDisplay: -> return not atom.wordpressSuite.getSelectedSite()?.notificationsIsEnabled() }
				]}
				{ label: 'Debug Log', submenu: [
					{ label: 'Pause Watching', command: "wordpress-suite:site:log-file:pause-watching", shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.isWatchingLogFile() }
					{ label: 'Resume Watching', command: "wordpress-suite:site:log-file:resume-watching", shouldDisplay: -> return not atom.wordpressSuite.getSelectedSite()?.isWatchingLogFile() }
				], shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.hasLogFile() }
				{ label: 'Utilities', submenu: [
					{ label: 'Clear Everything', command: "wordpress-suite:site:wp-cli:clear-everything", shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.hasWPCLI('installed') }
					{ type: 'separator' }
					{ label: 'Reset Permalinks', command: "wordpress-suite:site:wp-cli:reset-permalinks", shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.hasWPCLI('installed') }
					{ label: 'Clear Rewrite Rules', command: "wordpress-suite:site:wp-cli:clear-rewrite-rules", shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.hasWPCLI('installed') }
					{ label: 'Clear Cache', command: "wordpress-suite:site:wp-cli:clear-cache", shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.hasWPCLI('installed') }
					{ label: 'Clear Transients', command: "wordpress-suite:site:wp-cli:clear-transients", shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.hasWPCLI('installed') }
					{ type: 'separator' }
					{ label: 'Verify Checksums', command: "wordpress-suite:site:wp-cli:verify-checksums", shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.hasWPCLI('installed') }
					{ type: 'separator' }
					{ label: 'Optimize Database', command: "wordpress-suite:site:wp-cli:optimize-database", shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.hasWPCLI('database') }
					{ label: 'Repair Database', command: "wordpress-suite:site:wp-cli:repair-database", shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.hasWPCLI('database') }
					{ type: 'separator' }
					{ label: 'Regenerate Thumbnails', command: "wordpress-suite:site:wp-cli:regenerate-thumbnails", shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.hasWPCLI('installed') }
				], shouldDisplay: -> return atom.wordpressSuite.getSelectedSite()?.hasWPCLI('installed') }
			]}]
		}

		new Disposable()

	dispose: ->
		# Clean Up Subscriptions
		@subscriptions?.dispose()

		@log 'Deleted', 6

		if atom.inDevMode()
			@log = ->
			@log = -> ->
			@subscriptions = null