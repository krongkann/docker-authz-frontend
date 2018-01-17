import React, { Component }               from 'react'
import { connect }                     from 'react-redux'
import ServernameSelector              from '/app/components/servername_selector'
import UsernameSelector                from '/app/components/username_selector'
import CommandsCheckboxList            from '/app/components/commands_checkbox_list'
import '/app/assets/css/custom/triple_selector_form.css'

export default class  PermissionContainer extends Component
  render: ->
    <div className='containerhh' style={'padding': '21px'}>
      <ServernameSelector/>
      <UsernameSelector/>
      <CommandsCheckboxList/>
    </div>

