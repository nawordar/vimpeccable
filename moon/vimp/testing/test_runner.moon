
require('vimp')
stringUtil = require('vimp.util.string')
assert = require("vimp.util.assert")
log = require("vimp.util.log")
try = require("vimp.util.try")
util = require("vimp.util.util")

class TestRunner
  _getPluginRootPath: =>
    matches = [x for x in string.gmatch(vim.api.nvim_eval('&rtp'), "([^,]+)") when stringUtil.endsWith(x, '/vimpeccable')]
    assert.that(#matches == 1)
    return matches[1]

  _runTestFunc: (func) =>
    startTab = vim.api.nvim_get_current_tabpage()
    vim.cmd('normal! ' .. util.replaceSpecialChars("<c-w>v<c-w>T"))
    testTab = vim.api.nvim_get_current_tabpage()
    bufferHandle = vim.api.nvim_create_buf(true, false)
    vim.cmd("b #{bufferHandle}")
    -- Always throw exceptions during testing
    vimp.mapErrorHandlingStrategy = vimp.mapErrorHandlingStrategies.none
    try
      do: ->
        func!
        vimp.unmapAll!
      finally: ->
        vim.api.nvim_set_current_tabpage(testTab)
        vim.cmd('tabclose')
        vim.cmd("bd! #{bufferHandle}")
        vim.api.nvim_set_current_tabpage(startTab)
        -- Try this in case the error occurred during func!
        -- We don't _just_ do this because we want the error from
        -- unmapAll to propagate if it gets that far
        try
          do: vimp.unmapAll
          catch: ->
            -- do nothing

  runTestFile: (filePath) =>
    successCount = @\_runTestFile(filePath)
    log.info("#{successCount} tests completed successfully")

  _runTestFile: (filePath) =>
    testClass = dofile(filePath)
    tester = testClass!
    log.debug("Executing tests for file #{filePath}...")

    successCount = 0

    for methodName,func in pairs(getmetatable(tester))
      if stringUtil.startsWith(methodName, 'test')
        log.info("Executing test #{methodName}...")
        @\_runTestFunc -> func(tester)
        successCount += 1

    return successCount

  runTestMethod: (filePath, testName) =>
    testClass = dofile(filePath)
    tester = testClass!
    log.debug("Executing test #{testName}...")
    @\_runTestFunc ->
      tester[testName](tester)
    log.info("Test #{testName} completed successfully")

  runAllTests: =>
    testRoot = "#{@\_getPluginRootPath!}/lua"

    successCount = 0
    for testFile in *vim.fn.globpath(testRoot, '**/test_*.lua', 0, 1)
      successCount += @\_runTestFile(testFile)

    log.info("#{successCount} tests completed successfully")
