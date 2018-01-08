import React, { Component } from 'react'
# import { PERMISSION_ITEMS } from '/app/constants/shared_constants'

export default class ClickList extends Component

  list: null
  items: []
  data: []
  keys: []
  header: ''
  listOnClick: () ->

  listOnKeyDown: (keyCode) ->

  listOnKeyUp: (keyCode) ->
  
  render: ->
    me = @
    <div  className='containervv'>
      <h4>{ me.header }</h4>
      <select style={ fontSize: 15 } size={ 17 }
        onChange={ () ->
          me.listOnClick()
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
          for i in [0...Object.keys(me.data).length]
            <option 
              key={ me.keys[i] }
              value={ me.items[i] }
            >{ me.items[i] }
            </option>
        }
      </select>
    </div>