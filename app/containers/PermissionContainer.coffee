import React, { Component }               from 'react'
import { connect }                     from 'react-redux'
import ServernameSelector              from '/app/components/servername_selector'
import UsernameSelector                from '/app/components/username_selector'
import CommandsCheckboxList            from '/app/components/commands_checkbox_list'

export default class  PermissionContainer extends Component
  render: ->
    <div style={
      display: 'flex'
      flexDirection: 'row'
      alignItems: 'flex-start'
      alignContent: 'stretch'
      justifyContent: 'space-between'
      flex: 1
    }>
      <ServernameSelector/>
      <UsernameSelector/>
      <CommandsCheckboxList/>
    </div>

