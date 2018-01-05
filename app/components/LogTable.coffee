
import React,{Component} from 'react'
import { connect }                    from 'react-redux'
import { Icon, Table,Menu } from 'semantic-ui-react'
import DataTable from '/app/components/DataTable'
import moment              from 'moment'
import prettyMs            from 'pretty-ms'
import Fullscreenable from 'react-fullscreenable'

class  LogTable extends Component
  constructor:(props)->
    super props 
    @state = {
      last: Math.floor((window.innerHeight - 600) / 46)

    }

  render:->
    me = @
    data = _.get me, 'props.data'
    w = window.innerWidth
    cursor = ""
    id =""
    <div className='table'  style={height: '20px'} >
      <Table   size='small'
              celled 
              compact
              selectable > 
        <Table.Header>
          <Table.Row>
          <Table.HeaderCell>id</Table.HeaderCell>
            <Table.HeaderCell>UserName</Table.HeaderCell>
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
            data[0..me.state.last].map (v,k)->
              times  =  _.get v, 'node.createdAt' 

              time = moment(_.get v, 'node.createdAt').utcOffset '+07:00'
              unless (parseInt (moment().utcOffset '+07:00').format "DD") - parseInt(time.format "DD")== 0
                times = time.format "YYYY-MM-DD HH:mm:ss"
                # if _.get me, 'state.pagegination' == 'next'
                #   v.node.id = v.node.id + 1

              else
                v.node.createdAt  = prettyMs(new Date - time, { compact: true, verbose: true }) + ' ago'
              cursor = v.cursor
              id = v.node.id
              console.log "========curr", cursor

              table.push( <DataTable key={k} data={v.node} /> )
          table
        }
        </Table.Body>
        <Table.Footer>
          <Table.Row>
            <Table.HeaderCell colSpan='12 '>
              <Menu floated='right'   pagination>
                <Menu.Item as='a' onClick={()-> 
                      me.setState 
                        pagegination: 'back'
                        cursor: cursor
                      me.props.onPageBack(me.state)
                      } icon>
                  <Icon name='left chevron' />
                  { console.log "=======cirr", cursor, id}
                  {" "}
                    Back
                </Menu.Item>
                <Menu.Item as='a' onClick={()-> 
                          me.setState 
                            pagegination: 'next'
                            cursor: cursor
                          me.props.onPageNext(me.state)} icon>
                  Next
                  <Icon name='right chevron' />
                </Menu.Item>
              </Menu>
            </Table.HeaderCell>
          </Table.Row>
        </Table.Footer>
      </Table>
    </div>




export default connect()(LogTable)