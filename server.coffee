americano = require 'americano'
RealtimeAdapter = require 'cozy-realtime-adapter'
initKonnectors = require './server/init/konnectors'
patchKonnectors = require './server/init/patch'
poller = require './server/lib/konnector_poller'
autostopcheck = require './server/init/autostop'

process.env.TZ = 'UTC'

params =
    name: 'konnectors'
    port: process.env.PORT or 9358
    host: process.env.HOST or '127.0.0.1'
    root: __dirname

americano.start params, (app, server) ->
    realtime = RealtimeAdapter server: server, ['konnector.update']
    initKonnectors ->
        autostopcheck()
        patchKonnectors -> poller.start()
