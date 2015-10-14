# Description:
#   gets the component versions of an application in an environment
#
# Configuration:
#   RPM_HOST RPM_PORT RPM_TOKEN
#
# Commands:
#   hubot get versions for app X and env Y
#

RPM_URL = 'http://' + process.env.RPM_HOST + ':' + process.env.RPM_PORT + '/brpm/'
RPM_REST_URL = RPM_URL + "v1/"
TOKEN_SUFFIX = 'token=' + process.env.RPM_TOKEN

get_component_versions = (application, environment, robot, msg) ->
  robot.http(RPM_REST_URL + "installed_components?filters[app_name]=" + application + "&filters[environment_name]=" + environment + "&" + TOKEN_SUFFIX)
  .header('Accept', 'application/json')
  .header('Content-Type', 'application/json')
  .get() (err, res, body) ->
    if err
      msg.send "Encountered an error :( #{err}"
      return

    if res.statusCode isnt 200
      exitCode = res.statusCode
      msg.send "Request didn't come back with OK #{exitCode}\n" + body
      return

    data = null
    try
      data = JSON.parse body
    catch error
      msg.send "Ran into an error parsing JSON :("
      return

    versions_content = "The versions of application " + application + " in environment " + environment + " are:\n"
    for component in data
      versions_content += "  " + component.application_component.component.name + ": " + component.version + "\n" if component.version

    console.log versions_content
    msg.send versions_content

module.exports = (robot) ->
  robot.respond /get versions of app (.*) and env (.*)/i, (msg) ->
    application = msg.match[1]
    environment = msg.match[2]
    get_component_versions(application, environment, robot, msg)

if process.env.UNIT_TEST == "1"
  Robot = require("hubot/src/robot")
  robot = new Robot null, 'slack', yes

  application = "E-Finance"
  environment = "test"

  get_component_versions(application, environment, robot, null)








