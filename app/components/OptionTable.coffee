

import React,{Component}   from 'react'
import moment              from 'moment'
import { Dropdown, Label, Select, Grid, Button } from 'semantic-ui-react'
import DatePicker from 'react-datepicker'
import 'react-datepicker/dist/react-datepicker.css'
countryOptions=
  [{ key: 'af', value: 'af', flag: 'af', text: 'Afghanistan' },
    { key: 'af1', value: 'af1', flag: 'af', text: 'KOkea' }

]

class  OptionTable extends Component
  constructor: (props) ->
    super(props)
    @state = 
      startDate: moment()
  handleChange:(date) ->
    console.log "fff",date
    @setState
      startDate: date
    

  render:->
    me = @
    <div className='option-table'> 


      <Grid columns='equal'>
       
        <Grid.Row>
          <Grid.Column>
            <Select placeholder='Server Name' 
              onChange={(e,value)->  
                me.setState servername: value.options[0].text}
                options={countryOptions} />
          </Grid.Column>
          <Grid.Column>
            <Select placeholder='User Name' 
              options={countryOptions}
              onChange={(e,data)->  
                me.setState username: data.options[0].text}  />
          </Grid.Column>
          <Grid.Column>
            <Select placeholder='Command' 
              options={countryOptions}
              onChange={(e, data)->  
                me.setState command: data.options[1].text}  />
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

