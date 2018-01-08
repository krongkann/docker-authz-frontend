import React, { Component } from 'react'
import ClickList from './click_list'

export default class ServernameSelector extends ClickList

  meSv = null
  listOnClick: () ->
    @props.onClick()

  componentWillMount: (props) ->
    meSv = @
    meSv.header = 'Servername :'
    meSv.items = meSv.keys = meSv.data = @props.data