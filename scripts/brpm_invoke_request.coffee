RPM_HOST = 'localhost'
RPM_PORT = '8080'
RPM_URL = 'http://' + RPM_HOST + ':' + RPM_PORT + '/brpm/v1/'
TOKEN = '?token=d66d399360c20a06bf9bb0de1d7b6191d809e076'

module.exports = (robot) ->
  robot.respond /invoke request/i, (msg) ->
  	data = JSON.stringify({
  			"requestor_id":1
  			"deployment_coordinator_id":1
  			"name":"Slack Request"
  			"request_template_id":33
  			"environment":"DemoQAEnv"
  		})
    robot.http(RPM_URL + "requests" + TOKEN)
      .header('Accept', 'application/json')
      .header('Content-Type', 'application/json').post(data) (err, res, body) ->
    	if res.statusCode isnt 201
    		exitCode = res.statusCode 		
    		msg.send "Request didn't come back with OK #{exitCode}"
    		return
    	msg.send "Worked!"