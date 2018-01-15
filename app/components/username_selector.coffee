import React, { Component } from 'react'
import { connect }          from 'react-redux'
import ClickList            from './click_list'
import { TYPES }            from '/app/ducks/permission'
import { actions } from '/app/ducks/permission'

class UsernameSelector extends ClickList

  meUs = null
  listOnClick: (value) ->
    @props.onClick @props.selectedServername, value

  componentWillMount: (props) ->
    meUs = @
    meUs.header = 'Username :'
    if @props.data
      meUs.items = meUs.keys = meUs.data = @props.data
    else
      meUs.items = meUs.keys = meUs.data = []

mapDispatchToProps = (dispatch) ->
  onClick: (selectedServername, value) ->
    if _.isString selectedServername
      actions.getCommands(
        servername: selectedServername
        username: value) dispatch
    else
      dispatch
        type: TYPES.SELECT_USERNAME
        payload: value
mapStateToProps = ({ permission }) ->
  data: permission.usernames
  selectedServername: permission.selectedServername
export default connect(mapStateToProps, mapDispatchToProps)(UsernameSelector)