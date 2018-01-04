import React,{Component}               from 'react'
import { connect }                     from 'react-redux'
import { ProgressBar }                 from 'react-bootstrap'
import LogTable                        from '/app/components/LogTable'
import OptionTable                        from '/app/components/OptionTable'
import { actions as logActions }      from '/app/ducks/log'
import { Header, Modal } from 'semantic-ui-react'
axios = require 'axios'


class  LogContainer extends Component
  constructor:(props)->
    super props 
    @state = { }

  render: ->
    me = @
    <div className='table'>
      <OptionTable onClick={@props.onClick}  select={@props.select}/>

      <LogTable data={@props.logdata}  
                onPageNext = {@props.onPageNext} 
       
                onPageBack={@props.onPageBack}/>
  
      
    </div>
    



mapDispatchToProps = (dispatch) ->

  onClick:(key)->
    dispatch logActions.searchLog(key)
  onPageNext:(e)->
    dispatch logActions.getfilterLogNext(e)
  onPageBack:(e)->
    dispatch logActions.getfilterLogBack(e)


mapStateToProps = ({log})=>
  logdata: log.logs
  select: log.selector

export default connect(mapStateToProps, mapDispatchToProps)(LogContainer)
