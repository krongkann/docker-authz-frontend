import React,{Component}               from 'react'
import { connect }                     from 'react-redux'
import ImageTable                        from '/app/components/ImageTable'
import { actions as imageActions }      from '/app/ducks/image'
import ShowModal from '/app/containers/ShowModal'
import SearchImage from '/app/containers/SearchImage'
class  ImageContainer extends Component
  render: ->
    <div className='table'>
      <SearchImage onClick={@props.onClick}/>
      <ImageTable data={@props.imagedata}  
          onNext={@props.onNext} 
          onBack={@props.onBack} 
          showModal={@props.showModal}/>
  
      <ShowModal />
      
    </div>
    


mapDispatchToProps = (dispatch) ->

  onClick:(key)->
    dispatch imageActions.search(key)
  onNext:(e)->
    console.log e
    dispatch imageActions.getfilterImageNext(e)
  onBack:(e)->
    console.log e
    dispatch imageActions.getfilterImageBack(e)
  showModal:(e)->
    dispatch imageActions.showModal(e)


mapStateToProps = ({image})=>
  imagedata: image.images
  showModal: image.show

export default connect(mapStateToProps,mapDispatchToProps)(ImageContainer)
