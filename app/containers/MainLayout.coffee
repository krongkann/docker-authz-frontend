import React,{Component}               from 'react'
import { connect }                     from 'react-redux'
import { actions as loginActions }     from '/app/ducks/login'
import SigninContainer                 from '/app/containers/SigninContainer'
import RouterComponent                 from '/app/components/RouterComponent'
import LogContainer                    from '/app/containers/LogContainer'
import PermissionContainer             from '/app/containers/PermissionContainer'
import ImageContainer                  from '/app/containers/ImageContainer'

import { actions as pageActions }     from '/app/ducks/page'
import { 
  Navbar, 
  Nav, 
  NavItem, 
  NavDropdown, 
  MenuItem
} from 'react-bootstrap'
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
    me  = @
    <Router>
      <div>
        <Navbar inverse collapseOnSelect>
          <Navbar.Header>
            <Navbar.Brand>
              <a href="#">Docker-Authz</a>
            </Navbar.Brand>
            <Navbar.Toggle />
          </Navbar.Header>
            <div>
              <Navbar.Collapse>
                <Nav  onSelect={(key)-> me.props.onSelect(key) }>
                  <NavItem eventKey={1} ><Link className='nav' activeStyle='nav-active' to="/permission">PERMISSION</Link> </NavItem>
                  <NavItem eventKey={1} ><Link className='nav' to="/log">LOG</Link> </NavItem>
                  <NavItem eventKey={1} ><Link className='nav' to="/image">IMAGE</Link> </NavItem>
                  <NavDropdown eventKey={3} title="Dropdown" id="basic-nav-dropdown">
                    <MenuItem eventKey={3.1}>Action</MenuItem>
                    <MenuItem eventKey={3.2}>Another action</MenuItem>
                    <MenuItem eventKey={3.3}>Something else here</MenuItem>
                    <MenuItem divider />
                    <MenuItem eventKey={3.3}>Separated link</MenuItem>
                  </NavDropdown>
                </Nav>
                <Nav pullRight>
                  <NavItem eventKey={1} href="#">username</NavItem>
                  <NavItem eventKey={2} href="#">logout</NavItem>
                </Nav>
              </Navbar.Collapse>
            </div>
          </Navbar>
        <Route exact path="/permission" component={PermissionContainer}/>
        <Route exact path="/log" component={LogContainer}/>
        <Route exact path="/image" component={ImageContainer}/>
      </div>
    </Router>





mapDispatchToProps = (dispatch) ->
  onSelect:(key)->
    dispatch pageActions.doSelectPage(key)

mapStateToProps = ({page}) -> 
  pageSelect: _.get page, 'active'





export default connect(mapStateToProps, mapDispatchToProps )(MainLayout)



