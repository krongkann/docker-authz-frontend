import { defineAction } from 'redux-define'
import { GraphQLClient, request }  from 'graphql-request'
client = new GraphQLClient '/graphql' 
axios = require 'axios'

DEFAULT_STATE = { servernames: ['gg', 'hh'], commands: { puppy: true }}

export TYPES = defineAction('PERMISSSION',
  ['SET', 'SELECT_USERNAME', 'SELECT_SERVERNAME', 'CHANGE'])

export actions =
  fetch: () ->
    (dispatch) ->
      axios.defaults.baseURL =  '/permission'
      query = """
query($username: String, $servername: String){
  commands(username: $username,
    servername: $servername){
    command
    allow
  }
  usernames
  servernames
}
      """
      # result =
      #   usernames: ['cc', 'aa']
      #   servernames: ['dd', 'bb']
      #   commands:
      #     docker_ps: true
      result = client.request query,
        username: '1' #access state
        servername: '2'
      dispatch
        type: TYPES.SET
        payload: result
  changePermission: (params) ->
    (dispatch) ->
      mutation = """
mutation($username: String, $servername: String, $command: String, $allow: Boolean){
  updateUsercommand(username: $username , servername: $servername, allow: $allow, command: $command)
}
      """
      result = client.request mutation, params
      console.log 'trap ', @
  allowAll: (params) ->
    (dispatch) ->
      mutation = """
mutation($username: String, $servername: String){
  setAllowAll(username: $username , servername: $servername, allow: true) {
    username
    servername
    allow
  }
}
      """
      await client.request mutation, params
  denyAll: (params) ->
    (dispatch) ->
      mutation = """
mutation($username: String, $servername: String){
  setAllowAll(username: $username , servername: $servername, allow: false) {
    username
    servername
    allow
  }
}
      """
      await client.request mutation, params

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
