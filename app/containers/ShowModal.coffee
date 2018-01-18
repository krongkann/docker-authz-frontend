import React,{Component}   from 'react'
import moment              from 'moment'
import { connect }                     from 'react-redux'
import { Icon, Button, Modal} from 'semantic-ui-react'
import { actions as imageActions }      from '/app/ducks/image'
class  ShowModal extends Component
  constructor:(props)->
    super props 
    @state = {
      open: false
    }

  render:->
    me = @
    <Modal  open={me.props.showModal} onClose={@props.onCloseModal}>
      <Modal.Header>
        Change Your Permission
      </Modal.Header>
      <Modal.Content>
        <p>Are you sure you want to change your Permission</p>
      </Modal.Content>
      <Modal.Actions>
        <Button negative onClick={@props.onCloseModal}>
          No
        </Button>
        <Button positive icon='checkmark' 
        labelPosition='right' 
        onClick={()->   
            me.props.onAllow(me.props.idImage)
          }
        content='Yes' />
      </Modal.Actions>
    </Modal>
  
mapStateToProps = ({image})=>
  showModal: image.show
  idImage: image.id 
mapDispatchToProps = (dispatch) ->
  onCloseModal:(e)->
    dispatch imageActions.closeModal()
  onAllow:(e)->
    dispatch imageActions.permissionImage(e)
    
    # dispatch imageActions.search({})



export default connect(mapStateToProps, mapDispatchToProps)(ShowModal)

