
import React,{Component} from 'react'
import { connect }                    from 'react-redux'
import { Icon, Table,Menu } from 'semantic-ui-react'
import DataTable from '/app/components/DataTable'

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
            data[0..1].map (v,k)->
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
                      me.props.onPage(me.state)
                      } icon>
                  <Icon name='left chevron' />
                  {" "}
                    Back
                </Menu.Item>
                <Menu.Item as='a' onClick={()-> 
                          me.setState 
                            pagegination: 'next'
                            cursor: cursor
                          me.props.onPage(me.state)} icon>
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