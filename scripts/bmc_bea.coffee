
RPM_HOST = 'localhost'
RPM_PORT = '8080'

rpm_url = 'http://' + RPM_HOST + ':' + RPM_PORT + '/v1/'
token = '?token=b97b1b8df8bdce7b743090004f7ad83b7131be7b'

module.exports = (robot) ->
  robot.hear /what\'s\ up\?/i, (res) ->
    res.send 'chillin'

  robot.respond /help/i, (res) ->
    res.send 'some helpful message here'

  robot.respond /show\ users/i, (msg) ->
    msg.send 'working on it.'
    robot.http(rpm_url + 'users' + token)
      .header('Content-Type', 'application/json')
      .header('Accept', 'application/json')
      .get() (err, res, body) ->
        data = null
        try
          data = JSON.parse body
        catch error
          msg.send "Error parsing result"
        msg.send JSON.stringify(data, null, 4)
