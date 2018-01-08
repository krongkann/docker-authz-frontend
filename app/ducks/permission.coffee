import { defineAction } from 'redux-define'
axios = require 'axios'

DEFAULT_STATE = { servernames: ['gg', 'hh'], commands: { puppy: true }}

export TYPES = defineAction('PERMISSSION',
  ['SET', 'SELECT_USERNAME', 'SELECT_SERVERNAME', 'CHANGE'])

export actions =
  fetch: () ->
    (dispatch) ->
      axios.defaults.baseURL =  '/permission'
      servernames = ['jj'] #graphql
      usernames = ['kk']
      commands =
        ll: false
      dispatch
        type: TYPES.SET
        payload: { servernames, usernames, commands }
  changePermission: (params) ->
    (dispatch) ->
      console.log 'trap ', params

export default (state = DEFAULT_STATE, action) ->
  switch action.type
    when TYPES.SET
      _.extend {}, state, action.payload
    when TYPES.SELECT_SERVERNAME
      _.extend {}, state, { selectedServername: action.payload }
    when TYPES.SELECT_USERNAME
      _.extend {}, state, { selectedUsername: action.payload }
    else
      state
