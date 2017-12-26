import logo from "/app/assets/img/logo.png"
import React,{Component} from 'react'
import { render } from 'react-dom'
import {
  Form,
  FormGroup,
  Col,
  FormControl,
  Button,
  ControlLabel,
  Checkbox,
  Grid,
  Row,
  Image

  } from 'react-bootstrap'
import '/app/assets/css/custom/search'
class Login extends Component
  constructor:(props)->
    super props 
    @state = {}
  render: ->
    me = @

    isSubmitButtonDisable = !(@state.username and @state.password)

 
    <div className='search'> 
      <Grid>
        <Row>
          <Col xs={6} md={4}>
            <Image src={logo}   responsive  />
          </Col>
        </Row>
        <Col componentClass={ControlLabel}   className='search'  xs={6} md={4}>ABOSS Docker Authorizations</Col>
      </Grid>

      <Form horizontal onSubmit={(e) -> 
            e.preventDefault()
            me.props.onSubmit me.state   } >
        <FormGroup controlId="formHorizontalUsername" >
          <Col componentClass={ControlLabel} sm={2}>
            Username
          </Col>
          <Col sm={6}>
            <FormControl  type="text" placeholder="Username"   onChange={(e)-> me.setState username: e.target.value} />
          </Col>
        </FormGroup>

        <FormGroup controlId="formHorizontalPassword">
          <Col componentClass={ControlLabel} sm={2}>
            Password
          </Col>
          <Col sm={6}>
            <FormControl type="password" placeholder="Password"  onChange={(e)-> me.setState password: e.target.value} />
          </Col>
        </FormGroup>
        <Col componentClass={ControlLabel}style={color: 'red'} sm={5}>
          {

            if (_.get me, 'props.msg.response')  == false
              "Login fail"
          }
          
        </Col>

        <FormGroup>
          <Col smOffset={2} sm={10}>
            <Checkbox  id="rememberbox" onChange={(e)-> 
                  me.setState boxremember: rememberbox.checked
                  console.log "ckec;" }> Remember me</Checkbox>
          </Col>
        </FormGroup>

        <FormGroup>
          <Col smOffset={2} sm={10}>
            <Button type="submit" disabled={isSubmitButtonDisable} >
              Sign in
            </Button>
          </Col>
        </FormGroup>
      </Form>
    </div>



 

export default Login