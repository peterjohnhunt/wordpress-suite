module.exports = class Views

	constructor: (logger) ->
		@logger = logger
		@log = @logger "views"

		@log 'Created', 6

	create: (uri) ->
		uriRegex = /wordpress-suite\/?([a-zA-Z0-9_-]+)?\/?([a-zA-Z0-9_-]+)?/i
		match = uriRegex.exec(uri)

		console.log match

		@element = document.createElement('div')
		@element.classList.add('wordpress-suite')

		title = document.createElement('h1')
		title.textContent = 'Wordpress Suite'
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