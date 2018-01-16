import React, { Component } from 'react'
# import { PERMISSION_ITEMS } from '/app/constants/shared_constants'

export default class ClickList extends Component

  list: null
  items: []
  data: []
  keys: []
  header: ''
  listOnClick: (value) ->

  listOnKeyDown: (keyCode) ->

  listOnKeyUp: (keyCode) ->
  
  render: ->
    me = @
    <div className='containervv'>
      <h4>{ me.header }</h4>
      <select style={ fontSize: 15 } size={ Math.floor((window.innerHeight - 100) / 20) }
        onChange={ (event) ->
          me.listOnClick event.target.value
        }
        onKeyDown={ (event) ->
          me.listOnKeyDown event.keyCode
        }
        onKeyUp={ (event) ->
          me.listOnKeyUp event.keyCode
        }
        className='item'
        ref={ (instance) =>
          me.list = instance
        }>
        {
          if me.props.data
            for i in [0...Object.keys(me.props.data).length]
              <option
                key={ me.props.data[i] }
                value={ me.props.data[i] }
              >{ me.props.data[i] }
              </option>
        }
      </select>
    </div>