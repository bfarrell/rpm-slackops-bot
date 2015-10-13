# Description:
#   shows latest failed request information
#
# Configuration:
#   RPM_HOST RPM_PORT RPM_TOKEN RPM_CONTEXT_ROOT
#
# Commands:
#   hubot what's up? - shows latest failed request information
#

DAYS_AGO = 3
if process.env.RPM_CONTEXT_ROOT == null
  context_root = 'brpm/'
else
  context_root = process.env.RPM_CONTEXT_ROOT + '/'

RPM_URL = 'http://' + process.env.RPM_HOST + ':' + process.env.RPM_PORT + '/' + context_root
RPM_REST_URL = RPM_URL + "v1/"
TOKEN_SUFFIX = '?token=' + process.env.RPM_TOKEN

find_failed_requests = (robot, msg) ->
  now = new Date
  earlier = new Date
  earlier.setDate(now.getUTCDate() - DAYS_AGO)
  filter = JSON.stringify({
    filters: {
      aasm_state: 'problem',
#      started_start_date: "#{earlier.getMonth + 1}/#{earlier.getUTCDay}/#{earlier.getFullYear}",
#      started_end_date: "#{now.getMonth + 1}/#{now.getUTCDay}/#{now.getFullYear}",
    }})
  robot.http(RPM_REST_URL + "requests" + TOKEN_SUFFIX)
    .header('Content-Type', 'application/json')
    .header('Accept', 'application/json')
    .get(filter) (err, res, body) ->
      if err
        robot.emit 'error', err
        return

      if res.statusCode > 201
        exitCode = res.statusCode
        msg.send "Request didn't come back with OK #{exitCode}\n" + body
        return

      data = null
      try
        data = JSON.parse body
      catch parse_error
        robot.emit 'error', parse_error
      latest_failed_request(robot, msg, data)


latest_failed_request = (robot, msg, requests) ->
  if requests != null && requests.length > 0
    msg.send 'I found at least one RPM request in a problem state:'
    bad_request = requests[requests.length-1]
    msg.send " - Request named #{bad_request.name} with id #{parseInt(bad_request.id) + 1000}"
    msg.send " - for application #{bad_request.apps[0].name}"
    msg.send " - deployed to environment #{bad_request.environment.name}"
  else
    msg.send 'All Clear!'


zero_pad = (x) ->
  if x < 10 then '0'+x else ''+x

Date::pretty_string = ->
  d = zero_pad(this.getDate())
  m = zero_pad(this.getMonth() + 1)
  y = this.getFullYear()
  y + m + d

module.exports = (robot) ->
  robot.respond /what\'s\ up\?/i, (msg) ->
    msg.send "I'll take a look, one second."
    find_failed_requests(robot, msg)
