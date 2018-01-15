
import React,{Component} from 'react'
import { connect }                    from 'react-redux'
import { Icon, Table,Menu, Label } from 'semantic-ui-react'
import DataTable from '/app/components/DataTable'
import Pagination from '/app/containers/Pagination'
import moment              from 'moment'
import prettyMs            from 'pretty-ms'
import Fullscreenable from 'react-fullscreenable'

class  LogTable extends Component
  test =
    data:[
      node: 
        {id:1, username:'client', allow: true, servername: 'cc', command:'ps', request_method: 'get', createdAt: '2014-06-01T12:00:00Z'}
    ]
  render:->
    me = @
    data = _.get me, 'props.data'
    w = window.innerWidth
    cursor = ""
    id = ""
    first = 0
    last = Math.floor((window.innerHeight - 600) / 46)
    <div className='table'  style={height: '20px'} >
      <Table   size='small'
              celled 
              compact
              selectable > 
        <Table.Header>
          <Table.Row>
          <Table.HeaderCell>Id</Table.HeaderCell>
            <Table.HeaderCell >UserName</Table.HeaderCell>
            <Table.HeaderCell>ServerName</Table.HeaderCell>
            <Table.HeaderCell>Command</Table.HeaderCell>
            <Table.HeaderCell>Method</Table.HeaderCell>
            <Table.HeaderCell>Time</Table.HeaderCell>
            <Table.HeaderCell>Details</Table.HeaderCell>
          </Table.Row>
        </Table.Header>
          <Table.Body  >
        {
          table= []
    
          if data
           
            if me.props.pagination == 'back'
              first_old = data.length - (2)
              first_new = first_old - (last) 
              first = (first_new - last)
              last = first_new
            data[first..last].map (v,k)->
              times  =  _.get v, 'node.createdAt' 
              time = moment(_.get v, 'node.createdAt').utcOffset '+07:00'
              unless (parseInt (moment().utcOffset '+07:00').format "DD") - parseInt(time.format "DD")== 0
                times = time.format "YYYY-MM-DD HH:mm:ss"
                v.node.createdAt = times
              else
                v.node.createdAt  = prettyMs(new Date - time, { compact: true, verbose: true }) + ' ago'
              cursor = v.cursor
              
              table.push( <DataTable key={k} data={v.node} /> )
          else
            table.push(<Label as='a' key={1} color='red' tag>not data</Label>)
          table


        }
        </Table.Body>
        <Pagination   onPageBack={()-> me.props.onPageBack(cursor)}
                      cursor ={cursor}
                      onPageNext={()-> me.props.onPageNext(cursor)} />
      </Table>
    </div>




export default connect()(LogTable)