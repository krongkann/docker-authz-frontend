import { defineAction }           from 'redux-define'
import { GraphQLClient, request }  from 'graphql-request'
client = new GraphQLClient '/graphql' 
axios = require 'axios'

DEFAULT_STATE = {}

export ACTIONS = defineAction('LOG', ['LOAD_DATA', 
                                      'SUCCESS', 
                                      'FILTER_LOG', 
                                      'SELECTOR', 
                                      'SEARCH', 
                                      'FILTER_LOG_BACK']) 
QUERYLOG = 
  """
query($after: String, $before: String, $filter: LogsFilter, $first: Int){
  logs(first: $first
    after: $after
    filter: $filter
    before: $before
    ){
    totalCount
    edges {
      node {
        id
        servername
        username
        command
        allow
        activity
        createdAt
        message
        error
        auth_type
        request_body
        response_body
        request_header
        response_header
        request_method
      }
      cursor
    }
    pageInfo {
      endCursor
    }
  }
}
"""
export actions = 
  getLog: (servername)=>
    query = QUERYLOG
    (dispatch) =>
      try
        data = await client.request query
        dispatch 
          type: ACTIONS.LOAD_DATA
          payload: 
            logs: _.get data, 'logs.edges'
            total: _.get data, 'logs.totalCount'
            endcursor: _.get data, 'logs.pageInfo'
        dispatch 
          type: ACTIONS.SUCCESS
          payload: true


      catch e
  getfilterLogNext:(cursor)->
    query = QUERYLOG
    (dispatch) =>
      try
        data = await client.request query,
        {
          after: cursor
        }
        dispatch 
          type: ACTIONS.LOAD_DATA
          payload: 
            logs: _.get data, 'logs.edges'
            total: _.get data, 'logs.totalCount'
            endcursor: _.get data, 'logs.pageInfo'
        dispatch 
          type: ACTIONS.FILTER_LOG
          payload: 'next'
       
       
      catch e
  getfilterLogBack:(cursor)->
    query = QUERYLOG
    (dispatch) =>
      try
        console.log "currrsorrrr", cursor

        data = await client.request query,
        {
          before: cursor
        }
        dispatch 
          type: ACTIONS.LOAD_DATA
          payload: 
            logs: _.get data, 'logs.edges'
            total: _.get data, 'logs.totalCount'
            endcursor: _.get data, 'logs.pageInfo'
        dispatch 
          type: ACTIONS.FILTER_LOG
          payload: 'back'
      catch e

  getSelector:()->
    query = """
query{
  logsServernames
} """
    userQuery = """
query{
  logsUsernames
}
    """
    commandQuery = """
query{
  logsCommands
}
"""
    (dispatch)=>
      try
        server = await client.request query
        user    = await client.request userQuery
        command    = await client.request commandQuery

        dispatch 
          type: ACTIONS.SELECTOR
          payload: 
            server : server.logsServernames
            user   : user.logsUsernames
            command : command.logsCommands

      catch e
  searchLog:({startDate, endDate, servername, username, command})->
    query = QUERYLOG
    (dispatch)=>
      try
        search    = await client.request query,
          {
            filter:
              servername: servername
              username: username
              command: command
              from: startDate
              to: endDate
              admin: true
          }
        dispatch 
          type: ACTIONS.LOAD_DATA
          payload:
            logs: _.get search, 'logs.edges'

      catch e

export default (state=DEFAULT_STATE, {type, payload})->

  switch type
    when ACTIONS.LOAD_DATA
      _.extend {}, state, 
        logs: payload.logs
        total: payload.total
        endcursor: payload.endcursor
    when ACTIONS.SELECTOR
      _.extend {}, state,
        selector: payload
    when ACTIONS.SEARCH
      _.extend {}, state,
        data: payload
    when ACTIONS.FILTER_LOG
      _.extend {}, state,
        page: payload
    else
      state