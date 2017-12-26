import React,{Component}               from 'react'
import { connect }                     from 'react-redux'
import SigninContainer                   from '/app/containers/SigninContainer'
import {
  BrowserRouter as Router,
  Route,
  Link
} from 'react-router-dom'



class  RouterComponent extends Component

  render: ->
    me = @ 
    console.log "mee", me
    <Router>
      <div>
        <ul>
          <li><Link to="/">Home</Link></li>
          <li><Link to="/about">About</Link></li>
          <li><Link to="/topics">Topics</Link></li>
        </ul>
        <hr/>
        <Route exact path="/" component={SigninContainer}/>
      </div>
    </Router>
mapDispatchToProps = (dispatch) ->
  onSubmit:(e)->
    dispatch(loginActions.doLogin(e))

mapStateToProps = ({login}) -> 
  loginSuccess: _.get login, 'success'

export default connect()(RouterComponent)