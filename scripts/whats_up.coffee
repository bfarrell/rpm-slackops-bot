# Description:
#   shows latest failed request information
#
# Configuration:
#   RPM_HOST RPM_PORT RPM_TOKEN RPM_CONTEXT_ROOT
#
# Commands:
#   hubot wtf? - shows latest failed request information
#   hubot wtf up with request <id>? - information about a request
#   hubot wtf up with environment <id>? - information about an environment
#   hubot wtf happened with request <id>? - shows the 10 latest activities for the request
#

DAYS_AGO = 3
RPM_URL = 'http://' + process.env.RPM_HOST + ':' + process.env.RPM_PORT + '/' + (process.env.RPM_CONTEXT_ROOT || "brpm/")
RPM_REST_URL = RPM_URL + "v1/"
TOKEN_SUFFIX = 'token=' + process.env.RPM_TOKEN

find_failed_requests = (robot, msg, filter) ->
  robot.http(RPM_REST_URL + "requests?" + TOKEN_SUFFIX)
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
    msg.send " - deployed to environment #{bad_request.environment.name} with id #{bad_request.environment.id}"
  else
    msg.send 'All Clear!'

latest_failed_step = (robot, msg, steps) ->
  if steps != null && steps.length > 0
    msg.send 'I found a step in the RPM request in a problem state:'
    bad_step = steps[steps.length-1]
    msg.send " - Step named #{bad_step.name} with id #{parseInt(bad_step.id)}"
  else
    msg.send 'All Clear!'

find_failed_steps = (robot, msg, filter) ->
  robot.http(RPM_REST_URL + "steps?" + TOKEN_SUFFIX)
  .header('Content-Type', 'application/json')
  .header('Accept', 'application/json')
  .get(filter) (err, res, body) ->
    if err
      robot.emit 'error', err
      return

    if res.statusCode > 201
      exitCode = res.statusCode
      msg.send "Steps didn't come back with OK #{exitCode}\n" + body
      return

    data = null
    try
      data = JSON.parse body
    catch parse_error
      robot.emit 'error', parse_error
    latest_failed_step(robot, msg, data)

find_activity_logs = (robot, msg, requestId, callback) ->
  url = RPM_REST_URL + "activity_logs?filters[request_id]=" + requestId + "&" + TOKEN_SUFFIX
  console.log url
  robot.http(url)
  .header('Content-Type', 'application/json')
  .header('Accept', 'application/json')
  .get() (err, res, body) ->
    if err
      robot.emit 'error', err
      return

    if res.statusCode > 201
      exitCode = res.statusCode
      msg.send "Steps didn't come back with OK #{exitCode}\n" + body
      return

    data = null
    try
      data = JSON.parse body
    catch parse_error
      robot.emit 'error', parse_error

    callback(data, msg)

respond_activity_logs = (activity_logs, msg) ->
  msg.send "Showing the 10 last actions that happened on this request:"
  for activity_log in activity_logs[..10]
    msg.send "On "+ activity_log.created_at + " by " + activity_log.user.login + ":\n" + activity_log.activity

module.exports = (robot) ->
  robot.respond /wtf\?/i, (msg) ->
    msg.send "I'll take a look, one second."
    now = new Date
    earlier = new Date
    earlier.setDate(now.getUTCDate() - DAYS_AGO)
    filter = JSON.stringify({
      filters: {
        aasm_state: 'problem',
#      started_start_date: "#{earlier.getMonth + 1}/#{earlier.getUTCDay}/#{earlier.getFullYear}",
#      started_end_date: "#{now.getMonth + 1}/#{now.getUTCDay}/#{now.getFullYear}",
      }})
    find_failed_requests(robot, msg, filter)

  robot.respond /wtf up with request (.*)?/i, (msg) ->
    request = parseInt(msg.match[1]) - 1000
    msg.send "I'll take a look, one second."
    now = new Date
    earlier = new Date
    earlier.setDate(now.getUTCDate() - DAYS_AGO)
    filter = JSON.stringify({
      filters: {
        aasm_state: 'problem',
        request_id: "#{request}"
      }})
    find_failed_steps(robot, msg, filter)

  robot.respond /wtf up with environment (.*)?/i, (msg) ->
    environment = parseInt(msg.match[1])
    msg.send "I'll take a look, one second."
    now = new Date
    earlier = new Date
    earlier.setDate(now.getUTCDate() - DAYS_AGO)
    filter = JSON.stringify({
      filters: {
        aasm_state: 'problem',
        environment_id: "#{environment}"
      }})
    find_failed_requests(robot, msg, filter)

  robot.respond /wtf happened with request (.*)?/i, (msg) ->
    requestId = parseInt(msg.match[1]) - 1000
    msg.send "I'll take a look, one second."
    find_activity_logs(robot, msg, requestId, respond_activity_logs)



