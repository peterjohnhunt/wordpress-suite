Wordpress = require './wordpress'
{CompositeDisposable, Directory, File} = require 'atom'

Array.prototype.difference = (a) ->
    return @filter (i) ->
        return a.indexOf(i) < 0

module.exports = wordpressSuite =
    consumeAutoreload: (reloader) ->
        reloader(pkg:"wordpress-suite",files:["package.json"],folders:["lib/","menus/","node_modules/"])

    activate: ->
        if atom.inDevMode()
            try
                @initialize()
            catch e
                console.log e
        else
            @initialize()

    initialize: ->
        # Variables
        @sites = [];
        @paths = atom.project.getPaths();

        # Subscriptions
        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.project.onDidChangePaths (paths) => @foldersChanged(paths)

        # Initial Setup
        @foldersAdded(@paths)

    folderGetProjectId: (path) ->
        for site, index in @sites
            if site.isRelatedPath(path)
                return index
        return false

    foldersChanged: (paths) ->
        if paths.length > @paths.length
            addedPaths = paths.difference(@paths);
            @foldersAdded(addedPaths)
        else
            removedPaths = @paths.difference(paths);
            @foldersRemoved(removedPaths)
        @paths = paths

    foldersAdded: (paths) ->
        for path in paths
            site_id = @folderGetProjectId(path)
            if site_id is false
                root = new Directory(path.split('wp-content', 1)[0])
                if root.getSubdirectory('wp-content').existsSync()
                    site = new Wordpress(root)
                    site.addRelatedPath(path)
                    @sites.push(site)
            else
                site = @sites[site_id]
                site.addRelatedPath(path)

    foldersRemoved: (paths) ->
        for path in paths
            site_id = @folderGetProjectId(path)
            if site_id isnt false
                site = @sites[site_id]
                site.removeRelatedPath(path)
                if site.paths.length is 0
                    @sites[site_id].dispose()
                    @sites.splice(site_id,1);

    deactivate: ->
        # Remove All Projects
        for site in @sites
            site.dispose()

        # Clean Up Subscriptions
        @subscriptions?.dispose()