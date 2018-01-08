import React, { Component }               from 'react'
import { connect }                     from 'react-redux'
import { ProgressBar }                 from 'react-bootstrap'
import ServernameSelector              from '/app/components/servername_selector'
axios = require 'axios'
import { Button } from 'semantic-ui-react'



class  PermissionContainer extends Component
  render: ->
    <div>
      <ServernameSelector/>
    </div>

mapDispatchToProps = (dispatch) ->
  onClick: (key) ->
    console.log 'trap'
  #   dispatch pageActions.doSelectPage(@name)
  #   dispatch logActions.getLog()
  #   dispatch logActions.getSelector()
mapStateToProps = ({permission}) -> 
  data: permission.servernames
export default connect(mapStateToProps, mapDispatchToProps)(ServernameSelector)
