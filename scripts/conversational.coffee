root = exports ? this
RPM_URL = 'http://' + process.env.RPM_HOST + ':' + process.env.RPM_PORT + '/brpm/'
RPM_REST_URL = RPM_URL + "v1/"
TOKEN_SUFFIX = 'token=' + process.env.RPM_TOKEN

create_request = (action, application, environment, requestTemplate, requestName, robot, msg) ->
  msg.send "create_request was called successfully";

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

  robot.http(RPM_REST_URL + "requests?" + TOKEN_SUFFIX)
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
    msg.send RPM_URL + "requests/" + requestId + "?" + TOKEN_SUFFIX

clear_global_values =() ->
    root.app = null
    root.environment = null
    root.request = null

get_response = (cmd) ->
  switch cmd
    when "deploy"
      # Make sure paramerts are valid
      if root.app? and root.request? and root.environment?
        response = "Are you sure you want to redploy application *#{root.app}* with Request Template *#{root.request}* to the *#{root.environment}* environment?"
      else if root.app? and root.request?
        response = "What environment do you want to deploy app *#{root.app}* with request template *#{root.request}*?\n  Please use command *\"environ is <environment_name>.\"*"
      else if root.app?
        response = "What request template do you want to use to deploy *#{root.app}*?\n Please use command *\"request is <request_template_name>.\" *"
      else
        response = "When deploying you need to supply an application.\n Please use the command *\"deploy <application_name>\"*."

    when "request"
      response = "What Environment do you want to deploy *#{root.request}*?\n Please use command *\"environ is <environment_name>\"*."

    when "environment"
      if root.request? and root.environment?
        response ="OK, Deploying *#{root.request}* to *#{root.environment}*."
      else
        response = "Please check request and enviorment requested.  Please use command *\"list global values\"* ."

deploy_values_set = (cmd) ->
  if root.app? and root.enviorment? and root.request?
    return true
  else
    return false

module.exports = (robot) ->

  robot.hear /yes/i, (res) ->
    if deploy_values_set
      create_request("invoke", root.app, root.environment, root.request, null, robot, res)
    else
      res.send "I can't deploy because all values aren't set."

  robot.hear /no/i, (res) ->
    res.send "Ok, I won't deploy it."
    clear_global_values()

  robot.respond /deploy (.*)/i, (res) ->
    root.app = res.match[1]
    res.send get_response("deploy")

  robot.hear /request\ is\ (.*)/i, (res) ->
    root.request = res.match[1]
    res.send get_response("request")

  robot.hear /environ is (.*)/i, (res) ->
    root.environment = res.match[1]
    res.send get_response("environment")
    action = "invoke"
    create_request(action, root.app, root.environment, root.request, null, robot, res)

  #List the paramerters that are needed for deploying an application
  robot.respond /list (.*) parameters/i, (res) ->
    command = res.match[1]
    switch command
      when "deploy"
        res.send "\n\n Paramerters: \n Application: - name of the application to deploy. \n Environment: - target environment to deploy to. \n RequestTemplate: - Name of the request template to use"
      else
        res.send "List doesn't support that command"

  robot.respond /clear global values/i, (res) ->
    clear_global_values()

  robot.respond /list global values/i, (res) ->
    res.send "\n
    Application -> #{root.app}\n
    Request Teplate -> #{root.request}\n
    Environment -> #{root.environment}\n"
