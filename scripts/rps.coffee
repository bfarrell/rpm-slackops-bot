go = ['rock!', 'paper!', 'scissors!']
mine = null

module.exports = (robot) ->
  robot.hear /RoShamBo/i, (res) ->
    mine = res.random go
    res.send mine

  robot.hear /rock\!/i, (res) ->
    if mine == 'paper!'
      res.send 'I WIN!'

  robot.hear /paper\!/i, (res) ->
    if mine == 'scissors!'
      res.send 'I WIN!'

  robot.hear /scissors\!/i, (res) ->
    if mine == 'rock!'
      res.send 'I WIN!'

  robot.hear /I\ WIN\!/i, (res) ->
    mine = null
