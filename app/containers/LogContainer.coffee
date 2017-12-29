import React,{Component}               from 'react'
import { connect }                     from 'react-redux'
import { ProgressBar }                 from 'react-bootstrap'
import LogTable                        from '/app/components/LogTable'
import OptionTable                        from '/app/components/OptionTable'
import { actions as logActions }      from '/app/ducks/log'
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
      <OptionTable onClick={@props.onClick}  select={@props.select}/>

      <LogTable data={@props.logdata}  onPage = {@props.onPage}/>
    </div>
    



mapDispatchToProps = (dispatch) ->
  onClick:(key)->
  onPage:(e)->
    dispatch logActions.getfilterLog(e)

mapStateToProps = ({log})=>
  logdata: log.logs
  select: log.selector

export default connect(mapStateToProps, mapDispatchToProps)(LogContainer)
