import { defineAction } from 'redux-define'
DEFAULT_STATE = {}
console.log "__filename",__filename

export ACTIONS = defineAction('SYSTEM', ['SHOW_NOTIFY'], __filename) 


export default (state=DEFAULT_STATE, {type, payload})->
  switch type
    when ACTIONS.SHOW_NOTIFY 
      _.extend {}, state,  
        show_notify: payload
    else
      state
