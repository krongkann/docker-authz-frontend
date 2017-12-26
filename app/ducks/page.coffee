import { defineAction } from 'redux-define';
axios = require 'axios'

DEFAULT_STATE = {}

export ACTIONS = defineAction('PAGE', ['PAGESELECT', 'SUCCESS']) 

export actions = 
  doSelectPage: (key)=>
    (dispatch) =>
      dispatch 
        type: ACTIONS.PAGESELECT
        payload: 
          activePage: key

       
     
      

export default (state=DEFAULT_STATE, {type, payload})->
  switch type
    when ACTIONS.PAGESELECT 
      _.extend {}, state,  
        active: payload
    else
      state
