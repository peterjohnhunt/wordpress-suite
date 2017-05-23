{CompositeDisposable, Disposable} = require 'atom'
WP = require 'wp-cli'
command = require 'command-exists'
Projects = require './projects'
Actions = require './actions'
Views = require './views'

module.exports = class WordpressSuite

	constructor: (logger) ->
		@logger = logger
		@log = @logger "core"

		@wp = null
		@views = null

		@subscriptions = new CompositeDisposable
		@subscriptions.add @projects = new Projects(@logger)
		@subscriptions.add @actions = new Actions(@logger)

		# @subscriptions.add atom.workspace.addOpener (uri) =>
		# 	if uri.startsWith('atom://wordpress-suite')
		# 		if not @views? or @views.destroyed
		# 			@views = new Views(@logger)
		# 		@views.create(uri)
		# 		return @views

		command 'wp', (err,exists) =>
			if exists
				WP.discover (wp) =>
					@wp = wp
					wp.cli.check_update (err, update) =>
						if update
							atom.notifications.add('info', 'WP-CLI Update Available:', {
								dismissable: true,
								detail: update,
								buttons: [
									{ text: 'Update', className: 'btn-update', onDidClick: ->
										@removeNotification()
										atom.notifications.add('info', 'Updating WP-CLI')
										atom.wordpressSuite.wp.cli.update {yes:true}, (err,message) =>
											if err
												atom.notifications.add('error', 'Error Updating WP-CLI', {dismissable: true, detail: err})
											else
												atom.notifications.add('success', 'Updated WP-CLI', {dismissable: true, detail: message})

									}
								]
							})

		@log 'Created', 6

		new Disposable()

	getSelectedSite: ->
		for site in @projects.sites
			return site if site.isSelected()

	muteNotification: (message, sitePath) ->
		site = @projects.getSite(sitePath)
		site.notifications.mute(message)

	unmuteNotification: (message, sitePath) ->
		site = @projects.getSite(sitePath)
		site.notifications.unmute(message)

	dispose: ->
		@log 'Deleted', 6

		@subscriptions?.dispose()

		if atom.inDevMode()
			@log = ->
			@log = -> ->
			@projects = null
			@actions = null
			@views = null
			@wp = null