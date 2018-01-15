import _ from 'lodash'
import React, { Component } from 'react'
import { connect }          from 'react-redux'
import { Checkbox, Button } from 'react-bootstrap'
import { confirmAlert } from 'react-confirm-alert'
import PermissionButtonsPanel from '/app/components/permission_buttons_panel'
import { actions } from '/app/ducks/permission'
import 'react-confirm-alert/src/react-confirm-alert.css'

class CommandsCheckboxList extends Component

  me = null
  username = null
  servername = null
  form = null
  componentWillMount: ->
    if @props.data
      @data = @props.data
    else
      @data = []
  
  render: ->
    me = @
    <div className='containervv'>
      <PermissionButtonsPanel />
      <form className='containervv'>
        {
          checkboxs = []
          _.each me.props.data, (allow, command) ->
            checkboxs.push <Checkbox
              key={ command }
              style={'fontSize': 13}
              checked={ me.data[command] }
              onChange={ (e) ->
                checked = e.target.checked
                if me.props.onClick
                  confirmAlert
                    title: 'U sure?'
                    message: command + '\'s permission are going to be changed, are you sure?'
                    confirmLabel: 'Yes'
                    cancelLabel: 'No'
                    onConfirm: () ->
                      me.props.onClick
                        checked: checked
                        command: command
                        username: me.props.selectedUsername
                        servername: me.props.selectedServername
                    onCancel: () ->
                  
              }
              value={ command }
              className='item'
            >{ command }</Checkbox>
          _.sortBy checkboxs, ['key']
        }
      </form>
      
    </div>

mapDispatchToProps = (dispatch) ->
  onClick: (params) ->
    actions.changePermission(params) dispatch
mapStateToProps = ({ permission }) ->
  return
    data: permission.commands
    selectedUsername: permission.selectedUsername
    selectedServername: permission.selectedServername
export default connect(mapStateToProps, mapDispatchToProps) CommandsCheckboxList
  

  