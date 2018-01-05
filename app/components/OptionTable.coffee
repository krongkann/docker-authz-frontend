

import React,{Component}   from 'react'
import moment              from 'moment'
import { Dropdown, Label, Select, Grid, Button, Menu, Input, Header, Checkbox } from 'semantic-ui-react'
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
      <Grid columns={3}>
        <Grid.Column >
          <Header size='small'>Server Name</Header>
          <Header size='small'>User Name</Header>
          <Header size='small'>Command</Header>
          <Header size='small'>Date</Header>
          <Header size='small'>To</Header>
        </Grid.Column>
        <Grid.Column>

        {
          server = []
          _.each (_.get select, 'server'), (v,k) ->
            server.push { text: v, key: k , value: v}
          <Dropdown upward placeholder='Server Name' fluid multiple search selection
            onChange={(e,{value})->  
              me.setState servername: value}
              options={server } />
        }
        {
          user = []
          _.each (_.get select, 'user'), (v,k) ->
            user.push { text: v , key: k ,value: v}
          <Dropdown placeholder='User Name'  fluid multiple search selection
            onChange={(e,{value})->  
              me.setState username: value}
              options={user} />
        }
   
    
        {
          command = []
          _.each (_.get select, 'command'), (v,k) ->
            command.push { text: v ,key: k,value: v}
          <Dropdown placeholder='Command' fluid multiple search selection
            onChange={(e,{value})->  
              me.setState command: value}
              options={command } />

        }
        {
          <DatePicker placeholderText="Date"
              selected={@state.startDate}
              className='date-picker' 
              dateFormat="DD/MM/YYYY"
              onChange={(date)->  me.setState startDate: date} />
        }
        {
          <DatePicker placeholderText="To" className='date-picker' 
              selected={@state.endDate}
              dateFormat="DD/MM/YYYY"
              onChange={(date)->  me.setState endDate: date} 
             />
        }
        </Grid.Column>
        
        <Grid.Row>
          <Button color='teal'>Export CSV</Button>
          <Button color='blue'>Export PDF</Button>
          <Button positive onClick={()-> me.props.onClick me.state } >Search !</Button>

        </Grid.Row>
         
      </Grid>
      
      {' '}
      
      

    </div>    
export default OptionTable

