

import React,{Component}   from 'react'
import moment              from 'moment'
import prettyMs            from 'pretty-ms'
import { Dropdown, Label, Select, Grid, Button } from 'semantic-ui-react'
import DatePicker from 'react-datepicker'
import 'react-datepicker/dist/react-datepicker.css'


class  OptionTable extends Component
  constructor: (props) ->
    super(props)
    @state = 
      startDate: moment()


  render:->
    me = @
    time = moment(_.get me, 'state.startDate').utcOffset '+00:00'
    console.log prettyMs(new Date - time, { compact: true, verbose: true }) + ' ago'
    console.log  time.format "YYYY-MM-DD HH:mm:ss"
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
              onChange={(date)->  
                time = moment(date).utcOffset '+00:00'
                me.setState startDate: (prettyMs(new Date - time, { compact: true, verbose: true }) + ' ago')} />
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
              <Button positive onClick={()-> me.props.onClick me.state } >Save</Button>
              <Button.Or />
              <Button onClick={()-> console.log "Cancel"}>Cancel</Button>
            </Button.Group>
          </Grid.Column>
        </Grid.Row>
         
      </Grid>
      
      {' '}
      
      

    </div>    
export default OptionTable

