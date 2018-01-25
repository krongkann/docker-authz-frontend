

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
      servername: []
      command: []
      username:[]
      startDate: moment()
      endDate: moment()
    }
  componentWillMount: ->
    me = @

  httpPost = (theUrl, filters, callback) ->
    xmlHttp = new XMLHttpRequest()
    xmlHttp.onreadystatechange = () ->
      if xmlHttp.readyState == 4 && xmlHttp.status == 200
        callback xmlHttp.responseText
    xmlHttp.open "POST", theUrl, true
    xmlHttp.setRequestHeader "Content-type", "application/json"
    xmlHttp.send JSON.stringify { filters }

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
          <Dropdown  placeholder='Server Name' fluid multiple search selection
            value={me.state.servername}
            onChange={(e,{value})->
              me.setState servername: value}
              options={server } />
        }
        {
          user = []
          _.each (_.get select, 'user'), (v,k) ->
            user.push { text: v , key: k ,value: v}
          <Dropdown placeholder='User Name'  fluid multiple search selection
            value={me.state.username}
            onChange={(e,{value})->
              me.setState username: value}
              options={user} />
        }
   
    
        {
          command = []
          _.each (_.get select, 'command'), (v,k) ->
            command.push { text: v ,key: k,value: v}
          <Dropdown placeholder='Command' fluid multiple search selection
            value={me.state.command}
            className='item'
            onChange={(e,{value})->
              me.setState command: value}
              options={command } />

        }
        {
          <DatePicker placeholderText="Date"
              selected={me.state.startDate}
              className='date-picker' 
              dateFormat="DD/MM/YYYY"
              onChange={(date)->  me.setState startDate: date} />
        }
        {
          <DatePicker placeholderText="To"  
              selected={me.state.endDate}
              className='date-picker'
              dateFormat="DD/MM/YYYY"
              onChange={(date)->  me.setState endDate: date} 
             />
        }
        </Grid.Column>
        
        <Grid.Row>
          <Button size='tiny'  color='blue' onClick={ () ->
            httpPost '/download_pdf', {}, (res) ->
              hash = JSON.parse(res).hash
              aWindow = window.open "/download_pdf/#{hash}", 'Meow~', () ->
                aWindow.close()
          }>Export PDF</Button>
          <Button size='tiny' color='teal' onClick={ () ->
            httpPost '/download_csv', {}, (res) ->
              hash = JSON.parse(res).hash
              aWindow = window.open "/download_csv/#{hash}", 'Meow~', () ->
                aWindow.close()

          }>Export CSV</Button>
          <Button size='tiny'  positive onClick={()-> me.props.onClick me.state } >Search !</Button>
          <Button size='tiny'  color='olive' 
              onClick={()->
                me.setState 
                  servername: []
                  command: []
                  username:[]}>
            Clear!
          </Button>

        </Grid.Row>
         
      </Grid>
      
      {' '}
      
      

    </div>    
export default OptionTable

