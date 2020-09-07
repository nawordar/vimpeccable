
logLevels =
  debug: 1
  info: 2
  warning: 3
  error: 4
  all: {1, 2, 3, 4}
  strings: {"debug", "info", "warning", "error"}

class log
  levels: logLevels
  minLogLevel: logLevels.info

  outputHandler: (message, level) ->
    fullMessage = "[vimp] #{log.levels.strings[level]}: #{message}\n"
    if level == logLevels.error
      vim.api.nvim_err_write(fullMessage)
    else
      vim.api.nvim_out_write(fullMessage)

  log: (message, level) ->
    if not log.isLevelEnabled(level)
      return

    if message == nil
      message = "nil"
    elseif type(message) == 'table'
      message = vim.inspect(message)
    elseif type(message) != 'string'
      message = tostring(message)

    log.outputHandler(message, level)

  isLevelEnabled: (level) ->
    return level >= log.minLogLevel

  debug: (message) ->
    log.log(message, logLevels.debug)

  info: (message) ->
    log.log(message, logLevels.info)

  warning: (message) ->
    if log.isLevelEnabled(logLevels.warning)
      log.log(message, logLevels.warning)

  error: (message) ->
    if log.isLevelEnabled(logLevels.error)
      log.log(message, logLevels.error)

