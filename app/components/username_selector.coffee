import React, { Component } from 'react'
import { connect }          from 'react-redux'
import ClickList            from './click_list'
import { TYPES }            from '/app/ducks/permission'

class UsernameSelector extends ClickList

  meUs = null
  listOnClick: (value) ->
    @props.onClick value

  componentWillMount: (props) ->
    meUs = @
    meUs.header = 'Username :'
    if @props.data
      meUs.items = meUs.keys = meUs.data = @props.data
    else
      meUs.items = meUs.keys = meUs.data = []

mapDispatchToProps = (dispatch) ->
  onClick: (value) ->
    console.log 'trap\n\n\n\n\n\n' + value
    dispatch
      type: TYPES.SELECT_SERVERNAME
      payload: value
mapStateToProps = ({permission}) -> 
  data: permission.usernames
export default connect(mapStateToProps, mapDispatchToProps)(UsernameSelector)