module.exports = class Views

	constructor: (logger) ->
		@logger = logger
		@log = @logger "views"

		@log 'Created', 6

	create: (uri) ->
		# console.log atom.wordpressSuite.getSelectedSite()
		# uriRegex = /wordpress-suite\/?([a-zA-Z0-9_-]+)?\/?([a-zA-Z0-9_-]+)?/i
		# match = uriRegex.exec(uri)
		#
		# sitePath = match
		# site = atom.wordpressSuite.projects.projectPaths.indexOf(sitePath)
		# console.log site

		@element = document.createElement('div')
		@element.classList.add('wordpress-suite')

		title = document.createElement('h1')
		title.textContent = "WordPress Suite"
		title.classList.add('title')

		@element.appendChild(title)

	getTitle: ->
		return 'Wordpress Suite'

	getURI: ->
		return 'atom://wordpress-suite'

	getDefaultLocation: ->
		return 'right'

	getAllowedLocations: ->
		return ['left', 'right', 'bottom']

	serialize: ->
		return

	destory: ->
		@log 'Removed', 6
		return