import React from 'react'
import ReactDOM from 'react-dom'
import { AppContainer } from 'react-hot-loader'
import { createStore, applyMiddleware } from 'redux'
import thunk                            from 'redux-thunk'
import { Provider }                     from 'react-redux'
import reducer                          from '/app/ducks'
import promiseMiddleware                from 'redux-promise-middleware'
import { createLogger }                 from 'redux-logger'
import { composeWithDevTools }          from 'redux-devtools-extension'
import AppSignin from '/app/signin/appsignin'

viewport = null


middleware = applyMiddleware(promiseMiddleware(), thunk, createLogger())
store = createStore(reducer, {},composeWithDevTools(middleware))

render = (Component)=>
  ReactDOM.render(
    <Provider store={store}>    
      <AppContainer>
        <AppSignin />
      </AppContainer>
    </Provider>
  ,
    document.getElementById('render-app')
  )

render()

if module.hot
  module.hot.accept '/app/signin/appsignin', ->
    render require('/app/signin/appsignin')
