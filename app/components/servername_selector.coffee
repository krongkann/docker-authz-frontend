import React, { Component } from 'react'
import { connect }          from 'react-redux'
import ClickList from './click_list'

class ServernameSelector extends ClickList

  meSv = null
  listOnClick: (value) ->
    @props.onClick value

  componentWillMount: (props) ->
    meSv = @
    meSv.header = 'Servername :'
    meSv.items = meSv.keys = meSv.data = @props.data

mapDispatchToProps = (dispatch) ->
  onClick: (value) ->
    dispatch
      type: TYPES.SELECT_SERVERNAME
      payload: value
mapStateToProps = ({ permission }) ->
  data: permission.servernames

export default connect(mapStateToProps, mapDispatchToProps)(ServernameSelector)