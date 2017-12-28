
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
          _.each  data, (v,k)->

           
            data = _.extend {},
                    servername: _.get v, 'node.servername'
                    username:  _.get v, 'node.username'
                    allow:  _.get v, 'node.allow'
                    command:  _.get v, 'node.command'
                    time: _.get v, 'node.createdAt'
            table.push( <DataTable key={k} data={data}/> )
          table
        }
        </Table.Body>
        <Table.Footer>
        <Table.Row>
          <Table.HeaderCell colSpan='3'>
            <Menu floated='right' pagination>
              <Menu.Item as='a' icon>
                <Icon name='left chevron' />
                {" "}
                  Back
              </Menu.Item>
              <Menu.Item as='a' icon>
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