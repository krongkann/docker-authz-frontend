import _ from 'lodash'
import React, { Component } from 'react'
import store from '/app/redux'
import { getCommands, refreshUserCommands, toggleAllow, setAllowAll } from '/app/actions/commands'
import { Checkbox, Button } from 'react-bootstrap'
import { confirmAlert } from 'react-confirm-alert'
import 'react-confirm-alert/src/react-confirm-alert.css'

export default class CommandsCheckboxList extends Component

  me = null
  username = null
  servername = null
  form = null
  buttonStyle =
    color: '#FFFFFF'
    fontWeight: 'bold'
  listOnClick: (command, checked) ->
    servername = _.get store.getState(), "selectedServername", []
    username = _.get store.getState(), "selectedUsername", []
    confirmAlert
      title: 'U sure?'
      message: command + '\'s permission are going to be changed, are you sure?'
      confirmLabel: 'Yes'
      cancelLabel: 'No'
      onConfirm: () ->
        await toggleAllow username, servername, command, checked
        getCommands(username, servername) store.dispatch
      onCancel: () ->
  
  checkAll = () ->
    servername = _.get store.getState(), "selectedServername", []
    username = _.get store.getState(), "selectedUsername", []
    data = getCommandsData()
    filteredData = _.pickBy data, (e) -> not e
    if _.isEmpty filteredData
      outputString = 'No commands will become permitted'
      confirmAlert
        title: 'This will change nothing'
        message: outputString
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
          await setAllowAll username, servername, true
          getCommands(username, servername) store.dispatch
      
  uncheckAll = () ->
    servername = _.get store.getState(), "selectedServername", []
    username = _.get store.getState(), "selectedUsername", []
    data = getCommandsData()
    filteredData = _.pickBy data, (e) -> e
    if _.isEmpty filteredData
      outputString = 'No commands will become unpermitted'
      confirmAlert
        title: 'This will change nothing'
        message: outputString
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
          await setAllowAll username, servername, false
          getCommands(username, servername) store.dispatch

  componentWillMount: ->
    me = @
  
  store.subscribe () ->
    me.forceUpdate()

  getCommandsData = () ->
    _.get store.getState(), "commands", []
  
  commandRefresh = () ->
    refreshUserCommands(store.getState().selectedUsername, store.getState().selectedServername) store.dispatch
  
  render: ->
    me.data = getCommandsData()
    <div className='containervv'>
      <h4>Commands: 
        <div className='contanerhh'>
          <Button onClick={ commandRefresh } style={_.assign {}, buttonStyle, {background: '#444'}}>Refresh</Button>
          <Button onClick={ checkAll } style={_.assign {}, buttonStyle, {background: '#0A0'}}>Allow All</Button>
          <Button onClick={ uncheckAll } style={_.assign {}, buttonStyle, {background: '#A00'}}>Not Allow All</Button>
        </div>
        
      </h4>
      
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
  