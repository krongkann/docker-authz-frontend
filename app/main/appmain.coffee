import '/app/assets/css/react-bootstrap-table.min'
import '/app/assets/css/font-awesome.min'
import '/app/assets/js/jquery-3.2.1.min'
import '/app/assets/css/bootstrap.min.css'
import React, { Component }             from 'react'
import { render }                       from 'react-dom'
import MainLayout                   from '/app/containers/MainLayout'

import * as _ from 'lodash'


export default class App extends Component
 
  
  componentDidCatch: (error, info) ->
    alert error
   
  render: ->
    <MainLayout />


