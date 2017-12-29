import { defineAction }           from 'redux-define'
import { GraphQLClient, request }  from 'graphql-request'
client = new GraphQLClient '/graphql' 
axios = require 'axios'

DEFAULT_STATE = {}

export ACTIONS = defineAction('LOG', ['LOAD_DATA', 'SUCCESS', 'FILTER_LOG', 'SELECTOR']) 

export actions = 
  getLog: (servername)=>
    query = """
query($after: String, $filter: LogsFilter, $first: Int){
  logs(first: $first
    after: $after
    filter: $filter
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
      }
      cursor
    }
    pageInfo {
      endCursor
    }
  }
}
"""
    (dispatch) =>
      try
        data = await client.request query
        dispatch 
          type: ACTIONS.LOAD_DATA
          payload: 
            logs: _.get data, 'logs.edges'
            total: _.get data, 'logs.totalCount'
        dispatch 
          type: ACTIONS.SUCCESS
          payload: true


      catch e
  getfilterLog:(e)->
    query = """
query($after: String, $filter: LogsFilter, $first: Int){
  logs(first: $first
    after: $after
    filter: $filter
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
      }
      cursor
    }
    pageInfo {
      endCursor
    }
  }
}
"""
    (dispatch) =>
      try
        dispatch 
          type: ACTIONS.FILTER_LOG
        data = await client.request query,
        {
          after: e.cursor
        }

        dispatch 
          type: ACTIONS.LOAD_DATA
          payload: 
            logs: _.get data, 'logs.edges'



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

export default (state=DEFAULT_STATE, {type, payload})->
  switch type
    when ACTIONS.LOAD_DATA
      _.extend {}, state, 
        logs: payload.logs 
    when ACTIONS.SELECTOR
      _.extend {}, state,
        selector: payload

    else
      state