
import React,{Component} from 'react'
import { connect }                    from 'react-redux'
import { Icon, Table,Menu } from 'semantic-ui-react'
import DataTable from '/app/components/DataTable'
import moment              from 'moment'
import prettyMs            from 'pretty-ms'

class  LogTable extends Component
  constructor:(props)->
    super props 
    @state = {}

  render:->
    me = @
    data = _.get me, 'props.data'
    w = window.innerWidth
    cursor = ""
    <div className='table'>
      <Table   celled > 
        <Table.Header>
          <Table.Row>
            <Table.HeaderCell>'#'</Table.HeaderCell>
            <Table.HeaderCell>UserName</Table.HeaderCell>
            <Table.HeaderCell>ServerName</Table.HeaderCell>
            <Table.HeaderCell>Command</Table.HeaderCell>
            <Table.HeaderCell>Allow</Table.HeaderCell>
            <Table.HeaderCell>Activity</Table.HeaderCell>
            <Table.HeaderCell>Time</Table.HeaderCell>
          </Table.Row>
        </Table.Header>
          <Table.Body>
        {
          table= []
          if data
            data[0..5].map (v,k)->
              time = moment(_.get v, 'node.createdAt').utcOffset '+07:00'
              unless (parseInt (moment().utcOffset '+07:00').format "DD") - parseInt(time.format "DD")== 0
                v.node.createdAt = time.format "YYYY-MM-DD HH:mm:ss"
              else
                v.node.createdAt = prettyMs(new Date - time, { compact: true, verbose: true }) + ' ago'
              cursor = v.cursor
              table.push( <DataTable key={k} data={v.node} cursor= {v.cursor}/> )
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