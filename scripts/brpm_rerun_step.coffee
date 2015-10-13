#
# Description:
#   This command will restart a step based on an id.  It requires the state to be in problem for the step.  Otherwise, it will throw an error.
#
# Commands:
# hubot restart step <step_id> - Will send a resolve command to rpm to set the step to rerun and the request back to in progress
RPM_URL = 'http://' + process.env.RPM_HOST + ':' + process.env.RPM_PORT + '/brpm/'
RPM_REST_URL = RPM_URL + "v1/"
TOKEN_SUFFIX = '?token=' + process.env.RPM_TOKEN

module.exports = (robot) ->
  robot.respond /restart step (.*)/i, (msg) ->
    msg.send "10-4 Good buddy!"
    step = msg.match[1]

    input = JSON.stringify({
    	"aasm_event":"resolve"
    })

    robot.http(RPM_REST_URL + "steps/#{step}" + TOKEN_SUFFIX)
  	  .header('Accept', 'application/json')
      .header('Content-Type', 'application/json')
      .put(input) (err, res, body) ->

        if err
          msg.send "Encountered an for step #{step} error :( #{err}"
          return

        if res.statusCode isnt 202
          exitCode = res.statusCode
          msg.send "Step #{step} didn't come back with Accepted #{exitCode}\n" + body
          return

        data = null
        try
          data = JSON.parse body
        catch error
          msg.send "Ran into an error parsing JSON :("
          return

        requestId = parseInt(data.request.number)
        msg.send "Step #{step} has been restarted"
        msg.send RPM_URL + "requests/" + requestId + TOKEN_SUFFIX
