{CompositeDisposable, Disposable} = require 'atom'
command = require 'command-exists'
Projects = require './projects'
Actions = require './actions'

module.exports = class WordpressSuite

	constructor: (logger) ->
		@logger = logger
		@log = @logger "core"

		@subscriptions = new CompositeDisposable
		@subscriptions.add @projects = new Projects(@logger)
		@subscriptions.add @actions = new Actions(@logger)

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