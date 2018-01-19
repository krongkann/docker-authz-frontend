import React,{Component}               from 'react'
import { connect }                     from 'react-redux'
import SigninContainer                 from '/app/containers/SigninContainer'
import LogContainer                    from '/app/containers/LogContainer'
import PermissionContainer             from '/app/containers/PermissionContainer'
import ImageContainer                  from '/app/containers/ImageContainer'
import { Input, Menu, Segment, Container, Icon } from 'semantic-ui-react'
import { actions as pageActions }     from '/app/ducks/page'
import { actions as logActions }      from '/app/ducks/log'
import { actions as imageActions }      from '/app/ducks/image'
import { actions as logoutActions }     from '/app/ducks/logout'
import { actions as loginActions }     from '/app/ducks/login'

import {
  BrowserRouter as Router,
  Route,
  Link
} from 'react-router-dom'

class  MainLayout extends Component
  constructor:(props)->
    super props 
    @state = {
      activeItem: 'permission'
    }
  componentWillMount: ()->
    @props.oncheck()
  componentWillReceiveProps: (nextprops)->
    if _.get nextprops, 'logouting.response'
      document.location = "/"
  color:(color)->
    if color
      'red'
    else
      'white'
  render:( ) ->
    me = @
    activeItem = (_.get me, 'state.activeItem')
    <Router>
      <div>
        <Menu  >
          <Menu.Item name='permission'  
              active={activeItem is 'permission'} 
              style={backgroundColor: me.color(activeItem is 'permission')} 
              as={Link} to='/main'  
              onClick={()->
                me.props.onClick()
                me.setState 
                  activeItem: 'permission' } />
          <Menu.Item name='historylog'   
            active={activeItem is 'historylog'} 
            style={backgroundColor: me.color(activeItem is 'historylog')} 
            as={Link} to='/historylog'  
            onClick={()->
                me.props.onClick()
                me.setState 
                  activeItem: 'historylog'}/>
          <Menu.Item name='image'  
            active={activeItem is 'image'} 
            style={backgroundColor: me.color(activeItem is 'image')} 
            as={Link} to='/image'    
            onClick={()->
                me.props.onClick()
                me.setState 
                  activeItem: 'image'} />
          <Menu.Menu position='right'>
            <Menu.Item>
              <Icon circular name='spy' />
              user : {me.props.username}
            </Menu.Item>
            <Menu.Item name='logout'  
              style={backgroundColor: me.color(activeItem is 'logout')} 
              active={activeItem is 'logout'}  as={Link} to='/logout' 
              onClick={()-> 
                # me.props.onClick()
                me.props.logout()
                me.setState 
                  activeItem: 'logout' } />
          </Menu.Menu>
        </Menu>
        <Route exact path="/main" component={PermissionContainer}/>
        <Route exact path="/historylog" component={LogContainer}/>
        <Route exact path="/image" component={ImageContainer}/>
      </div>
    </Router>


mapDispatchToProps = (dispatch) ->
  onClick:(key)->
    dispatch pageActions.doSelectPage(@name)
    # dispatch imageActions.getAllImage()
  oncheck: ->
    dispatch loginActions.checkLoing()
  logout:()->
    dispatch logoutActions.doLogout()
mapStateToProps = ({page, logout, login}) ->
  username: _.get login, 'success.username'
  activeItem: _.get page, 'activePage'
  logouting: logout.success
  





export default connect(mapStateToProps, mapDispatchToProps )(MainLayout)



