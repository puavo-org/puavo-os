{EventEmitter} = require "events"
request = require("request")

class Puavo extends EventEmitter

  constructor: (config) ->
    @organisations = config.organisations
    console.log @organisationsorganisationDevicesByMac
    @organisationDevicesByMac = {}
    @organisationSchoolsById = {}
    @organisationDevicesByHostname = {}

  pollStart: ->
    console.log("pollStart")

    for key, value of @organisations then do (key, value) =>
      console.log("Organisation: ", key)
  
      auth = "Basic " + new Buffer(value["username"] + ":" + value["password"]).toString("base64");
  
      requestCount = 2
      done = (args...) =>
        requestCount -= 1
        if requestCount is 0
          @emit "ready"
          done = ->
  
      # Get schools
      request {
        url: value["puavoDomain"] + "/users/schools.json",
        headers:  {"Authorization" : auth}
      }, (error, res, body) =>
        if !error && res.statusCode == 200
          schools = JSON.parse(body)
          debugger
          @organisationSchoolsById[key] = {}
          console.info "Fetched #{ schools.length } schools from #{ value["puavoDomain"] }"
          for school in schools
            @organisationSchoolsById[key][school.puavo_id] = {}
            @organisationSchoolsById[key][school.puavo_id]["name"] = school.name
        else
          console.log("Can't connect to puavo server: ", error)
        done error

      # Get devices
      request {
        method: 'GET',
        url: value["puavoDomain"] + "/devices/devices.json",
        headers:  {"Authorization" : auth}
      }, (error, res, body) =>
        if !error && res.statusCode == 200
          devices = JSON.parse(body)
          @organisationDevicesByMac[key] = {}
          console.info "Fetched #{ devices.length } devices from #{ value["puavoDomain"] }"
          @organisationDevicesByHostname[key] = {}
          for device in devices
            if device["puavoSchool"]
              school_id = device.puavoSchool[0].rdns[0].puavoId
              @organisationDevicesByHostname[key][ device["puavoHostname"][0] ] = {}
              @organisationDevicesByHostname[key][ device["puavoHostname"][0] ]["school_id"] = school_id
            if device["macAddress"]
              @organisationDevicesByMac[key][ device["macAddress"][0] ] = {}
              @organisationDevicesByMac[key][ device["macAddress"][0] ]["hostname"] = device["puavoHostname"][0]
        else
          console.log("Can't connect to puavo server: ", error)
  
        done error
  
  lookupDeviceName: (org, mac) ->

  lookupSchoolName: (org, deviceHostname) ->


module.exports = Puavo
