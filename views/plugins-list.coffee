{SelectListView} = require 'atom-space-pen-views'

module.exports = class PluginsListView extends SelectListView
	initialize: ->
		super
		@panel = null

		@addClass('overlay from-top')

		@filterEditorView.getModel().getBuffer().onDidStopChanging => @updateItems()

		@open()

	viewForItem: (item) ->
		"<li>
			<div class=\'primary-line\'>#{item.name}</div>
			<div class=\'secondary-line\'>#{item.short_description}</div>
		</li>"

	getFilterKey: ->
		return 'name'

	updateItems: ->
		filterQuery = @getFilterQuery()
		if filterQuery
			atom.wordpressSuite.getSelectedSite().wpcli.plugins.wp.plugin.search "'#{filterQuery}'", {quiet:true,fields:'name,slug,short_description,version'}, (err,plugins) =>
				if err
					console.log err
					# @emitter.emit 'message', [ "Error Searching for #{filterQuery}", 'error', err ]
				else
					@setItems(plugins)

	open: ->
		@panel ?= atom.workspace.addModalPanel(item: this)
		@panel.show()
		@focusFilterEditor()

	close: ->
		panel = @panel
		@panel = null
		panel?.destroy()

	confirmed: (item) ->
		atom.wordpressSuite.getSelectedSite().wpcli.plugins.install(item.slug)
		@close()

	cancelled: ->
		@close()