import { defineAction }           from 'redux-define'
import { GraphQLClient, request }  from 'graphql-request'
client = new GraphQLClient '/graphql' 
axios = require 'axios'

DEFAULT_STATE = {numberpage: 1}

export ACTIONS = defineAction('LOG', ['LOAD_DATA', 
                                      'SUCCESS', 
                                      'FILTER_LOG', 
                                      'SELECTOR', 
                                      'SEARCH', 
                                      'FILTER_LOG_BACK',
                                      'PAGE_NUMBER']) 
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
  pageNumber:(me) -> (dispatch) ->
    dispatch 
      type: ACTIONS.PAGE_NUMBER
      payload:
        page: me

  getfilterLogNext:(cursor, {startDate, endDate, servername, username, command})->
    query = QUERYLOG
    (dispatch) =>
      try
        data = await client.request query,
        {
          filter:
            servername: servername
            username: username
            command: command
            from: startDate
            to: endDate
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
  getfilterLogBack:(cursor, {startDate, endDate, servername, username, command})->
    query = QUERYLOG
    (dispatch) =>
      try
        data = await client.request query,
        {
          filter:
            servername: servername
            username: username
            command: command
            from: startDate
            to: endDate
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
            page: 1

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

              # admin: true
          }
        dispatch 
          type: ACTIONS.LOAD_DATA
          payload:
            total: _.get search, 'logs.totalCount'
            logs: _.get search, 'logs.edges'
            endcursor: _.get search, 'logs.pageInfo'
        dispatch
          type: ACTIONS.SEARCH
          payload:
            filter:
              servername: servername
              username: username
              command: command
              from: startDate
              to: endDate

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
        page: payload.page
    when ACTIONS.SEARCH
      _.extend {}, state,
        data: payload.filter
    when ACTIONS.FILTER_LOG
      _.extend {}, state,
        page: payload
    when ACTIONS.PAGE_NUMBER
      _.extend {}, state,
        if payload.page == 0
          numberpage: 1
        else
          numberpage: (state.numberpage + payload.page) 
    else
      state