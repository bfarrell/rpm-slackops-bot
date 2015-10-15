# Description:
#   acknowledges appreciation of job well done
#
# Configuration:
#   RPM_HOST RPM_PORT RPM_TOKEN RPM_CONTEXT_ROOT
#
# Commands:
#   hubot thanks - acknowledges appreciation
#

DAYS_AGO = 3
RPM_URL = 'http://' + process.env.RPM_HOST + ':' + process.env.RPM_PORT + '/' + (process.env.RPM_CONTEXT_ROOT || "brpm/")
RPM_REST_URL = RPM_URL + "v1/"
TOKEN_SUFFIX = 'token=' + process.env.RPM_TOKEN

RESPONSES = ["Anytime!", "You betcha!", "You got it!", "It was nothin", "I'm a bot.. It's my job."]

module.exports = (robot) ->
  robot.respond /thanks/i, (res) ->
    res.send res.random RESPONSES
