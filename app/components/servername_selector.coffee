import React, { Component } from 'react'
import { connect }          from 'react-redux'
import ClickList from './click_list'
import { TYPES }            from '/app/ducks/permission'
import { actions } from '/app/ducks/permission'

class ServernameSelector extends ClickList

  meSv = null
  listOnClick: (value) ->
    @props.onClick @props.selectedUsername, value

  componentWillMount: (props) ->
    meSv = @
    meSv.header = 'Servername :'
    meSv.items = meSv.keys = meSv.data = @props.data

mapDispatchToProps = (dispatch) ->
  onClick: (selectedUsername, value) ->
    if _.isString selectedUsername
      actions.getCommands(
        servername: value
        username: selectedUsername) dispatch
    else
      dispatch
        type: TYPES.SELECT_SERVERNAME
        payload: value
mapStateToProps = ({ permission }) ->
  data: permission.servernames
  selectedUsername: permission.selectedUsername

export default connect(mapStateToProps, mapDispatchToProps)(ServernameSelector)