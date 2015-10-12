module.exports = (robot) ->
  robot.hear /what\'s\ up\?/i, (res) ->
    res.send 'chillin'
