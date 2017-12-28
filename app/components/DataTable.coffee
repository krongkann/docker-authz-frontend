import React,{Component}   from 'react'
import moment              from 'moment'
import { Icon, Table,Menu } from 'semantic-ui-react'

class  DataTable extends Component

  render:->
    me = @ 
    <Table.Row  >
      <Table.Cell>{_.get me, 'props.data.id'}</Table.Cell>
      <Table.Cell>{_.get me, 'props.data.username'}</Table.Cell>
      <Table.Cell>{_.get me, 'props.data.servername'} </Table.Cell>
      <Table.Cell>{_.get me, 'props.data.command'} </Table.Cell>
      <Table.Cell>{(_.get me, 'props.data.allow').toString()} </Table.Cell>
       <Table.Cell>  </Table.Cell>
      <Table.Cell>{_.get me, 'props.data.time'} </Table.Cell>
    </Table.Row>
    
export default DataTable

