import React, { Component } from 'react'
import ClickList from './click_list'
import store from '/app/redux'

export default class UsernameSelector extends ClickList

  meUs = null
  listOnClick: () ->
    store.dispatch
      type: 'SELECT_USERNAME'
      username: meUs.data[meUs.list.selectedIndex]

  componentWillMount: ->
    meUs = @
    meUs.header = 'Username :'
    meUs.data = getUsername()
    meUs.items = meUs.keys = meUs.data
  
  store.subscribe () ->
    meUs.data = getUsername()
    meUs.items = meUs.keys = meUs.data
    meUs.forceUpdate()

  getUsername = () ->
    data = _.get store.getState(), 'usernames', []
    _.sortBy data