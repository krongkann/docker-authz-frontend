import React,{Component}               from 'react'
import { connect }                     from 'react-redux'
import SigninContainer                 from '/app/containers/SigninContainer'
import LogContainer                    from '/app/containers/LogContainer'
import PermissionContainer             from '/app/containers/PermissionContainer'
import ImageContainer                  from '/app/containers/ImageContainer'
import { Input, Menu, Segment, Container } from 'semantic-ui-react'

import { actions as pageActions }     from '/app/ducks/page'
import {
  BrowserRouter as Router,
  Route,
  Link
} from 'react-router-dom'





class  MainLayout extends Component
  constructor:(props)->
    super props 
    @state = {}
    
  render: ->
    me = @
    <Router>

      <div>
        <Menu inverted >
          <Menu.Item name='permission' as={Link} to='/permission'  onClick={me.props.onClick} />
          <Menu.Item name='log' as={Link} to='/log'  onClick={me.props.onClick}/>
          <Menu.Item name='image' as={Link} to='/image' onClick={me.props.onClick} />
          <Menu.Menu position='right'>
            <Menu.Item>
              <Input icon='search' placeholder='Search...' />
            </Menu.Item>
            <Menu.Item name='logout' as={Link} to='/logout' onClick={me.props.onClick} />
          </Menu.Menu>
        </Menu>
        <Route exact path="/permission" component={PermissionContainer}/>
        <Route exact path="/log" component={LogContainer}/>
        <Route exact path="/image" component={ImageContainer}/>
        <Route exact path="/logout" component={SigninContainer}/>
      </div>
    </Router>




mapDispatchToProps = (dispatch) ->
  onClick:(key)->
    dispatch pageActions.doSelectPage(@name)

mapStateToProps = ({page}) -> 
  pageSelect: _.get page, 'active'





export default connect(mapStateToProps, mapDispatchToProps )(MainLayout)



