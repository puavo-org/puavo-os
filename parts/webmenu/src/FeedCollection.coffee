Backbone = require "backbone"
child = require "child_process"
Q = require "q"

exec = (cmd) ->
    return Q.promise (resolve, reject) ->
        child.exec cmd, (err, stdout, stderr) ->
            return reject(err) if err
            resolve({
                stdout: stdout
                stderr: stderr
            })

        null


class FeedCollection extends Backbone.Collection

    constructor: (models, opts) ->
        super
        @command = opts.command
        @_fetch()

    _fetch: ->
        if not @command
            console.warn "feedCMD not set"
            return

        exec(@command).then( (out) =>
            return JSON.parse(out.stdout)
        ).then( (feeds) =>
            @reset(feeds)
        ).catch( (err) =>
            console.error "Failed to fetch feeds", @command, err
            @emit("error", err)
        ).delay(1000 * 60 * 60).then(@_fetch.bind(this))


module.exports = FeedCollection
