import React,{Component}                from 'react'
import { connect }                      from 'react-redux'
import ImageTable                       from '/app/components/ImageTable'
import { actions as imageActions }      from '/app/ducks/image'
import { Icon, Table,Menu, Label }      from 'semantic-ui-react'
import { actions as logActions }        from '/app/ducks/log'
class  Pagination extends Component
  
  render: ->
    me = @
    disablednext =  ((_.get @, 'props.cursorend.endCursor') == me.props.cursor) or !me.props.total
    disabledback = (@props.page == 1)
    <Table.Footer>
      <Table.Row>
        <Table.HeaderCell colSpan='12 '>
          <Menu floated='right'   pagination>
            <Menu.Item as='a' 
              disabled={disabledback}
              onClick={(cursor)->
                    me.props.onPageClick(-1)
                    me.props.onPageBack(cursor, me.state)        } icon>
              <Icon name='left chevron' />
              {" "}
                Back
            </Menu.Item>
            <Menu.Item as='a'
              disabled = {disablednext}
              onClick={(cursor,s)->
                      me.props.onPageClick(1)
                      me.props.onPageNext(cursor, me.state)} icon>
              Next
              <Icon name='right chevron' />
            </Menu.Item>
          </Menu>
          <Label>
            PAGE :
            <Label.Detail>{me.props.page}</Label.Detail>
          </Label>
        </Table.HeaderCell>
      </Table.Row>
    </Table.Footer>
    
mapDispatchToProps = (dispatch)=>
  onPageClick:(me)->
    dispatch logActions.pageNumber(me)

mapStateToProps = ({log})=>
  cursorend: log.endcursor
  page: log.numberpage 
export default connect(mapStateToProps,mapDispatchToProps)(Pagination)
