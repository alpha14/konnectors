americano = require 'americano-cozy'
requestJson = require 'request-json'
request = require 'request'
moment = require 'moment'
cheerio = require 'cheerio'
fs = require 'fs'

File = require '../models/file'
fetcher = require '../lib/fetcher'
filterExisting = require '../lib/filter_existing'
saveDataAndFile = require '../lib/save_data_and_file'

log = require('printit')
    prefix: "Github"
    date: true


# Models

CodeBill = americano.getModel 'CodeBill',
    date: Date
    vendor: String
    amount: Number
    plan: String
    fileId: String

CodeBill.all = (callback) ->
    CodeBill.request 'byDate', callback

# Konnector

module.exports =

    name: "Github"
    slug: "github"
    description: "Download all your Github Bills."
    vendorLink: "https://www.github.com/"

    fields:
        login: "text"
        password: "password"
        folderPath: "folder"
    models:
        codebill: CodeBill

    # Define model requests.
    init: (callback) ->
        map = (doc) -> emit doc.date, doc
        CodeBill.defineRequest 'byDate', map, (err) ->
            callback err

    fetch: (requiredFields, callback) ->
        log.info "Import started"

        fetcher.new()
            .use(logIn)
            .use(parsePage)
            .use(filterExisting log, CodeBill)
            .use(saveDataAndFile log, CodeBill, 'github', ['bill'])
            .args(requiredFields, {}, {})
            .fetch ->
                log.info "Import finished"
                callback()


# Procedure to login to Free website.
logIn = (requiredFields, billInfos, data, next) ->
    loginUrl = "https://github.com/session"

    signInOptions =
        method: 'POST'
        jar: true
        url: "https://github.com/session"
        form:
            login: requiredFields.login
            password: requiredFields.password
            commit: 'Sign in'

    logInOptions =
        method: 'GET'
        jar: true
        url: "https://github.com/login"

    billOptions =
        method: 'GET'
        jar: true
        url: "https://github.com/settings/billing"

    request logInOptions, (err, res, body) ->
        if err then next err
        $ = cheerio.load body
        inputs = $('#login input')
        if inputs.length > 2
            token = $(inputs[1]).val()
        else
            token = ''
        signInOptions.form.authenticity_token = token

        request signInOptions, (err, res, body) ->
            request billOptions, (err, res, body) ->
                if err then next err
                else
                    data.html = body
                    next()


# Parse the fetched page to extract bill data.
parsePage = (requiredFields, bills, data, next) ->
    bills.fetched = []
    $ = cheerio.load data.html

    $('.succeeded').each ->
        date = $(this).find('.date time').text()
        amount = parseFloat $(this).find('.amount').text().substring 5
        pdfurl = "https://github.com#{$(this).find('.receipt a').attr 'href'}"

        switch amount
            when 7 then plan = 'micro'
            when 12 then plan = 'small'
            when 22 then plan = 'medium'
            when 50 then plan = 'large'

        bills.fetched.push
            date: moment date
            amount: amount
            pdfurl: pdfurl
            plan: plan
    if bills.fetched.length is 0
        log.error "No bills retrieved"
    next()
