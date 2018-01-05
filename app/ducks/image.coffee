import { defineAction }           from 'redux-define'
import { GraphQLClient, request }  from 'graphql-request'
import { ACTIONS as systemActionTypes }                     from './system'
client = new GraphQLClient '/graphql' 
axios = require 'axios'

DEFAULT_STATE = {}

export ACTIONS = defineAction('IMAGE', ['RECEIVE_IMAGES', 
                                        'SHOW_MODAL', 
                                        'CLOSE_MODAL', 
                                        'SORT_IMAGE', 
                                        'CHANGE_ALLOW',
                                        'SEARCH_SERVER']) 

export actions = 
  getAllImage: (servername)=>
    query = """
query($id: Int, $servername: String,
      $repository_name: String,
      $image_id: String,
      $allow: Boolean){
  images(id: $id
                servername: $servername
                repository_name: $repository_name
                image_id: $image_id
                allow: $allow){
    ListImage(servername: $servername){
      id
      servername
      repository_name
      tag
      image_id
      allow
      extrainfo
    }

    sortServername {
      servername

    }
  }
}


"""
    (dispatch) =>
      try
        data = await client.request query,
        {
          servername: servername
        }
        
        dispatch 
          type: ACTIONS.RECEIVE_IMAGES
          payload: 
            images: _.get data, 'images.ListImage'
            servers:  _.get data, 'images.sortServername'


      catch e
        dispatch
          type: systemActionTypes.SHOW_NOTIFY
          payload: 
            type: 'error'
            message: e.message

        
  showModal: (id)=> 
    type: ACTIONS.SHOW_MODAL
    payload:
      open: true
      id: id
  closeModal:()->
    type: ACTIONS.CLOSE_MODAL
  permissionImage: (id)->
    query = """
mutation($input: updateImagesInputType!){
  updateImage(input:$input ){
    servername
    repository_name
    id
    allow
  }
}
 """ 
    (dispatch)->
      if id 
        data = await client.request query,
          {
            input:
              id: id
          }
        dispatch 
          type: ACTIONS.CHANGE_ALLOW
          payload: 
              id: id
              allow: _.get data, 'updateImage.allow'
              message: 'permission pass'

      else
        dispatch 
          type: ACTIONS.CHANGE_ALLOW
          payload: 
            message: 'permission fail'


export default (state=DEFAULT_STATE, {type, payload})->
  switch type
    when ACTIONS.RECEIVE_IMAGES
      _.extend {}, state, 
        images: payload.images 
        servers: payload.servers

    when ACTIONS.SORTIMAGE 
      _.extend {}, state,
        servernames: payload 

    when ACTIONS.SHOW_MODAL
      _.extend {}, state,
        show: payload.open
        id: payload.id

    when ACTIONS.CLOSE_MODAL
      _.extend {}, state,
        show: false

    when ACTIONS.CHANGE_ALLOW
      _.extend {}, state,
        allow: payload.allow
        msg: payload.message
    else
      state
