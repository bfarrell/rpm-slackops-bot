oot = exports ? this

get_response = (cmd) ->
  switch cmd
    when "deploy"
      # Make sure paramerts are valid
      if root.app? and root.request? and root.environment?
        response = "Are you sure you want to redploy application #{root.app} with Request Template #{root.request} to the #{root.environment} environment?"
      else if root.app? and root.request?
        response = "What environment do you want to deploy app #{root.app} with request template #{root.request}?"
      else if root.app?
        response = "What request template do you want to use to deploy #{root.app}?"
      else
        response = "When deploying you need to supply an appication. Please use the command deploy <application_name>"

    when "request"
      response = "What Environment do you want to deploy #{root.request}?"

    when "environment"
      if root.request? and root.environment?
        response ="OK, Deploying #{root.request} to #{root.environment}"
      else
        response = "Please check request and enviorment requested."


module.exports = (robot) ->

  robot.respond /deploy/i, (res) ->
    res.send get_response("deploy")

  robot.respond /deploy (.*)/i, (res) ->
    root.app = res.match[1]
    res.send get_response("deploy")

  robot.respond /request (.*)/i, (res) ->
    root.request = res.match[1]
    res.send get_response("request")

  robot.respond /environment (.*)/i, (res) ->
    root.environment = res.match[1]
    res.send get_response("environment")
    action = "create"
    create_request(action, root.app, root.environment, root.request, null, robot, msg)

  #List the paramerters that are needed for deploying an application
  robot.respond /list (.*) parameters/i, (res) ->
    command = res.match[1]
    switch command
      when "deploy"
        res.send "\n\n Paramerters: \n Application: - name of the application to deploy. \n Environment: - target environment to deploy to. \n RequestTemplate: - Name of the request template to use"
      else
        res.send "List doesn't support that command"

  robot.respond /clear global values/i, (res) ->
    root.app = null
    root.environment = null
    root.request = null

  robot.respond /list global values/i, (res) ->
    res.send "\n
    Application -> #{root.app}\n
    Request Teplate -> #{root.request}\n
    Environment -> #{root.environment}\n"
