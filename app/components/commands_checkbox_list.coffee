import _ from 'lodash'
import React, { Component } from 'react'
import { connect }          from 'react-redux'
import { Checkbox, Button } from 'react-bootstrap'
import { confirmAlert } from 'react-confirm-alert'
import PermissionButtonsPanel from '/app/components/permission_buttons_panel'
import 'react-confirm-alert/src/react-confirm-alert.css'

class CommandsCheckboxList extends Component

  me = null
  username = null
  servername = null
  form = null
  listOnClick: (command, checked) ->
    # servername = _.get store.getState(), "selectedServername", []
    # username = _.get store.getState(), "selectedUsername", []
    # confirmAlert
    #   title: 'U sure?'
    #   message: command + '\'s permission are going to be changed, are you sure?'
    #   confirmLabel: 'Yes'
    #   cancelLabel: 'No'
    #   onConfirm: () ->
    #     await toggleAllow username, servername, command, checked
    #     getCommands(username, servername) store.dispatch
    #   onCancel: () ->
  


  componentWillMount: ->
    me = @
    if @props.data
      me.data = @props.data
    else
      me.data = []
  
  # store.subscribe () ->
  #   me.forceUpdate()
  
  
  render: ->
    
    <div className='containervv'>
      <PermissionButtonsPanel/>
      
      <form className='containervv'>
        {
          checkboxs = []
          _.each me.data, (allow, command) ->
            checkboxs.push <Checkbox
              key={ command }
              style={'fontSize': 13}
              checked={ me.data[command] }
              onChange={ (e) ->
                me.listOnClick command, e.target.checked
              }

              value={ command }
              className='item'
            >{ command }</Checkbox>
          _.sortBy checkboxs, ['key']
        }
      </form>
      
    </div>
mapDispatchToProps = (dispatch) ->
  onClick: (value) ->
    console.log 'I\'m like TT' + value
mapStateToProps = ({permission}) -> 
  data: permission.commands
export default connect(mapStateToProps, mapDispatchToProps)(CommandsCheckboxList)
  

  