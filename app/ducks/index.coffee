import _ from 'lodash'
import { combineReducers } from 'redux'
req = require.context("/app/ducks", true, /^(?!.*index.coffee)((.*\.(coffee\.*))[^.]*$)/ )
reducers = {}
for eachFile in req.keys().sort()
  reducers[_.first _.last(eachFile.split("/")).split(".")] = req(eachFile).default

export default combineReducers(reducers)


