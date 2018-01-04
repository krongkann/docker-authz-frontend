

import React,{Component}   from 'react'
import moment              from 'moment'
import { Dropdown, Label, Select, Grid, Button, Menu, Input } from 'semantic-ui-react'
import MenuOption from '/app/components/MenuOption'
import DatePicker from 'react-datepicker'
import 'react-datepicker/dist/react-datepicker.css'


class  OptionTable extends Component
  constructor: (props) ->
    super(props)
    @state = {
      btnOther: false
    }


  render:->
    me = @

    select = _.get me, 'props.select'
    stateOptions = [ { key: 'AL', value: 'AL', text: 'Alabama' }]
    <div className='option-table'> 
      <Grid columns='equal'>
        <Grid.Row>
          <Grid.Column>
          {
            server = []
            _.each (_.get select, 'server'), (v,k) ->
              server.push { text: v, key: k , value: v}
            <Dropdown placeholder='Server Name' fluid multiple search selection
              onChange={(e,{value})->  
                me.setState servername: value}
                options={server } />
          }
          </Grid.Column>
          <Grid.Column>
          {
            user = []
            _.each (_.get select, 'user'), (v,k) ->
              user.push { text: v , key: k ,value: v}
            <Dropdown placeholder='User Name'  fluid multiple search selection
              onChange={(e,{value})->  
                me.setState username: value}
                options={user} />
          }
     
          </Grid.Column>
          <Grid.Column>
           {
            command = []
            _.each (_.get select, 'command'), (v,k) ->
              command.push { text: v ,key: k,value: v}
            <Dropdown placeholder='Command' fluid multiple search selection
              onChange={(e,{value})->  
                me.setState command: value}
                options={command } />
          }
          </Grid.Column>
        </Grid.Row>
        <Grid.Row>
          <Grid.Column>

            <DatePicker placeholderText="Date"
              selected={@state.startDate}
              className='date-picker' 
              dateFormat="DD/MM/YYYY"
              onChange={(date)->  me.setState startDate: date} />
          </Grid.Column>
          <Grid.Column>
            <DatePicker placeholderText="To" className='date-picker' 
              selected={@state.endDate}
              dateFormat="DD/MM/YYYY"
              onChange={(date)->  me.setState endDate: date} 
             />
          </Grid.Column>
          <Grid.Column>
            <Button.Group>
              <Button positive onClick={()-> me.props.onClick me.state } >Search !</Button>
              <Button.Or />
              <Button onClick={()-> me.setState btnOther: true }>
                <Dropdown item text='Other'>
                  <Dropdown.Menu>
                    <Menu.Item name='inbox' >
                      <Label color='teal'>1</Label>
                      Inbox
                    </Menu.Item>
                    <Menu.Item name='spam' >
                      <Label>51</Label>
                      Spam
                    </Menu.Item>

                    <Menu.Item name='updates'  >
                      <Label>1</Label>
                      Updates
                    </Menu.Item>
                    <Menu.Item>
                      <Input icon='search'  />
                    </Menu.Item>
                  </Dropdown.Menu>
                </Dropdown>
              </Button>


                
            </Button.Group>
       
    

          </Grid.Column>
        </Grid.Row>
         
      </Grid>
      
      {' '}
      
      

    </div>    
export default OptionTable

