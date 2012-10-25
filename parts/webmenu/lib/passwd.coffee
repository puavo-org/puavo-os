
{exec, spawn} = require "child_process"


passwd = module.exports = (username, cb) ->
  cmd = spawn "getent", ["passwd", username]
  output = ""
  cmd.stdout.on "data", (data) -> output += data.toString()

  cmd.on "exit", (code) ->
    if code isnt 0
      return cb new Error "failed get user data from getent"

    console.error "OU", output

    [ username,
      __,
      uid,
      gid,
      gecos,
      home,
      shell ] = output.split(":")

    [ fullName,
      room,
      phoneNumber,
      workNumber,
      other ] = gecos.split(",")

    cb null,
      username: username
      uid: uid
      gid: gid
      home: home
      shell: shell
      fullName: fullName
      room: room
      phoneNumber: phoneNumber
      workNumber: workNumber
      other: other

if require.main is module
  passwd "epeli", (err, data) ->
    console.log err, data
