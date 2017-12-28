import { defineAction }           from 'redux-define'
import { GraphQLClient, request }  from 'graphql-request'
client = new GraphQLClient '/graphql' 
axios = require 'axios'

DEFAULT_STATE = {}

export ACTIONS = defineAction('LOG', ['LOAD_DATA', 'SUCCESS']) 

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
        dispatch 
          type: ACTIONS.SUCCESS
          payload: true


      catch e
        
export default (state=DEFAULT_STATE, {type, payload})->
  switch type
    when ACTIONS.LOAD_DATA
      _.extend {}, state, 
        logs: payload.logs 


    else
      state