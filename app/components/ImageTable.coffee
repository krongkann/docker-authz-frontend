
import React, {Component}             from 'react'
import { connect }                    from 'react-redux'
import { Icon, Table, Menu, Label }   from 'semantic-ui-react'
import moment                         from 'moment'
import prettyMs                       from 'pretty-ms'
import DataImage                      from '/app/components/DataImage'
import ImagePagination                from '/app/containers/ImagePagination'
class  ImageTable extends Component

  render:->
    me = @
    data = _.get me, 'props.data'
    cursor = ""
    first = 0
    last = Math.floor((window.innerHeight - 100 ) / 120)
    <div className='table'>
      <Table   size='small'
              celled 
              selectable > 
        <Table.Header>
          <Table.Row>
            <Table.HeaderCell>Id</Table.HeaderCell>
            <Table.HeaderCell>ServerName</Table.HeaderCell>
            <Table.HeaderCell>Repository</Table.HeaderCell>
            <Table.HeaderCell>Tag</Table.HeaderCell>
            <Table.HeaderCell>Image Id</Table.HeaderCell>
            <Table.HeaderCell>Allow</Table.HeaderCell>
            <Table.HeaderCell>ExtraInfo</Table.HeaderCell>
          </Table.Row>
        </Table.Header>
          <Table.Body  >
        {
          table= []
          if data
            if data.length == 0
              table.push(<Label as='a' key={1} color='red' tag>not data</Label>)
            data[first..last].map (v,k)->
              cursor =  v.cursor
              table.push( <DataImage key={k} data={v.node} 
                showModal={ me.props.showModal}/>)
          else
            table.push(<Label as='a' key={1} color='red' tag>not data</Label>) 
          table
        }
        </Table.Body>
        <ImagePagination   
            onPageBack={()-> me.props.onBack(cursor,(_.get me, 'props.search'))}
            cursor ={cursor}
            totals={_.get me, 'props.totalCount'}
            onPageNext={()-> me.props.onNext(cursor, (_.get me, 'props.search'))} />
      </Table>
    </div>




export default connect()(ImageTable)