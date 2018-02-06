import { defineAction } from 'redux-define'
import { GraphQLClient, request }  from 'graphql-request'
client = new GraphQLClient '/graphql'

DEFAULT_STATE = { servernames: ['gg', 'hh'], commands: { puppy: true }}

export TYPES = defineAction('PERMISSSION',
  ['SET', 'SELECT_USERNAME', 'SELECT_SERVERNAME', 'CHANGE'])
export actions =
  fetch: (params) ->
    (dispatch) ->
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
      result = await client.request query, params
      if result.usernames
        result.usernames = _.sortBy result.usernames, (e) ->
          e.toLowerCase()
      if result.servernames
        result.servernames = _.sortBy result.servernames, (e) ->
          e.toLowerCase()
      if result.commands
        result.commands = _.reduce result.commands, (set, member) ->
          set[member.command] = member.allow
          return set
        , {}
      dispatch
        type: TYPES.SET
        payload: result

  getCommands: (params) ->
    (dispatch) ->
      query = """
        query($username: String, $servername: String){
          commands(username: $username,
            servername: $servername){
            command
            allow
          }
        }
      """
      result = await client.request query, params
      if result.commands
        result.commands = _.reduce result.commands, (set, member) ->
          set[member.command] = member.allow
          return set
        , {}
      result = _.extend result,
        selectedUsername: params.username
        selectedServername: params.servername
      dispatch
        type: TYPES.SET
        payload: result

  changePermission: (params) ->
    me = @
    (dispatch) ->
      mutation = """
        mutation($username: String, $servername: String, $command: String, $allow: Boolean, $userlogin: String ){
          updateUsercommand(username: $username , servername: $servername, allow: $allow, command: $command, userlogin: $userlogin)
        }
      """
      result = await client.request mutation, params
      me.fetch(params) dispatch

  allowAll: (params) ->
    me = @
    (dispatch) ->
      mutation = """
        mutation($username: String, $servername: String, $userlogin: String){
          setAllowAll(username: $username , servername: $servername, allow: true, userlogin: $userlogin) {
            username
            servername
            allow
          }
        }
      """
      await client.request mutation, params
      me.fetch(params) dispatch

  denyAll: (params) ->
    me = @
    (dispatch) ->
      mutation = """
        mutation($username: String, $servername: String, $userlogin: String){
          setAllowAll(username: $username , servername: $servername, allow: false, userlogin: $userlogin) {
            username
            servername
            allow
          }
        }
      """
      await client.request mutation, params
      me.fetch(params) dispatch

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
