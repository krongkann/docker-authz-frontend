import _                               from 'lodash'
import React,{Component}               from 'react'
import Login                           from '/app/components/forms/Login'
import { connect }                     from 'react-redux'
import { ProgressBar }                 from 'react-bootstrap'
import { actions as loginActions }     from '/app/ducks/login'
import {Router, Route, IndexRoute, hashHistory, browserHistory} from "react-router"
axios = require 'axios'


class  SigninContainer extends Component
  componentWillReceiveProps: (nextprops)->
    if _.get nextprops, 'loginSuccess.response'
      document.location = "/main"
  render: ->
    
    <Login  onSubmit={@props.onSubmit} msg={@props.loginSuccess} />
    

mapDispatchToProps = (dispatch) ->
  onSubmit:(e)->
    dispatch(loginActions.doLogin(e))

mapStateToProps = ({login}) -> 
  loginSuccess: _.get login, 'success'



export default connect(mapStateToProps,mapDispatchToProps)(SigninContainer)
