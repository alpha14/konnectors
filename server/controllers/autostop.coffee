application = require '../models/application'
log = require('printit')
    prefix: null
    date: true

fetch = (callback) ->
    application.all (err, apps) ->
        for app in apps
            if app['name'] is 'konnectors'
                state = app['isStoppable']
                if state is true
                    log.warn 'auto-stop for this app is activated,'
                    + 'disable this option to activate auto-import'
                callback state

module.exports =
    state: (req, res, next) ->
        fetch (state) ->
            res.send state
