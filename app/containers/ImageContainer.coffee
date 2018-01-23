import React,{Component}                from 'react'
import { connect }                      from 'react-redux'
import ImageTable                       from '/app/components/ImageTable'
import { actions as imageActions }      from '/app/ducks/image'
import ShowModal                        from '/app/containers/ShowModal'
import SearchImage                      from '/app/containers/SearchImage'
class  ImageContainer extends Component
  render: ->
    <div className='table'>
      <SearchImage onClick={@props.onClick}/>
      <ImageTable data={@props.imagedata}  
          onNext={@props.onNext} 
          onBack={@props.onBack} 
          showModal={@props.showModal}
          search ={@props.search}
          totalCount={@props.total}
          pagination={@props.pagination} />
      <ShowModal />
    </div>
    


mapDispatchToProps = (dispatch) ->
  onClick:(key)->
    dispatch imageActions.search(key)
    dispatch imageActions.pageNumber(0)
  onNext:(e, search)->
    dispatch imageActions.getfilterImageNext(e, search)
  onBack:(e, search)->
    dispatch imageActions.getfilterImageBack(e, search)
  showModal:(e)->
    dispatch imageActions.showModal(e)


mapStateToProps = ({image})=>
  search: image.search
  imagedata: image.images
  pagination: image.page
  showModal: image.show
  total: image.total

export default connect(mapStateToProps,mapDispatchToProps)(ImageContainer)
