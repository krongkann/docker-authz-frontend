
import '/app/assets/css/react-bootstrap-table.min'
import '/app/assets/css/font-awesome'
import '/app/assets/js/jquery-3.2.1.min'
import '/app/assets/css/bootstrap.min.css'
import '/app/semantic/dist/semantic.css'
import React, { Component }             from 'react'
import { render }                       from 'react-dom'
import { createStore, applyMiddleware } from 'redux'
import { Provider }                     from 'react-redux'
import promiseMiddleware                from 'redux-promise-middleware'
import { createLogger }                 from 'redux-logger'
import thunk                            from 'redux-thunk'
import reducer                          from '/app/ducks'
import { composeWithDevTools }          from 'redux-devtools-extension'
import SigninContainer                   from '/app/containers/SigninContainer'

import * as _ from 'lodash'
export default class AppSignin extends Component
  
  middleware = applyMiddleware(promiseMiddleware(), thunk, createLogger())
  store = createStore(reducer, {},composeWithDevTools(middleware))

  
  componentDidCatch: (error, info) ->
    alert error
   
  render: ->
    <Provider store={store}>
      <SigninContainer />
    </Provider>

