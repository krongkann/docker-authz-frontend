import React,{Component}               from 'react'
import { connect }                     from 'react-redux'
import SigninContainer                 from '/app/containers/SigninContainer'
import LogContainer                    from '/app/containers/LogContainer'
import PermissionContainer             from '/app/containers/PermissionContainer'
import ImageContainer                  from '/app/containers/ImageContainer'
import { Input, Menu, Segment, Container } from 'semantic-ui-react'
import { actions as pageActions }     from '/app/ducks/page'
import { actions as logActions }      from '/app/ducks/log'
import { actions as imageActions }      from '/app/ducks/image'
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
      colorItem: 'white'
    }

    
  render:( ) ->
    me = @
    activeItem = (_.get me, 'state.activeItem')


    <Router>
      <div>
        <Menu  >
          <Menu.Item name='permission'  active={activeItem is 'permission'}  as={Link} to='/permission'  
              onClick={()->
                me.props.onClick()
                me.setState 
                  activeItem: 'permission' } />
          <Menu.Item name='history log'   active={activeItem is 'history log'}  as={Link} to='/main'  
            onClick={()->
                me.props.onClick()
                me.setState 
                  activeItem: 'history log'}/>
          <Menu.Item name='image'  active={activeItem is 'image'}  as={Link} to='/image'    onClick={()->
                me.props.onClick
                me.setState 
                  activeItem: 'image'} />
          <Menu.Menu position='right'>
            <Menu.Item>
              <Input icon='search' placeholder='Search...' />
            </Menu.Item>
            <Menu.Item name='logout'  active={activeItem is 'logout'}  as={Link} to='/logout' 
              onClick={()-> 
                me.props.onClick()
                me.setState 
                  activeItem: 'logout' } />
          </Menu.Menu>
        </Menu>
        <Route exact path="/permission" component={PermissionContainer}/>
        <Route exact path="/main" component={LogContainer}/>
        <Route exact path="/image" component={ImageContainer}/>
        <Route exact path="/logout" component={SigninContainer}/>
      </div>
    </Router>




mapDispatchToProps = (dispatch) ->
  onClick:(key)->
    dispatch pageActions.doSelectPage(@name)
    dispatch logActions.getLog()
    dispatch logActions.getSelector()
    dispatch imageActions.getAllImage()
mapStateToProps = ({page, login}) -> 
  activeItem: _.get page, 'activePage'
  user: login





export default connect(mapStateToProps, mapDispatchToProps )(MainLayout)



