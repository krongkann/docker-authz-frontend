import { defineAction } from 'redux-define'
axios = require 'axios'

DEFAULT_STATE = {}

export TYPES = defineAction('LOGOUT', ['LOGOUTING', 'SUCCESS', 'FAIL']) 

export actions = 
  doLogout: ()=>
    (dispatch) =>

      axios.defaults.baseURL =  '/logout'
      try 
        dispatch 
          type: TYPES.LOGOUTING
          payload: true

        response = await axios
          method: 'delete'
        dispatch
          type: TYPES.SUCCESS
          payload: 
            response: (if _.get(response, 'data.error') then false else true)
      catch e
        dispatch
          type: TYPES.FAIL
          payload: 
            response: false
            message: e




export default (state=DEFAULT_STATE, {type, payload})->
  switch type
    when TYPES.LOGINGIN 
      _.extend {}, state,  
        logging_in: payload

    when TYPES.SUCCESS
      _.extend {}, state,
        success: payload
    when TYPES.FAIL
      _.extend {}, state,
        success: payload
      
    else
      state
