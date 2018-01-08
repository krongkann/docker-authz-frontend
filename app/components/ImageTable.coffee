
import React,{Component} from 'react'
import { connect }                    from 'react-redux'
import { Icon, Table,Menu } from 'semantic-ui-react'
import moment              from 'moment'
import prettyMs            from 'pretty-ms'
import DataImage from '/app/components/DataImage'

class  ImageTable extends Component
  constructor:(props)->
    super props 
    @state = {}

  render:->
    me = @
    data = _.get me, 'props.data'
    cursor = ""
    last = Math.floor((window.innerHeight - 85) / 100)
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

            data[0..last].map (v,k)->
              cursor =  v.cursor
              table.push( <DataImage key={k} data={v.node} 
                showModal={ me.props.showModal}/> )
          table
        }
        </Table.Body>
        <Table.Footer>
          <Table.Row>
            <Table.HeaderCell colSpan='12 '>
              <Menu floated='right'   pagination>
                <Menu.Item as='a' onClick={()-> 
                      me.props.onBack(cursor)
                      } icon>
                  <Icon name='left chevron' />
                  {" "}
                    Back
                </Menu.Item>
                <Menu.Item as='a' onClick={()-> 
                  
                          me.props.onNext(cursor)} icon>
                  Next
                  <Icon name='right chevron' />
                </Menu.Item>
              </Menu>
            </Table.HeaderCell>
          </Table.Row>
        </Table.Footer>
      </Table>
    </div>




export default connect()(ImageTable)