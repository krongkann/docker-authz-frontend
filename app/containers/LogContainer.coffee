import React,{Component}               from 'react'
import { connect }                     from 'react-redux'
import { ProgressBar }                 from 'react-bootstrap'
import LogTable                        from '/app/components/LogTable'
import OptionTable                        from '/app/components/OptionTable'
import { Header } from 'semantic-ui-react'
axios = require 'axios'


class  LogContainer extends Component
  constructor:(props)->
    super props 
    @state = {}

  render: ->
    me = @ 
    <div className='table'>
      <Header as='h2' icon='history' content='History Log' />
      <OptionTable onClick={@props.onClick}  />

      <LogTable data={@props.logdata} />
    </div>
    



mapDispatchToProps = (dispatch) ->
  onClick:(key)->

    console.log "dfdfd", key

mapStateToProps = ({log})=>
  logdata: log.logs

export default connect(mapStateToProps, mapDispatchToProps)(LogContainer)
