# module.exports = class ProjectsView
#
# 	constructor: (logger) ->
# 		@logger = logger
# 		@log = @logger "projects.view"
#
# 		@element = document.createElement('div')
# 		@element.classList.add('wordpress-suite')
#
# 		title = document.createElement('h1')
# 		title.textContent = 'Wordpress Suite'
# 		title.classList.add('title')
#
# 		@element.appendChild(title)
#
# 		projects = document.createElement('ul')
# 		projects.classList.add('projects')
# 		@element.appendChild(projects)
# 		@log 'Created', 6
#
# 		# html = ''
# 		# for site in sites
# 		# 	html += "<li>#{site.name}</li>"
#
# 		# projects.innerHTML = html
#
# 	getTitle: ->
# 		return 'Wordpress Suite'
#
# 	getURI: ->
# 		return 'atom://wordpress-suite'
#
# 	getDefaultLocation: ->
# 		return 'right'
#
# 	getAllowedLocations: ->
# 		return ['left', 'right', 'bottom']
#
# 	serialize: ->
# 		return
#
# 	destory: ->
# 		@log 'Removed', 6
# 		return
#
# 	getElement: ->
# 		return @element
# @subscriptions.add atom.commands.add 'atom-workspace',
# 	"#{config.name}:projects:view:open": -> atom.workspace.open(config.uri)
#
# @subscriptions.add atom.workspace.addOpener (uri) =>
# 	if uri.startsWith(config.uri)
# 		if not @view? or @view.destroyed
# 			@view = new View(@logger)
# 		return @view