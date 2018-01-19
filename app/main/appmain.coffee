import '/app/assets/css/react-bootstrap-table.min'
import '/app/assets/css/font-awesome.min'
import '/app/assets/js/jquery-3.2.1.min'
import '/app/assets/css/bootstrap.min.css'
import '/app/semantic/dist/semantic.css'
import { connect }                     from 'react-redux'
import React, { Component }             from 'react'
import { render }                       from 'react-dom'
import MainLayout                   from '/app/containers/MainLayout'
import { actions as loginActions }     from '/app/ducks/login'

import * as _ from 'lodash'


class App extends Component


 
  componentDidCatch: (error, info) ->
    alert error
   
  render: ->
    me = @
    <MainLayout  />


mapDispatchToProps= (dispatch) ->


mapStateToProps = ({login}) ->
  

export default connect()(App)