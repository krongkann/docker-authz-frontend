import React,{Component}               from 'react'
import { connect }                     from 'react-redux'
import ImageTable                        from '/app/components/ImageTable'
import { actions as imageActions }      from '/app/ducks/image'
import { Icon, Table,Menu, Label } from 'semantic-ui-react'
class  Pagination extends Component
  constructor:(props)->
    super props 
    @state = {
      page: 1
    }
  render: ->
    me = @
    disablednext =  ((_.get @, 'props.cursorend.endCursor') == me.props.cursor) or !me.props.total
    disabledback = (@state.page == 1)
    <Table.Footer>
      <Table.Row>
        <Table.HeaderCell colSpan='12 '>
          <Menu floated='right'   pagination>
            <Menu.Item as='a' 
              disabled={disabledback}
              onClick={(cursor)->
                    me.setState 
                      page: me.state.page - 1
                    me.props.onPageBack(cursor)        } icon>
              <Icon name='left chevron' />
              {" "}
                Back
            </Menu.Item>
            <Menu.Item as='a'
              disabled = {disablednext}
              onClick={(cursor)-> 
                      me.setState 
                        page: me.state.page + 1
                      me.props.onPageNext(cursor)} icon>
              Next
              <Icon name='right chevron' />
            </Menu.Item>
          </Menu>
          <Label>
            PAGE :
            <Label.Detail>{me.state.page}</Label.Detail>
          </Label>
            
        </Table.HeaderCell>
      </Table.Row>
    </Table.Footer>
    


mapDispatchToProps = (dispatch) ->

  


mapStateToProps = ({log})=>
  cursorend: log.endcursor
  total: log.total
export default connect(mapStateToProps)(Pagination)
