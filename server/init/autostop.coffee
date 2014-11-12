application = require '../models/application'
log = require('printit')
    prefix: null
    date: true

module.exports = () ->
    application.all (err, apps) ->
        for app in apps
            if app['name'] is 'konnectors'
              if app['isStoppable'] is true
                  log.warn 'auto-stop for this app is activated,'
                  + 'disable this option to activate auto-import'
