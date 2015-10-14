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

get_component_versions = (application, environment, robot, msg, callback) ->
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

    versions = null
    try
      versions = JSON.parse body
    catch error
      msg.send "Ran into an error parsing JSON :("
      return

    callback(application, environment, versions, msg)

respond_versions = (application, environment, versions, msg) ->
  versions_content = "The versions of application " + application + " in environment " + environment + " are:\n"
  for component in versions
    versions_content += "  " + component.application_component.component.name + ": " + component.version + "\n" if component.version

  #console.log versions_content
  msg.send versions_content


module.exports = (robot) ->
  robot.respond /get versions of app (.*) and env (.*)/i, (msg) ->
    application = msg.match[1]
    environment = msg.match[2]

    get_component_versions(application, environment, robot, msg, respond_versions)


#  robot.respond /get version diff of app (.*) between env (.*) and  (.*)/i, (msg) ->
#    application = msg.match[1]
#    source_environment = msg.match[2]
#    target_environment = msg.match[3]
#    source_versions = get_component_versions(application, source_environment, robot, msg)
#    target_versions = get_component_versions(application, target_environment, robot, msg)
#
#    versions_content = "The version diff of application " + application + " between environment " + source_environment + " and " + target_environment + " are:\n"
#    for component in source_versions
#      versions_content += "  " + component.application_component.component.name + ": " + component.version + "\n" if component.version
#
#    console.log versions_content

if process.env.UNIT_TEST == "1"
  Robot = require("hubot/src/robot")
  robot = new Robot null, 'slack', yes

  application = "E-Finance"
  environment = "test"

  versions = get_component_versions(application, environment, robot, null, respond_versions)








