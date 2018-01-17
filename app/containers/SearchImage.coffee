import React,{Component}               from 'react'
import { connect }                     from 'react-redux'
import { ProgressBar }                 from 'react-bootstrap'
axios = require 'axios'
import { Dropdown, Label, Select, Grid, Button, Menu, Input, Header, Checkbox } from 'semantic-ui-react'




class  SearchImage extends Component
  constructor:(props)->
    super props 
    @state = { }
  render: ->
    me = @    
    select = _.get me, 'props.selector'

    <div className='option-image'> 
      <Grid columns={3} >
        <Grid.Column textAlign='right'>
          <Header size='small'>Server Name</Header>
        </Grid.Column>
        <Grid.Column >

        {
          server = []
          _.each (_.get me, 'props.selector'), (v,k) ->
            server.push { text: v.servername, key: k , value: v.servername}
          <Dropdown  placeholder='Server Name' fluid multiple search selection
            onChange={(e,{value})->  
              me.setState servername: value}
              options={server } />
        }
       

        </Grid.Column>
        <Grid.Column textAlign='justified'>

          <Button size='tiny' color='teal' onClick={()-> me.props.onClick me.state}>Search</Button>
        </Grid.Column>


      </Grid>
      
      {' '}
      
      

    </div>    
    

mapStateToProps = ({image})=>
  selector: image.selectorImage


export default connect(mapStateToProps)(SearchImage)


