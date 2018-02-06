import React, { Component } from 'react'
import { connect } from 'react-redux'
import { actions } from '/app/ducks/permission'
import { Button } from 'react-bootstrap'
import { confirmAlert } from 'react-confirm-alert'
import 'react-confirm-alert/src/react-confirm-alert.css'
import { actions as loginActions }      from '/app/ducks/login'

class PermissionButtonsPanel extends Component
  buttonStyle =
    color: '#FFFFFF'
    fontWeight: 'bold'
    

  render: ->
    me = @
    <h4>Commands: 
      <div className='contanerhh'>
        <Button onClick={ () -> 
          if me.props.onRefreshClick
            me.props.onRefreshClick me.props.selectedUsername, me.props.selectedServername
          } style={_.assign {}, buttonStyle, {background: '#444'}}>Refresh</Button>
        <Button onClick={ () ->
          if me.props.data
            filteredData = _.pickBy me.props.data, (e) -> not e
          if _.isEmpty filteredData
            confirmAlert
              title: 'This will change nothing'
              message: 'No commands will become permitted'
              cancelLabel: 'No'
          else
            outputString = 'These command(s) will become permitted : '
            _.each filteredData, (value, key) ->
              outputString += key + ' '
            confirmAlert
              title: 'U sure?'
              message: outputString
              confirmLabel: 'Yes'
              cancelLabel: 'No'
              onConfirm: () ->
                if me.props.onAllowAllClick
                  me.props.onAllowAllClick me.props.selectedUsername, me.props.selectedServername, me.props.userlogin
          } style={_.assign {}, buttonStyle, { background: '#0A0' }}>Allow All</Button>
        <Button onClick={ () ->
          if me.props.data
            filteredData = _.pickBy me.props.data, (e) -> e
          else
            filteredData = []
          if _.isEmpty filteredData
            confirmAlert
              title: 'This will change nothing'
              message: 'No commands will become unpermitted'
              cancelLabel: 'No'
          else
            outputString = 'These command(s) will become unpermitted : '
            _.each filteredData, (value, key) ->
              outputString += key + ' '
            confirmAlert
              title: 'U sure?'
              message: outputString
              confirmLabel: 'Yes'
              cancelLabel: 'No'
              onConfirm: () ->
                if me.props.onDenyAllClick
                  me.props.onDenyAllClick me.props.selectedUsername, me.props.selectedServername, me.props.userlogin
          } style={ _.assign {}, buttonStyle, { background: '#A00' } }>Deny All</Button>
      </div>
    </h4>
mapDispatchToProps = (dispatch) ->
  onRefreshClick: (selectedUsername, selectedServername) ->
    actions.fetch(
      servername: selectedServername
      username: selectedUsername
    ) dispatch
  onAllowAllClick: (selectedUsername, selectedServername, userlogin) ->
    actions.allowAll(
      servername: selectedServername
      username: selectedUsername
      userlogin: userlogin

    ) dispatch
  onDenyAllClick: (selectedUsername, selectedServername, userlogin) ->
    actions.denyAll(
      servername: selectedServername
      username: selectedUsername
      userlogin: userlogin
      
    ) dispatch
mapStateToProps = ({permission,login}) -> 
  return
    data: permission.commands
    userlogin: _.get login, 'success.username'
    selectedUsername: permission.selectedUsername
    selectedServername: permission.selectedServername
export default connect(mapStateToProps, mapDispatchToProps) PermissionButtonsPanel