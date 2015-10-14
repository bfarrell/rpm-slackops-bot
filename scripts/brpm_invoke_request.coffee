# Description:
#   creates and optionally starts a request
#
# Configuration:
#   RPM_HOST RPM_PORT RPM_TOKEN
#
# Commands:
#   hubot invoke request for app X and env Y
#   hubot invoke request for app X and env Y with name Z
#

RPM_URL = 'http://' + process.env.RPM_HOST + ':' + process.env.RPM_PORT + '/brpm/'
RPM_REST_URL = RPM_URL + "v1/"
TOKEN_SUFFIX = '?token=' + process.env.RPM_TOKEN

create_request = (action, application, environment, requestTemplate, requestName, robot, msg) ->
  if action is "invoke"
    execute_now = true
  else
    execute_now = false
  requestTemplate = requestTemplate || "Deploy " + application
  requestName = requestName || "Deploy " + application + " to " + environment

  msg.send action + " request from template '" + requestTemplate + "' for app " + application + " and env " + environment + " with name '" + requestName + "'..."

  data = JSON.stringify(
    {
      "request":
        "requestor_id": 1
        "deployment_coordinator_id": 1
        "name": requestName
        "template_name": requestTemplate
        "environment": environment
        "execute_now": execute_now
    })

  robot.http(RPM_REST_URL + "requests" + TOKEN_SUFFIX)
  .header('Accept', 'application/json')
  .header('Content-Type', 'application/json')
  .post(data) (err, res, body) ->
    if err
      msg.send "Encountered an error :( #{err}"
      return

    if res.statusCode isnt 201
      exitCode = res.statusCode
      msg.send "Request didn't come back with OK #{exitCode}\n" + body
      return

    data = null
    try
      data = JSON.parse body
    catch error
      msg.send "Ran into an error parsing JSON :("
      return

    requestId = parseInt(data.id) + 1000
    msg.send RPM_URL + "requests/" + requestId + TOKEN_SUFFIX

module.exports = (robot) ->
  robot.respond /(create|invoke) request for app (.*) and env (.*)/i, (msg) ->
    action = msg.match[1]
    application = msg.match[2]
    environment = msg.match[3]

    create_request(action, application, environment, null, null, robot, msg)

#  robot.respond /(create|invoke) request from template '(.*)' for app (.*) and env (.*)/i, (msg) ->
#    action = msg.match[1]
#    requestTemplate = msg.match[2]
#    application = msg.match[3]
#    environment = msg.match[4]
#
#    create_request(action, application, environment, requestTemplate, null, robot, msg)
#
  robot.respond /(create|invoke) request for app (.*) and env (.*) with name (.*)/i, (msg) ->
    action = msg.match[1]
    application = msg.match[2]
    environment = msg.match[3]
    requestName = msg.match[4]

    create_request(action, application, environment, null, requestName, robot, msg)

#  robot.respond /(create|invoke) request from template '(.*)' for app (.*) and env (.*) with name '(.*)'/i, (msg) ->
#    action = msg.match[1]
#    requestTemplate = msg.match[2]
#    application = msg.match[3]
#    environment = msg.match[4]
#    requestName = msg.match[5]
#
#    create_request(action, application, environment, requestTemplate, requestName, robot, msg)









