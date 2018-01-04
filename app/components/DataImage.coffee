import React,{Component}   from 'react'
import moment              from 'moment'
import { Icon, Table,Menu, Button, Header, Image, Modal, List, Label} from 'semantic-ui-react'
class  DataImage extends Component

  render:->
    me = @
    id =  _.get me, 'props.data.image_id'
    <Table.Row  style={{"height": "100%"}}>
      <Table.Cell>{_.get me, 'props.data.id'}</Table.Cell>
      <Table.Cell>{_.get me, 'props.data.servername'} </Table.Cell>
      <Table.Cell>{_.get me, 'props.data.repository_name'} </Table.Cell>
      <Table.Cell>{_.get me, 'props.data.tag'}</Table.Cell>
      <Table.Cell>{id[0..10]} </Table.Cell>
      <Table.Cell>{(_.get me, 'props.data.allow').toString()} </Table.Cell>
    </Table.Row>
    
export default DataImage

