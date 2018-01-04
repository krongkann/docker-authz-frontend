import { defineAction } from 'redux-define';
axios = require 'axios'

DEFAULT_STATE = {}

export TYPES = defineAction('LOGIN', ['LOGINGIN', 'SUCCESS','REMEMBER']) 

export actions = 
  doLogin: ({username, password})=>
    (dispatch) =>

      axios.defaults.baseURL =  '/login'
      try 
        dispatch 
          type: TYPES.LOGINGIN
          payload: true

        response = await axios
          method: 'post'
          data: {username, password}

        dispatch 
          type: TYPES.LOGINGIN
          payload: false
        
        dispatch
          type: TYPES.SUCCESS
          payload: 
            response: (if _.get(response, 'data.error') then false else true)
            data: {username, password}
      catch e
        dispatch
          type: TYPES.SUCCESS
          payload: false


export default (state=DEFAULT_STATE, {type, payload})->
  switch type
    when TYPES.LOGINGIN 
      _.extend {}, state,  
        logging_in: payload

    when TYPES.SUCCESS
      _.extend {}, state,
        success: payload
    when TYPES.REMEMBER
      
    else
      state
