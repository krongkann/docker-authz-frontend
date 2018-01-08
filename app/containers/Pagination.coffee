import React,{Component}               from 'react'
import { connect }                     from 'react-redux'
import ImageTable                        from '/app/components/ImageTable'
import { actions as imageActions }      from '/app/ducks/image'
import { Icon, Table,Menu } from 'semantic-ui-react'
class  Pagination extends Component
  constructor:(props)->
    super props 
    @state = {
      page: 'null'
    }
  render: ->
    me = @
    disabledend =  ((_.get @, 'props.cursorend.endCursor') == me.props.cursor)
    disabledback = ((_.get me, 'props.lastValue') ==  me.props.total) 
    <Table.Footer>
      <Table.Row>
        <Table.HeaderCell colSpan='12 '>
          <Menu floated='right'   pagination>
            <Menu.Item as='a' 
              disabled={disabledback}
              onClick={(cursor)->
                  me.setState 
                    page: 'back'
                  me.props.onPageBack(cursor)        } icon>
              <Icon name='left chevron' />
              {" "}
                Back
            </Menu.Item>
            <Menu.Item as='a'
              disabled = {disabledend}
              onClick={(cursor)-> 
                      me.setState 
                        page: 'next'
                      me.props.onPageNext(cursor)} icon>
              Next
              <Icon name='right chevron' />
            </Menu.Item>
          </Menu>
        </Table.HeaderCell>
      </Table.Row>
    </Table.Footer>
    


mapDispatchToProps = (dispatch) ->

  


mapStateToProps = ({log})=>
  cursorend: log.endcursor
  total: log.total
export default connect(mapStateToProps)(Pagination)
