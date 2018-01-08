
import React,{Component} from 'react'
import { connect }                    from 'react-redux'
import { Icon, Table,Menu } from 'semantic-ui-react'
import DataTable from '/app/components/DataTable'
import Pagination from '/app/containers/Pagination'
import moment              from 'moment'
import prettyMs            from 'pretty-ms'
import Fullscreenable from 'react-fullscreenable'

class  LogTable extends Component


  render:->
    me = @
    data = _.get me, 'props.data'
    w = window.innerWidth
    cursor = ""
    id = ""
    first = 1
    last = Math.floor((window.innerHeight - 600) / 46)
    console.log me.props.pagination
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
            data[0..last].map (v,k)->
              times  =  _.get v, 'node.createdAt' 
              time = moment(_.get v, 'node.createdAt').utcOffset '+07:00'
              unless (parseInt (moment().utcOffset '+07:00').format "DD") - parseInt(time.format "DD")== 0
                times = time.format "YYYY-MM-DD HH:mm:ss"
                v.node.createdAt = times
              else
                v.node.createdAt  = prettyMs(new Date - time, { compact: true, verbose: true }) + ' ago'
              cursor = v.cursor
              

              table.push( <DataTable key={k} data={v.node} /> )
          table


        }
        </Table.Body>
        <Pagination   onPageBack={()-> me.props.onPageBack(cursor)}
                      cursor ={cursor}
                      onPageNext={()-> me.props.onPageNext(cursor)} />
      </Table>
    </div>




export default connect()(LogTable)