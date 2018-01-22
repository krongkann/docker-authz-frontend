import logo from "/app/assets/img/logo.png"
import React,{Component} from 'react'
import { render } from 'react-dom'
import { Button, Form, Grid, Header, Image, Message, Segment } from 'semantic-ui-react'
import '/app/assets/css/custom/search'
class Login extends Component
  constructor:(props)->
    super props 
    @state = {}
  render: ->
    me = @
    msg = _.get me, 'props.msg.response' 
    isSubmitButtonDisable = !(@state.username and @state.password)
    <div className='login-form'>
      <Grid
        textAlign='center'
        style={{ height: '100%' }}
        verticalAlign='middle'
      >
        <Grid.Column style={{ maxWidth: 450 }}>
          <Image src={logo} />

          <Header as='h2' style={color: '#0596d5'} textAlign='center'>
            {' '}Log-in to your account
          </Header>
          <Form size='large' onSubmit={(e) -> 
            e.preventDefault()
            me.props.onSubmit me.state   }>
            <Segment stacked>
              <Form.Input
                fluid
                icon='user'
                iconPosition='left'
                placeholder='Username'
                onChange={(e)-> me.setState username: e.target.value} 
              />
              <Form.Input
                fluid
                icon='lock'
                iconPosition='left'
                placeholder='Password'
                type='password'
                onChange={(e)-> me.setState password: e.target.value}
              />
              <Button color='blue' fluid size='large' disabled={isSubmitButtonDisable}  >Login</Button>
            </Segment>
          </Form>
            {
              if msg == false
                <Message style={color: 'red'}>
                  Login Fail  
                </Message>
              else
                <Message>
                  New to us? <a href='#'>Sign Up</a>
                </Message>
            }
        </Grid.Column>
      </Grid>
    </div>



 

export default Login