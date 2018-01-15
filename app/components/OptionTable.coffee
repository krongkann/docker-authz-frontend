

import React,{Component}   from 'react'
import moment              from 'moment'
import { Dropdown, Label, Select, Grid, Button, Menu, Input, Header, Checkbox } from 'semantic-ui-react'
import MenuOption from '/app/components/MenuOption'
import DatePicker from 'react-datepicker'
import 'react-datepicker/dist/react-datepicker.css'


class  OptionTable extends Component
  me = null
  constructor: (props) ->
    super(props)
    @state = {
      btnOther: false
      value:[]
    }
  componentWillMount: ->
    me = @

    

  render:->
    me = @
    select = _.get me, 'props.select'
    stateOptions = [ { key: 'AL', value: 'AL', text: 'Alabama' }]
    <div className='option-table'> 
      <Grid columns={3}>
        <Grid.Column >
          <Header size='tiny'>Server Name</Header>
          <Header size='tiny'>User Name</Header>
          <Header size='tiny'>Command</Header>
          <Header size='tiny'>Date</Header>
          <Header size='tiny'>To</Header>
        </Grid.Column>
        <Grid.Column>

        {
          server = []
          _.each (_.get select, 'server'), (v,k) ->
            server.push { text: v, key: k , value: v}
          <Dropdown upward placeholder='Server Name' item={false} id ='dropdown' fluid multiple search selection
            onAddItem={()-> console.log "dd"}
            value={me.state.value}
            onChange={(e,{value})->
              me.setState value: value
              me.setState servername: value}
              options={server } />
        }
        {
          user = []
          _.each (_.get select, 'user'), (v,k) ->
            user.push { text: v , key: k ,value: v}
          <Dropdown placeholder='User Name'  fluid multiple search selection
            value={me.state.value}
            onChange={(e,{value})->  
              me.setState username: value}
              options={user} />
        }
   
    
        {
          command = []
          _.each (_.get select, 'command'), (v,k) ->
            command.push { text: v ,key: k,value: v}
          <Dropdown placeholder='Command' fluid multiple search selection
            value={me.state.value}
            className='item'
            onChange={(e,{value})->  
              me.setState command: value}
              options={command } />

        }
        {
          <DatePicker placeholderText="Date"
              selected={me.state.startDate}
              value={me.state.startDate}
              className='date-picker' 
              dateFormat="DD/MM/YYYY"
              onChange={(date)->  me.setState startDate: date} />
        }
        {
          <DatePicker placeholderText="To" className='date-picker' 
              selected={me.state.endDate}
              value={me.state.endDate}
              dateFormat="DD/MM/YYYY"
              onChange={(date)->  me.setState endDate: date} 
             />
        }
        </Grid.Column>
        
        <Grid.Row>
          <Button size='tiny'  color='blue'>Export PDF</Button>
          <Button size='tiny' color='teal'>Export CSV</Button>
          <Button size='tiny'  positive onClick={()-> me.props.onClick me.state } >Search !</Button>
          <Button size='tiny'  color='olive' 
              onClick={()-> 
                me.setState 
                    startDate: ""
                    endDate: ""
                    value: []}>
            Clear!
          </Button>

        </Grid.Row>
         
      </Grid>
      
      {' '}
      
      

    </div>    
export default OptionTable

