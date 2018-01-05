
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

            data[0..9].map (v,k)->
              table.push( <DataImage key={k} data={v} 
                showModal={ me.props.showModal}/> )
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
                      me.props.onBack(me.state)
                      } icon>
                  <Icon name='left chevron' />
                  {" "}
                    Back
                </Menu.Item>
                <Menu.Item as='a' onClick={()-> 
                          me.setState 
                            pagegination: 'next'
                            cursor: cursor
                          me.props.onNext(me.state)} icon>
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