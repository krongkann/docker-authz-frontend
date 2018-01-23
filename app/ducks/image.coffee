import { defineAction }           from 'redux-define'
import { GraphQLClient, request }  from 'graphql-request'
import { ACTIONS as systemActionTypes }                     from './system'
client = new GraphQLClient '/graphql' 
axios = require 'axios'

DEFAULT_STATE = {numberpage: 1}

export ACTIONS = defineAction('IMAGE', ['RECEIVE_IMAGES', 
                                        'SHOW_MODAL', 
                                        'CLOSE_MODAL', 
                                        'SORT_IMAGE', 
                                        'CHANGE_ALLOW',
                                        'SEARCH_SERVER'
                                        'SEARCH_IMAGE',
                                        'PAGE_SELECT',
                                        'PAGE_NUMBER']) 
QUERY = """
query($id: Int, 
      $servername: [String],
      $repository_name: String,
      $image_id: String,
      $allow: Boolean,
      $before: String,
      $after: String){
  images(id: $id
        before: $before
        after: $after
        servername: $servername
        repository_name: $repository_name
        image_id: $image_id
        allow: $allow){
    edges{
      node{
        id
        servername
        repository_name
        tag
        image_id
        allow
        extrainfo
      }
      cursor
    }
    pageInfo{
      endCursor
    }
    sortServername {
      servername
    }
    totalCount
  }
}

"""

export actions = 
  permissionImage: (id, username)-> 
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
    queryimages = QUERY
    (dispatch)->
      if id 
        data = await client.request query,
          {
            input:
              id: id
              username: username
          }
        dispatch 
          type: ACTIONS.CHANGE_ALLOW
          payload: 
              id: id
              allow: _.get data, 'updateImage.allow'
              message: 'permission pass'

        data = await client.request queryimages,
        {
          servername: name.servername
        }
        dispatch 
          type: ACTIONS.RECEIVE_IMAGES
          payload: 
            images: _.get data, 'images.edges'
            selectorImage:  _.get data, 'images.sortServername'
            total: _.get data, 'images.totalCount'
            endcursor: _.get data, 'images.pageInfo'
            search:
              servername: name.servername
        dispatch
          type: ACTIONS.CLOSE_MODAL

      else
        dispatch 
          type: ACTIONS.CHANGE_ALLOW
          payload: 
            message: 'permission fail'
  pageNumber:(me) -> (dispatch) ->
    dispatch 
      type: ACTIONS.PAGE_NUMBER
      payload:
        page: me

        
  showModal: (id)=> 
    type: ACTIONS.SHOW_MODAL
    payload:
      open: true
      id: id
  closeModal:()->
    type: ACTIONS.CLOSE_MODAL
  search:(name)-> (dispatch) ->
    query = QUERY
    try
      data = await client.request query,
      {
        servername: name.servername
      }
      dispatch 
        type: ACTIONS.RECEIVE_IMAGES
        payload: 
          images: _.get data, 'images.edges'
          selectorImage:  _.get data, 'images.sortServername'
          total: _.get data, 'images.totalCount'
          endcursor: _.get data, 'images.pageInfo'
          search:
            servername: name.servername
    catch e
      dispatch
        type: systemActionTypes.SHOW_NOTIFY
        payload: 
          type: 'error'
          message: e.message
  getfilterImageNext:(cursor,name)->
    query = QUERY
    (dispatch) =>
      try
        data = await client.request query,
        {
          servername: name.servername
          after: cursor
        }
        dispatch 
          type: ACTIONS.RECEIVE_IMAGES
          payload: 
            images: _.get data, 'images.edges'
            selectorImage:  _.get data, 'images.sortServername'
            total: _.get data, 'images.totalCount'
            endcursor: _.get data, 'images.pageInfo'
            search:
              servername: name.servername
        dispatch 
          type: ACTIONS.PAGE_SELECT
          payload: 'next'
       
       
      catch e
  getfilterImageBack:(cursor, name) =>
    query = QUERY
    (dispatch) =>
      try
        data = await client.request query,
        {
          servername: name.servername
          before: cursor
        }
        dispatch 
          type: ACTIONS.RECEIVE_IMAGES
          payload: 
            images: _.get data, 'images.edges'
            selectorImage:  _.get data, 'images.sortServername'
            total: _.get data, 'images.totalCount'
            endcursor: _.get data, 'images.pageInfo'
            search:
              servername: name.servername
        dispatch 
          type: ACTIONS.PAGE_SELECT
          payload: 'back'
        
      catch e

 


export default (state=DEFAULT_STATE, {type, payload})->
  switch type
    when ACTIONS.RECEIVE_IMAGES
      _.extend {}, state, 
        images: payload.images
        total: payload.total
        search: payload.search
        endcursor: payload.endcursor
        selectorImage: payload.selectorImage

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
    when ACTIONS.PAGE_SELECT
      _.extend {}, state,
        page: payload
    when ACTIONS.PAGE_NUMBER
      _.extend {}, state,
        if payload.page == 0
          numberpage: 1
        else
          numberpage: (state.numberpage + payload.page) 

    when ACTIONS.CHANGE_ALLOW
      _.extend {}, state,
        allow: payload.allow
        msg: payload.message
    else
      state
