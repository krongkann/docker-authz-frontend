import React,{Component}               from 'react'
import { connect }                     from 'react-redux'
import ImageTable                        from '/app/components/ImageTable'


class  ImageContainer extends Component
  render: ->
    <div className='table'>
      <ImageTable data={@props.imagedata}  onNext={@props.onNext} onBack={@props.onBack} />
  
      
    </div>
    


mapDispatchToProps = (dispatch) ->

  onClick:(key)->
    dispatch logActions.searchLog(key)
  onNext:(e)->
    dispatch logActions.getfilterLogNext(e)
  onBack:(e)->
    dispatch logActions.getfilterLogBack(e)


mapStateToProps = ({image})=>
  console.log "iamgee", image
  imagedata: image.images

export default connect(mapStateToProps)(ImageContainer)
